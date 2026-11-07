"""Durable single-node SQLite queue for the opt-in standalone HTTP worker.

The queue is an adapter around StandaloneService, not a replacement for
VoxPrep Backend V2. Text is stored on the private local volume: operators
must apply retention, encryption and backup policies appropriate to content.
"""
from __future__ import annotations

import fcntl
import hashlib
import json
import logging
import sqlite3
import threading
import time
from contextlib import contextmanager
from pathlib import Path
from uuid import UUID, uuid4

LOG = logging.getLogger(__name__)
TERMINAL = frozenset(("SUCCEEDED", "FAILED", "CANCELLED"))
MAX_RETRIES = 3
MAX_QUEUED = 100
MAX_IDEMPOTENCY_LENGTH = 128


class QueueConflict(ValueError):
    pass


class QueueFull(RuntimeError):
    pass


class InvalidQueueKey(ValueError):
    pass


class QueueClosed(RuntimeError):
    pass


def _fingerprint(payload: dict, manifest_sha256: str) -> str:
    return hashlib.sha256(
        json.dumps([manifest_sha256, payload], sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode()
    ).hexdigest()


class DurableQueue:
    """Single active queue owner, crash recovery, and atomic durable transitions."""

    def __init__(self, root: Path, service, *, max_queued: int = MAX_QUEUED):
        root.mkdir(parents=True, exist_ok=True)
        if root.is_symlink():
            raise ValueError("Queue directory must not be a symlink")
        self.root = root
        self.service = service
        self.max_queued = max_queued
        self._stop = threading.Event()
        self._wakeup = threading.Event()
        self._thread: threading.Thread | None = None
        self._owner_handle = (root / ".queue-owner.lock").open("a+b")
        try:
            fcntl.flock(self._owner_handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as exc:
            self._owner_handle.close()
            raise QueueClosed("Another process owns the standalone queue") from exc
        try:
            db_path = root / "jobs.sqlite3"
            if db_path.is_symlink():
                raise ValueError("Queue database must not be a symlink")
            self._db = sqlite3.connect(db_path, timeout=10, isolation_level=None, check_same_thread=False)
            self._lock = threading.RLock()
            self._db.execute("PRAGMA journal_mode=WAL")
            self._db.execute("PRAGMA synchronous=FULL")
            self._db.execute("PRAGMA busy_timeout=10000")
            self._db.execute("""CREATE TABLE IF NOT EXISTS jobs (
                id TEXT PRIMARY KEY,
                idempotency_key TEXT UNIQUE,
                fingerprint TEXT NOT NULL,
                manifest_sha256 TEXT NOT NULL DEFAULT '',
                payload TEXT NOT NULL,
                status TEXT NOT NULL CHECK (status IN
                    ('QUEUED','RUNNING','SUCCEEDED','FAILED','CANCELLED')),
                attempts INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                result TEXT,
                error_code TEXT
            )""")
            # Migration for early D2 databases. Legacy queued records have
            # unknown model identity and will fail closed rather than running
            # against an upgraded model bundle.
            columns = {
                row[1] for row in self._db.execute("PRAGMA table_info(jobs)").fetchall()
            }
            if "manifest_sha256" not in columns:
                self._db.execute(
                    "ALTER TABLE jobs ADD COLUMN manifest_sha256 TEXT NOT NULL DEFAULT ''"
                )
            # Interrupted RUNNING jobs are replayed using the same UUID.
            # Do not permanently retry after MAX_RETRIES attempts.
            with self._transaction():
                now = int(time.time())
                self._db.execute(
                    "UPDATE jobs SET status='QUEUED', updated_at=? "
                    "WHERE status='RUNNING' AND attempts < ?", (now, MAX_RETRIES))
                self._db.execute(
                    "UPDATE jobs SET status='FAILED', error_code='RETRY_EXHAUSTED', updated_at=? "
                    "WHERE status='RUNNING' AND attempts >= ?", (now, MAX_RETRIES))
        except Exception:
            self._owner_handle.close()
            raise

    @contextmanager
    def _transaction(self):
        with self._lock:
            self._db.execute("BEGIN IMMEDIATE")
            try:
                yield
                self._db.execute("COMMIT")
            except BaseException:
                self._db.execute("ROLLBACK")
                raise

    def submit(self, payload: dict, key: str | None) -> tuple[dict, bool]:
        if key is not None and (
            not isinstance(key, str) or not 1 <= len(key) <= MAX_IDEMPOTENCY_LENGTH
            or not key.isascii() or not all(c.isalnum() or c in "-_.:" for c in key)
        ):
            raise InvalidQueueKey("Invalid Idempotency-Key")
        manifest_sha256 = self.service.manifest["manifestSha256"]
        digest = _fingerprint(payload, manifest_sha256)
        with self._transaction():
            if key is not None:
                existing = self._db.execute(
                    "SELECT id, fingerprint FROM jobs WHERE idempotency_key=?", (key,)
                ).fetchone()
                if existing:
                    if existing[1] != digest:
                        raise QueueConflict("Idempotency-Key reused for a different request")
                    result = self._get_locked(existing[0])
                    return result, False
            queued = self._db.execute(
                "SELECT COUNT(*) FROM jobs WHERE status IN ('QUEUED','RUNNING')"
            ).fetchone()[0]
            if queued >= self.max_queued:
                raise QueueFull("Queue capacity reached")
            now = int(time.time())
            job_id = str(uuid4())
            self._db.execute(
                "INSERT INTO jobs(id,idempotency_key,fingerprint,manifest_sha256,payload,status,created_at,updated_at) "
                "VALUES(?,?,?,?,?,?,?,?)",
                (job_id, key, digest, manifest_sha256,
                 json.dumps(payload, ensure_ascii=False, sort_keys=True),
                 "QUEUED", now, now))
            result = self._get_locked(job_id)
        self._wakeup.set()
        return result, True

    def _get_locked(self, job_id: str) -> dict | None:
        row = self._db.execute(
            "SELECT id,status,attempts,created_at,updated_at,result,error_code "
            "FROM jobs WHERE id=?", (job_id,)
        ).fetchone()
        if not row:
            return None
        info = dict(zip(("id","status","attempts","createdAt","updatedAt","result","errorCode"), row))
        info["result"] = json.loads(info["result"]) if info["result"] else None
        return info

    def get(self, job_id: str) -> dict | None:
        try:
            if str(UUID(job_id)) != job_id:
                return None
        except (TypeError, ValueError):
            return None
        with self._lock:
            return self._get_locked(job_id)

    def cancel(self, job_id: str) -> dict | None:
        with self._transaction():
            existing = self._get_locked(job_id)
            if not existing:
                return None
            if existing["status"] == "QUEUED":
                self._db.execute(
                    "UPDATE jobs SET status='CANCELLED', updated_at=? WHERE id=?",
                    (int(time.time()), job_id))
            return self._get_locked(job_id)

    def process_once(self) -> bool:
        with self._transaction():
            row = self._db.execute(
                "SELECT id,payload,attempts,manifest_sha256 FROM jobs WHERE status='QUEUED' "
                "ORDER BY created_at,id LIMIT 1"
            ).fetchone()
            if row is None:
                return False
            job_id, encoded, attempts, manifest_sha256 = row
            if manifest_sha256 != self.service.manifest["manifestSha256"]:
                self._db.execute(
                    "UPDATE jobs SET status='FAILED',error_code='MODEL_SNAPSHOT_MISMATCH',updated_at=? "
                    "WHERE id=? AND status='QUEUED'", (int(time.time()), job_id))
                return True
            self._db.execute(
                "UPDATE jobs SET status='RUNNING',attempts=?,updated_at=? "
                "WHERE id=? AND status='QUEUED'",
                (attempts + 1, int(time.time()), job_id))
        try:
            # The output UUID is the queue job UUID: interrupted jobs cannot
            # produce unrelated completed artifacts on retry.
            result = self.service.synthesize(json.loads(encoded), output_id=job_id)
            with self._transaction():
                self._db.execute(
                    "UPDATE jobs SET status='SUCCEEDED',result=?,updated_at=?,error_code=NULL "
                    "WHERE id=? AND status='RUNNING'",
                    (json.dumps(result, sort_keys=True), int(time.time()), job_id))
            return True
        except Exception:
            LOG.exception("Queued synthesis failed: job_id=%s", job_id)
            with self._transaction():
                # Fail closed for runtime errors; only a crash during RUNNING
                # causes automatic replay at startup.
                self._db.execute(
                    "UPDATE jobs SET status='FAILED',error_code='SYNTHESIS_FAILED',updated_at=? "
                    "WHERE id=? AND status='RUNNING'", (int(time.time()), job_id))
            return True

    def _run(self):
        while not self._stop.is_set():
            if not self.process_once():
                self._wakeup.wait(0.5)
                self._wakeup.clear()

    @property
    def healthy(self) -> bool:
        return (not self._stop.is_set() and self._thread is not None
                and self._thread.is_alive())

    def stats(self) -> dict:
        with self._lock:
            rows = self._db.execute(
                "SELECT status, COUNT(*) FROM jobs GROUP BY status"
            ).fetchall()
        counts = {status.lower(): count for status, count in rows}
        return {
            "queuedJobs": counts.get("queued", 0),
            "runningJobs": counts.get("running", 0),
            "succeededJobs": counts.get("succeeded", 0),
            "failedJobs": counts.get("failed", 0),
            "cancelledJobs": counts.get("cancelled", 0),
            "maxQueueDepth": self.max_queued,
        }

    def start(self):
        if self._thread is not None:
            return
        self._thread = threading.Thread(target=self._run, name="kokoro-queue", daemon=False)
        self._thread.start()
        self._wakeup.set()

    def stop(self, *, timeout: float = 125):
        self._stop.set()
        self._wakeup.set()
        if self._thread is not None:
            self._thread.join(timeout)
            if self._thread.is_alive():
                raise QueueClosed("Inference still running; cannot close queue safely")
        with self._lock:
            self._db.close()
        fcntl.flock(self._owner_handle.fileno(), fcntl.LOCK_UN)
        self._owner_handle.close()
