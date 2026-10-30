from __future__ import annotations

import threading
from datetime import datetime, timezone

from voxprep_tts_worker.application.worker_loop import WorkerLoop
from voxprep_tts_worker.domain.job import ClaimedJob


def _job() -> ClaimedJob:
    return ClaimedJob(
        job_id="job-1",
        file_id="file-1",
        content_revision_id="revision-1",
        audio_role="PRIMARY",
        normalized_tts_text="Hello.",
        language="en-US",
        voice_model_id="model-1",
        voice_model_code="voice-1",
        model_sha256="a" * 64,
        config_sha256="b" * 64,
        fingerprint="c" * 64,
        lease_token="lease-1",
        lease_until=datetime(2030, 1, 1, tzinfo=timezone.utc),
    )


class QueueBackend:
    def __init__(self, jobs: list[ClaimedJob | None]) -> None:
        self.jobs = jobs
        self.claims: list[str] = []

    def claim(self, worker_id: str) -> ClaimedJob | None:
        self.claims.append(worker_id)
        return self.jobs.pop(0) if self.jobs else None


class RecordingProcessor:
    def __init__(self) -> None:
        self.jobs: list[ClaimedJob] = []

    def process(self, job: ClaimedJob) -> None:
        self.jobs.append(job)


def test_run_once_processes_one_claimed_job() -> None:
    shutdown = threading.Event()
    backend = QueueBackend([_job()])
    processor = RecordingProcessor()
    loop = WorkerLoop(
        worker_id="worker-a",
        backend=backend,  # type: ignore[arg-type]
        processor=processor,  # type: ignore[arg-type]
        poll_interval_seconds=1,
        shutdown=shutdown,
    )

    assert loop.run_once() is True
    assert backend.claims == ["worker-a"]
    assert [job.job_id for job in processor.jobs] == ["job-1"]


def test_run_once_is_idle_when_backend_has_no_job() -> None:
    shutdown = threading.Event()
    backend = QueueBackend([None])
    processor = RecordingProcessor()
    loop = WorkerLoop(
        worker_id="worker-a",
        backend=backend,  # type: ignore[arg-type]
        processor=processor,  # type: ignore[arg-type]
        poll_interval_seconds=1,
        shutdown=shutdown,
    )

    assert loop.run_once() is False
    assert processor.jobs == []


def test_shutdown_prevents_new_claims() -> None:
    shutdown = threading.Event()
    shutdown.set()
    backend = QueueBackend([_job()])
    processor = RecordingProcessor()
    loop = WorkerLoop(
        worker_id="worker-a",
        backend=backend,  # type: ignore[arg-type]
        processor=processor,  # type: ignore[arg-type]
        poll_interval_seconds=1,
        shutdown=shutdown,
    )

    assert loop.run_once() is False
    assert backend.claims == []
    assert processor.jobs == []
