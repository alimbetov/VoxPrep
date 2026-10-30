from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from pathlib import Path

from voxprep_tts_worker.application.job_processor import JobProcessor
from voxprep_tts_worker.domain.errors import (
    BackendTransportError,
    LeaseLostError,
    ModelUnavailableError,
    PostprocessError,
    SynthesisError,
)
from voxprep_tts_worker.domain.job import AudioArtifact, ClaimedJob


def _job() -> ClaimedJob:
    return ClaimedJob(
        job_id="job-123",
        file_id="file-456",
        content_revision_id="revision-789",
        audio_role="PRIMARY",
        normalized_tts_text="Tell me about yourself.",
        language="en-US",
        voice_model_id="model-1",
        voice_model_code="en_US-lessac-high-v1",
        model_sha256="a" * 64,
        config_sha256="b" * 64,
        fingerprint="c" * 64,
        lease_token="lease-abc",
        lease_until=datetime(2030, 1, 1, tzinfo=timezone.utc),
    )


class FakeBackend:
    def __init__(
        self,
        *,
        lose_lease_on_upload: bool = False,
        lose_lease_on_heartbeat: bool = False,
        transport_error_on_upload: bool = False,
        transport_error_on_fail: bool = False,
    ) -> None:
        self.uploaded: tuple[str, ClaimedJob, AudioArtifact] | None = None
        self.failures: list[tuple[str, ClaimedJob, str, str]] = []
        self.lose_lease_on_upload = lose_lease_on_upload
        self.lose_lease_on_heartbeat = lose_lease_on_heartbeat
        self.transport_error_on_upload = transport_error_on_upload
        self.transport_error_on_fail = transport_error_on_fail
        self.heartbeats = 0

    def claim(self, worker_id: str) -> ClaimedJob | None:
        raise AssertionError("claim is not used by JobProcessor tests")

    def heartbeat(self, *, worker_id: str, job: ClaimedJob) -> None:
        self.heartbeats += 1
        if self.lose_lease_on_heartbeat:
            raise LeaseLostError("stale lease")

    def upload_output(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        artifact: AudioArtifact,
    ) -> None:
        if self.lose_lease_on_upload:
            raise LeaseLostError("stale lease")
        if self.transport_error_on_upload:
            raise BackendTransportError("response lost")
        self.uploaded = (worker_id, job, artifact)

    def fail(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        error_code: str,
        error_message: str,
    ) -> None:
        if self.transport_error_on_fail:
            raise BackendTransportError("failure callback unavailable")
        self.failures.append((worker_id, job, error_code, error_message))


class FakeModelCache:
    def __init__(self, root: Path, *, fail: bool = False) -> None:
        self.root = root
        self.fail = fail
        self.seen_job: ClaimedJob | None = None

    def ensure_model(self, job: ClaimedJob) -> Path:
        self.seen_job = job
        if self.fail:
            raise ModelUnavailableError("model missing")
        model_dir = self.root / job.voice_model_id / job.model_sha256
        model_dir.mkdir(parents=True, exist_ok=True)
        return model_dir


class FakeSynthesizer:
    def __init__(self, *, fail: bool = False) -> None:
        self.fail = fail
        self.seen_job: ClaimedJob | None = None

    def synthesize(self, *, job: ClaimedJob, model_dir: Path, output_wav: Path) -> Path:
        self.seen_job = job
        if self.fail:
            raise SynthesisError("fake synthesis failed")
        assert model_dir.name == job.model_sha256
        output_wav.write_bytes(b"RIFF-fake-wav")
        return output_wav


class FakePostprocessor:
    def __init__(self, *, fail: bool = False) -> None:
        self.fail = fail
        self.seen_job: ClaimedJob | None = None

    def postprocess(self, *, job: ClaimedJob, input_wav: Path, output_mp3: Path) -> AudioArtifact:
        self.seen_job = job
        assert input_wav.exists()
        if self.fail:
            raise PostprocessError("fake ffmpeg failed")
        payload = b"fake-mp3"
        output_mp3.write_bytes(payload)
        return AudioArtifact(
            path=output_mp3,
            content_type="audio/mpeg",
            audio_profile="mp3-mono-24k-64k-v1",
            sha256=hashlib.sha256(payload).hexdigest(),
            size_bytes=len(payload),
            duration_ms=1000,
        )


def _processor(
    tmp_path: Path,
    backend: FakeBackend,
    *,
    model_cache: FakeModelCache | None = None,
    synthesizer: FakeSynthesizer | None = None,
    postprocessor: FakePostprocessor | None = None,
    heartbeat_interval_seconds: float | None = None,
) -> tuple[JobProcessor, FakeModelCache, FakeSynthesizer, FakePostprocessor]:
    temp_dir = tmp_path / "tmp"
    temp_dir.mkdir()
    cache = model_cache or FakeModelCache(tmp_path / "models")
    synth = synthesizer or FakeSynthesizer()
    post = postprocessor or FakePostprocessor()
    processor = JobProcessor(
        worker_id="worker-01",
        temp_dir=temp_dir,
        backend=backend,
        model_cache=cache,
        synthesizer=synth,
        postprocessor=post,
        heartbeat_interval_seconds=heartbeat_interval_seconds,
    )
    return processor, cache, synth, post


def test_processor_preserves_backend_owned_job_file_and_lease_identity(tmp_path: Path) -> None:
    backend = FakeBackend()
    processor, model_cache, synth, post = _processor(tmp_path, backend)
    job = _job()

    processor.process(job)

    assert model_cache.seen_job is job
    assert synth.seen_job is job
    assert post.seen_job is job
    assert backend.uploaded is not None
    worker_id, uploaded_job, artifact = backend.uploaded
    assert worker_id == "worker-01"
    assert uploaded_job.job_id == "job-123"
    assert uploaded_job.file_id == "file-456"
    assert uploaded_job.lease_token == "lease-abc"
    assert artifact.content_type == "audio/mpeg"
    assert artifact.audio_profile == "mp3-mono-24k-64k-v1"
    assert list((tmp_path / "tmp").iterdir()) == []


def test_lease_loss_on_upload_never_reports_fail_or_finalizes(tmp_path: Path) -> None:
    backend = FakeBackend(lose_lease_on_upload=True)
    processor, _, _, _ = _processor(tmp_path, backend)

    processor.process(_job())

    assert backend.uploaded is None
    assert backend.failures == []
    assert list((tmp_path / "tmp").iterdir()) == []


def test_lease_loss_during_revalidation_prevents_upload_and_fail(tmp_path: Path) -> None:
    backend = FakeBackend(lose_lease_on_heartbeat=True)
    processor, _, _, _ = _processor(
        tmp_path, backend, heartbeat_interval_seconds=3600
    )

    processor.process(_job())

    assert backend.heartbeats == 1
    assert backend.uploaded is None
    assert backend.failures == []
    assert list((tmp_path / "tmp").iterdir()) == []


def test_backend_response_loss_after_upload_never_reports_false_failure(tmp_path: Path) -> None:
    backend = FakeBackend(transport_error_on_upload=True)
    processor, _, _, _ = _processor(tmp_path, backend)

    processor.process(_job())

    assert backend.uploaded is None
    assert backend.failures == []
    assert list((tmp_path / "tmp").iterdir()) == []


def test_heartbeat_revalidates_lease_before_upload(tmp_path: Path) -> None:
    backend = FakeBackend()
    processor, _, _, _ = _processor(
        tmp_path,
        backend,
        heartbeat_interval_seconds=3600,
    )

    processor.process(_job())

    assert backend.uploaded is not None
    assert backend.heartbeats == 1


def test_missing_model_is_reported_with_classified_error(tmp_path: Path) -> None:
    backend = FakeBackend()
    cache = FakeModelCache(tmp_path / "models", fail=True)
    processor, _, _, _ = _processor(tmp_path, backend, model_cache=cache)

    processor.process(_job())

    assert backend.uploaded is None
    assert len(backend.failures) == 1
    assert backend.failures[0][2:] == ("VOICE_MODEL_NOT_FOUND", "model missing")
    assert list((tmp_path / "tmp").iterdir()) == []


def test_classified_synthesis_failure_is_reported_and_temp_is_cleaned(tmp_path: Path) -> None:
    backend = FakeBackend()
    processor, _, _, _ = _processor(
        tmp_path,
        backend,
        synthesizer=FakeSynthesizer(fail=True),
    )

    processor.process(_job())

    assert backend.uploaded is None
    assert len(backend.failures) == 1
    worker_id, failed_job, error_code, error_message = backend.failures[0]
    assert worker_id == "worker-01"
    assert failed_job.job_id == "job-123"
    assert failed_job.file_id == "file-456"
    assert error_code == "PIPER_SYNTHESIS_FAILED"
    assert error_message == "fake synthesis failed"
    assert list((tmp_path / "tmp").iterdir()) == []


def test_postprocess_failure_is_reported_with_ffmpeg_code(tmp_path: Path) -> None:
    backend = FakeBackend()
    processor, _, _, _ = _processor(
        tmp_path,
        backend,
        postprocessor=FakePostprocessor(fail=True),
    )

    processor.process(_job())

    assert backend.uploaded is None
    assert len(backend.failures) == 1
    assert backend.failures[0][2:] == ("FFMPEG_FAILED", "fake ffmpeg failed")
    assert list((tmp_path / "tmp").iterdir()) == []


def test_backend_outage_while_reporting_failure_relies_on_lease_recovery(tmp_path: Path) -> None:
    backend = FakeBackend(transport_error_on_fail=True)
    processor, _, _, _ = _processor(
        tmp_path,
        backend,
        synthesizer=FakeSynthesizer(fail=True),
    )

    processor.process(_job())

    assert backend.uploaded is None
    assert backend.failures == []
    assert list((tmp_path / "tmp").iterdir()) == []


def test_reclaimed_same_job_id_uses_new_attempt_directory(tmp_path: Path) -> None:
    backend = FakeBackend()
    processor, _, _, _ = _processor(tmp_path, backend)
    stale = tmp_path / "tmp" / "job-123-stale"
    stale.mkdir()
    (stale / "partial.wav").write_bytes(b"partial")

    processor.process(_job())

    assert backend.uploaded is not None
    assert stale.exists()
    assert sorted(path.name for path in (tmp_path / "tmp").iterdir()) == ["job-123-stale"]
