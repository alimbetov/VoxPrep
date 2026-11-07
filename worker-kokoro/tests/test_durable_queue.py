"""Adversarial single-node durable queue acceptance without ONNX downloads."""
from __future__ import annotations

import json
import sqlite3
import threading
from dataclasses import replace

import httpx
import pytest

from voxprep_kokoro_worker.application.durable_queue import (
    DurableQueue, QueueClosed, QueueConflict, QueueFull,
)
from voxprep_kokoro_worker.standalone import StandaloneService, make_server
from test_standalone import fixture, FakeSynth, FakePost

PAYLOAD = {"text": "A reliable new synthesis job.", "voiceCode": "af_heart", "speed": 1.0}


def service_fixture(tmp_path):
    settings, _ = fixture(tmp_path)
    service = StandaloneService(settings, synthesizer=FakeSynth(), postprocessor=FakePost())
    service.startup()
    return settings, service


def test_queue_persists_and_deduplicates_across_restart(tmp_path):
    settings, service = service_fixture(tmp_path)
    root = settings.output_dir / "queue"
    queue = DurableQueue(root, service)
    first, created = queue.submit(PAYLOAD, "client-abc")
    assert created and first["status"] == "QUEUED"
    repeated, created = queue.submit(PAYLOAD, "client-abc")
    assert not created and repeated["id"] == first["id"]
    with pytest.raises(QueueConflict):
        queue.submit(PAYLOAD | {"text": "different"}, "client-abc")
    queue.stop()

    restarted = DurableQueue(root, service)
    assert restarted.get(first["id"])["status"] == "QUEUED"
    assert restarted.process_once()
    finished = restarted.get(first["id"])
    assert finished["status"] == "SUCCEEDED"
    assert finished["attempts"] == 1
    assert finished["result"]["id"] == first["id"]
    assert service.find(first["id"])["sha256"] == finished["result"]["sha256"]
    again, created = restarted.submit(PAYLOAD, "client-abc")
    assert not created and again["status"] == "SUCCEEDED"
    restarted.stop()


def test_running_crash_recovery_reuses_exact_output_identity(tmp_path):
    settings, service = service_fixture(tmp_path)
    root = settings.output_dir / "queue"
    queue = DurableQueue(root, service)
    job, _ = queue.submit(PAYLOAD, "recovery")
    # Emulate interrupted RUNNING state: committed output, no final DB state.
    with queue._transaction():
        queue._db.execute(
            "UPDATE jobs SET status='RUNNING',attempts=1 WHERE id=?", (job["id"],))
    created_output = service.synthesize(PAYLOAD, output_id=job["id"])
    queue.stop()

    recovered = DurableQueue(root, service)
    assert recovered.get(job["id"])["status"] == "QUEUED"
    # If inference runs again the fixture deliberately fails; recovery should
    # take the verified complete MP3 from the previous attempt.
    class FailingSynth:
        def synthesize(self, **kwargs):
            raise AssertionError("Already committed audio must not be synthesized twice")
    service.synthesizer = FailingSynth()
    assert recovered.process_once()
    assert recovered.get(job["id"])["status"] == "SUCCEEDED"
    assert recovered.get(job["id"])["result"] == created_output
    assert recovered.get(job["id"])["attempts"] == 2
    recovered.stop()


def test_crash_attempts_exhausted_and_single_owner_lock(tmp_path):
    settings, service = service_fixture(tmp_path)
    root = settings.output_dir / "queue"
    queue = DurableQueue(root, service)
    with pytest.raises(QueueClosed):
        DurableQueue(root, service)
    job, _ = queue.submit(PAYLOAD, None)
    with queue._transaction():
        queue._db.execute(
            "UPDATE jobs SET status='RUNNING',attempts=3 WHERE id=?", (job["id"],))
    queue.stop()
    recovered = DurableQueue(root, service)
    assert recovered.get(job["id"])["status"] == "FAILED"
    assert recovered.get(job["id"])["errorCode"] == "RETRY_EXHAUSTED"
    assert not recovered.process_once()
    recovered.stop()


def test_cancel_queued_only_and_capacity(tmp_path):
    settings, service = service_fixture(tmp_path)
    queue = DurableQueue(settings.output_dir / "queue", service, max_queued=1)
    first, _ = queue.submit(PAYLOAD, "first")
    with pytest.raises(QueueFull):
        queue.submit(PAYLOAD | {"text": "second"}, "second")
    assert queue.cancel(first["id"])["status"] == "CANCELLED"
    assert queue.cancel(first["id"])["status"] == "CANCELLED"
    second, _ = queue.submit(PAYLOAD | {"text": "second"}, "second")
    assert queue.process_once()
    assert queue.cancel(second["id"])["status"] == "SUCCEEDED"
    queue.stop()


def test_queue_no_duplicate_when_concurrent_idempotent_posts(tmp_path):
    from concurrent.futures import ThreadPoolExecutor
    settings, service = service_fixture(tmp_path)
    queue = DurableQueue(settings.output_dir / "queue", service)
    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(lambda _: queue.submit(PAYLOAD, "shared-key"), range(16)))
    assert len({item["id"] for item, _ in results}) == 1
    assert sum(created for _, created in results) == 1
    queue.stop()


def test_http_async_submit_status_audio_and_cancel(tmp_path):
    settings, service = service_fixture(tmp_path)
    queue = DurableQueue(settings.output_dir / "queue", service)
    server = make_server(settings, service, queue)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        headers = {"Authorization": "Bearer " + settings.token}
        with httpx.Client(base_url="http://127.0.0.1:" + str(server.server_address[1])) as client:
            response = client.post("/v1/tts/jobs", json=PAYLOAD, headers=headers)
            assert response.status_code == 202
            ident = response.json()["id"]
            assert response.json()["status"] == "QUEUED"
            assert client.get(f"/v1/tts/jobs/{ident}", headers=headers).json()["status"] == "QUEUED"
            assert client.get(f"/v1/tts/jobs/{ident}/audio", headers=headers).status_code == 409
            assert client.post(f"/v1/tts/jobs/{ident}/cancel", headers=headers).json()["status"] == "CANCELLED"
            assert client.post(f"/v1/tts/jobs/{ident}/cancel", headers=headers).status_code == 200
            assert client.post("/v1/tts/jobs", json=PAYLOAD,
                               headers=headers | {"Idempotency-Key": "example-key"}).status_code == 202
            dup = client.post("/v1/tts/jobs", json=PAYLOAD,
                              headers=headers | {"Idempotency-Key": "example-key"})
            assert dup.status_code == 200
            assert client.post("/v1/tts/jobs", json=PAYLOAD | {"text": "changed"},
                               headers=headers | {"Idempotency-Key": "example-key"}).status_code == 409
            assert queue.process_once()
            successful = queue.get(dup.json()["id"])
            assert successful["status"] == "SUCCEEDED"
            assert client.get(f"/v1/tts/jobs/{successful['id']}/audio",
                              headers=headers).content == b"safe-mp3-output"
            assert client.get(f"/v1/tts/jobs/{successful['id']}", headers=headers).json()["status"] == "SUCCEEDED"
            assert client.get(f"/v1/tts/jobs/{successful['id']}").status_code == 401
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)
        queue.stop()


def test_queue_synthesis_error_is_failed_and_no_text_leaked(tmp_path):
    settings, service = service_fixture(tmp_path)
    class BrokenSynth:
        def synthesize(self, **kwargs):
            raise RuntimeError("sensitive internal diagnostic")
    service.synthesizer = BrokenSynth()
    queue = DurableQueue(settings.output_dir / "queue", service)
    job, _ = queue.submit(PAYLOAD, "bad-worker")
    assert queue.process_once()
    status = queue.get(job["id"])
    assert status["status"] == "FAILED"
    assert status["errorCode"] == "SYNTHESIS_FAILED"
    assert "sensitive" not in json.dumps(status)
    queue.stop()

def test_background_queue_liveness_and_persistent_metrics(tmp_path):
    import time
    settings, service = service_fixture(tmp_path)
    queue = DurableQueue(settings.output_dir / "queue", service)
    assert not queue.healthy
    queued, _ = queue.submit(PAYLOAD, "background-1")
    assert queue.stats()["queuedJobs"] == 1
    server = make_server(settings, service, queue)
    server_thread = threading.Thread(target=server.serve_forever, daemon=True)
    server_thread.start()
    try:
        with httpx.Client(base_url="http://127.0.0.1:" + str(server.server_address[1])) as client:
            headers = {"Authorization": "Bearer " + settings.token}
            assert client.get("/health/ready", headers=headers).status_code == 503
            queue.start()
            assert queue.healthy
            assert client.get("/health/ready", headers=headers).status_code == 200
            deadline = time.monotonic() + 5
            while queue.get(queued["id"])["status"] != "SUCCEEDED" and time.monotonic() < deadline:
                time.sleep(0.02)
            assert queue.get(queued["id"])["status"] == "SUCCEEDED"
            metrics = client.get("/v1/metrics", headers=headers).json()
            assert metrics["succeededJobs"] == 1
            assert metrics["queuedJobs"] == 0
            assert metrics["maxQueueDepth"] == 100
            assert client.get(f"/v1/tts/jobs/{queued['id']}/audio",
                              headers=headers).content == b"safe-mp3-output"
    finally:
        server.shutdown()
        server.server_close()
        server_thread.join(timeout=5)
        queue.stop()

def test_model_upgrade_cannot_reinterpret_queued_job(tmp_path):
    settings, service = service_fixture(tmp_path)
    queue = DurableQueue(settings.output_dir / "queue", service)
    queued, _ = queue.submit(PAYLOAD, "fixed-content-revision")
    saved_manifest = service.manifest
    service.manifest = dict(saved_manifest, manifestSha256="b" * 64)
    try:
        assert queue.process_once()
        status = queue.get(queued["id"])
        assert status["status"] == "FAILED"
        assert status["errorCode"] == "MODEL_SNAPSHOT_MISMATCH"
        assert list(settings.output_dir.glob("*.mp3")) == []
        with pytest.raises(QueueConflict):
            queue.submit(PAYLOAD, "fixed-content-revision")
    finally:
        service.manifest = saved_manifest
        queue.stop()


def test_legacy_queue_migration_fails_closed_on_missing_bundle_identity(tmp_path):
    settings, service = service_fixture(tmp_path)
    root = settings.output_dir / "queue"
    root.mkdir(parents=True)
    database = sqlite3.connect(root / "jobs.sqlite3")
    try:
        database.execute("""
            CREATE TABLE jobs (
              id TEXT PRIMARY KEY, idempotency_key TEXT UNIQUE,
              fingerprint TEXT NOT NULL, payload TEXT NOT NULL,
              status TEXT NOT NULL, attempts INTEGER NOT NULL DEFAULT 0,
              created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL,
              result TEXT, error_code TEXT
            )
        """)
        from uuid import uuid4
        ident = str(uuid4())
        database.execute(
            "INSERT INTO jobs(id,fingerprint,payload,status,created_at,updated_at) VALUES(?,?,?,?,?,?)",
            (ident, "a" * 64, json.dumps(PAYLOAD), "QUEUED", 1, 1))
        database.commit()
    finally:
        database.close()
    queue = DurableQueue(root, service)
    try:
        assert queue.process_once()
        assert queue.get(ident)["errorCode"] == "MODEL_SNAPSHOT_MISMATCH"
    finally:
        queue.stop()

def test_second_instance_cannot_delete_first_instances_working_files(tmp_path):
    settings, first_service = service_fixture(tmp_path)
    root = settings.output_dir / "queue"
    owner = DurableQueue(root, first_service)
    active = settings.temp_dir / "standalone-active-inference"
    active.mkdir()
    file = active / "audio.wav"
    file.write_bytes(b"still-in-use")
    second_service = StandaloneService(
        settings, synthesizer=FakeSynth(), postprocessor=FakePost())
    assert file.read_bytes() == b"still-in-use"
    with pytest.raises(QueueClosed):
        DurableQueue(root, second_service)
    assert file.read_bytes() == b"still-in-use"
    owner.stop()
    recovered = DurableQueue(root, second_service)
    try:
        assert not active.exists()
    finally:
        recovered.stop()
