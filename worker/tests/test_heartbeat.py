from __future__ import annotations

from datetime import datetime, timezone

import pytest

from voxprep_tts_worker.application.heartbeat import LeaseHeartbeat
from voxprep_tts_worker.domain.errors import BackendTransportError, LeaseLostError
from voxprep_tts_worker.domain.job import ClaimedJob


def _job() -> ClaimedJob:
    return ClaimedJob(
        job_id="job-1",
        file_id="file-1",
        content_revision_id="revision-1",
        audio_role="PRIMARY",
        normalized_tts_text="Hello",
        language="en-US",
        voice_model_id="model-1",
        voice_model_code="voice-1",
        model_sha256="a" * 64,
        config_sha256="b" * 64,
        fingerprint="c" * 64,
        lease_token="lease-1",
        lease_until=datetime(2030, 1, 1, tzinfo=timezone.utc),
    )


class Backend:
    def __init__(self, outcomes: list[Exception | None]) -> None:
        self.outcomes = outcomes
        self.calls = 0

    def heartbeat(self, *, worker_id: str, job: ClaimedJob) -> None:
        assert worker_id == "worker-1"
        assert job.lease_token == "lease-1"
        self.calls += 1
        outcome = self.outcomes.pop(0) if self.outcomes else None
        if outcome is not None:
            raise outcome


def _heartbeat(backend: Backend) -> LeaseHeartbeat:
    return LeaseHeartbeat(
        backend=backend,  # type: ignore[arg-type]
        worker_id="worker-1",
        job=_job(),
        interval_seconds=3600,
    )


def test_revalidate_confirms_current_lease() -> None:
    backend = Backend([None])
    heartbeat = _heartbeat(backend)

    heartbeat.revalidate()
    heartbeat.assert_owned()

    assert backend.calls == 1


def test_revalidate_marks_lease_lost_and_fails_closed_afterward() -> None:
    backend = Backend([LeaseLostError("stale")])
    heartbeat = _heartbeat(backend)

    with pytest.raises(LeaseLostError, match="stale"):
        heartbeat.revalidate()

    with pytest.raises(LeaseLostError, match="ownership was lost"):
        heartbeat.assert_owned()

    with pytest.raises(LeaseLostError, match="ownership was lost"):
        heartbeat.revalidate()

    assert backend.calls == 1


def test_transient_revalidation_error_does_not_mark_lease_lost() -> None:
    backend = Backend([BackendTransportError("temporary"), None])
    heartbeat = _heartbeat(backend)

    with pytest.raises(BackendTransportError, match="temporary"):
        heartbeat.revalidate()

    heartbeat.assert_owned()
    heartbeat.revalidate()

    assert backend.calls == 2
