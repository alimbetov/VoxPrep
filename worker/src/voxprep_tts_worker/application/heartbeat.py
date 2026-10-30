from __future__ import annotations

import logging
import threading

from voxprep_tts_worker.domain.errors import LeaseLostError, WorkerError
from voxprep_tts_worker.domain.job import ClaimedJob
from voxprep_tts_worker.ports.backend import BackendPort

logger = logging.getLogger(__name__)


class LeaseHeartbeat:
    def __init__(
        self,
        *,
        backend: BackendPort,
        worker_id: str,
        job: ClaimedJob,
        interval_seconds: float,
    ) -> None:
        self._backend = backend
        self._worker_id = worker_id
        self._job = job
        self._interval_seconds = interval_seconds
        self._stop = threading.Event()
        self._lease_lost = threading.Event()
        self._thread = threading.Thread(
            target=self._run,
            name=f"tts-heartbeat-{job.job_id}",
            daemon=True,
        )

    def __enter__(self) -> "LeaseHeartbeat":
        self._thread.start()
        return self

    def __exit__(self, exc_type: object, exc: object, traceback: object) -> None:
        self._stop.set()
        self._thread.join(timeout=max(1.0, self._interval_seconds + 1.0))

    def assert_owned(self) -> None:
        if self._lease_lost.is_set():
            raise LeaseLostError("Backend lease ownership was lost")

    def revalidate(self) -> None:
        self.assert_owned()
        try:
            self._backend.heartbeat(worker_id=self._worker_id, job=self._job)
        except LeaseLostError:
            self._lease_lost.set()
            raise
        self.assert_owned()

    def _run(self) -> None:
        while not self._stop.wait(self._interval_seconds):
            try:
                self._backend.heartbeat(worker_id=self._worker_id, job=self._job)
            except LeaseLostError:
                self._lease_lost.set()
                return
            except WorkerError:
                logger.warning(
                    "heartbeat failed; lease will be revalidated before finalization",
                    extra={"worker_id": self._worker_id, "job_id": self._job.job_id},
                    exc_info=True,
                )
