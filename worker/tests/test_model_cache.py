from __future__ import annotations

import hashlib
from datetime import datetime, timezone
from pathlib import Path

import pytest

from voxprep_tts_worker.adapters.model_cache import BackendModelCache
from voxprep_tts_worker.domain.errors import ModelChecksumError
from voxprep_tts_worker.domain.job import ClaimedJob


MODEL_BYTES = b"model-bytes-v1"
CONFIG_BYTES = b'{"audio":{"sample_rate":22050}}'


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _job(*, model_sha: str | None = None) -> ClaimedJob:
    return ClaimedJob(
        job_id="job-1",
        file_id="file-1",
        content_revision_id="revision-1",
        audio_role="PRIMARY",
        normalized_tts_text="Hello",
        language="en-US",
        voice_model_id="model-1",
        voice_model_code="voice-1",
        model_sha256=model_sha or _sha(MODEL_BYTES),
        config_sha256=_sha(CONFIG_BYTES),
        fingerprint="c" * 64,
        lease_token="lease-1",
        lease_until=datetime(2030, 1, 1, tzinfo=timezone.utc),
    )


class FakeModelSource:
    def __init__(self) -> None:
        self.model_downloads = 0
        self.config_downloads = 0

    def download_model(self, *, job: ClaimedJob, destination: Path) -> None:
        self.model_downloads += 1
        destination.write_bytes(MODEL_BYTES)

    def download_config(self, *, job: ClaimedJob, destination: Path) -> None:
        self.config_downloads += 1
        destination.write_bytes(CONFIG_BYTES)


def test_cache_miss_downloads_exact_revision_and_reuses_it(tmp_path: Path) -> None:
    source = FakeModelSource()
    cache = BackendModelCache(cache_root=tmp_path / "models", source=source)
    job = _job()

    first = cache.ensure_model(job)
    second = cache.ensure_model(job)

    assert first == second
    assert first == tmp_path / "models" / "model-1" / job.model_sha256
    assert (first / "model.onnx").read_bytes() == MODEL_BYTES
    assert (first / "model.onnx.json").read_bytes() == CONFIG_BYTES
    assert (first / "installed.json").is_file()
    assert source.model_downloads == 1
    assert source.config_downloads == 1


def test_checksum_mismatch_never_installs_revision(tmp_path: Path) -> None:
    source = FakeModelSource()
    cache = BackendModelCache(cache_root=tmp_path / "models", source=source)
    job = _job(model_sha="0" * 64)

    with pytest.raises(ModelChecksumError):
        cache.ensure_model(job)

    final_dir = tmp_path / "models" / "model-1" / job.model_sha256
    assert not final_dir.exists()


def test_corrupt_cached_revision_is_replaced_from_backend(tmp_path: Path) -> None:
    source = FakeModelSource()
    cache = BackendModelCache(cache_root=tmp_path / "models", source=source)
    job = _job()
    final_dir = tmp_path / "models" / "model-1" / job.model_sha256
    final_dir.mkdir(parents=True)
    (final_dir / "model.onnx").write_bytes(b"corrupt")
    (final_dir / "model.onnx.json").write_bytes(CONFIG_BYTES)

    resolved = cache.ensure_model(job)

    assert resolved == final_dir
    assert (resolved / "model.onnx").read_bytes() == MODEL_BYTES
    assert source.model_downloads == 1
    assert source.config_downloads == 1
