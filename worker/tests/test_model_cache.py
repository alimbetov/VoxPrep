from __future__ import annotations

import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path

import pytest

from voxprep_tts_worker.adapters.model_cache import BackendModelCache
from voxprep_tts_worker.domain.errors import ModelChecksumError, ModelDownloadError
from voxprep_tts_worker.domain.job import ClaimedJob


MODEL_BYTES = b"model-bytes-v1"
CONFIG_BYTES = b'{"audio":{"sample_rate":22050}}'


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _job(
    *,
    voice_model_id: str = "model-1",
    model_sha: str | None = None,
    config_sha: str | None = None,
) -> ClaimedJob:
    return ClaimedJob(
        job_id="job-1",
        file_id="file-1",
        content_revision_id="revision-1",
        audio_role="PRIMARY",
        normalized_tts_text="Hello",
        language="en-US",
        voice_model_id=voice_model_id,
        voice_model_code="voice-1",
        model_sha256=model_sha or _sha(MODEL_BYTES),
        config_sha256=config_sha or _sha(CONFIG_BYTES),
        fingerprint="c" * 64,
        lease_token="lease-1",
        lease_until=datetime(2030, 1, 1, tzinfo=timezone.utc),
    )


def _size(path: Path) -> int:
    return sum(item.stat().st_size for item in path.rglob("*") if item.is_file())


class FakeModelSource:
    def __init__(
        self,
        *,
        model_bytes: bytes = MODEL_BYTES,
        config_bytes: bytes = CONFIG_BYTES,
        fail_model: bool = False,
        fail_config: bool = False,
    ) -> None:
        self.model_downloads = 0
        self.config_downloads = 0
        self.model_bytes = model_bytes
        self.config_bytes = config_bytes
        self.fail_model = fail_model
        self.fail_config = fail_config

    def download_model(self, *, job: ClaimedJob, destination: Path) -> None:
        self.model_downloads += 1
        if self.fail_model:
            raise ModelDownloadError("model unavailable")
        destination.write_bytes(self.model_bytes)

    def download_config(self, *, job: ClaimedJob, destination: Path) -> None:
        self.config_downloads += 1
        if self.fail_config:
            raise ModelDownloadError("config unavailable")
        destination.write_bytes(self.config_bytes)


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
    metadata = json.loads((first / "installed.json").read_text(encoding="utf-8"))
    assert metadata == {
        "configSha256": job.config_sha256,
        "modelSha256": job.model_sha256,
        "voiceModelCode": "voice-1",
        "voiceModelId": "model-1",
    }
    assert source.model_downloads == 1
    assert source.config_downloads == 1


def test_model_checksum_mismatch_never_installs_revision(tmp_path: Path) -> None:
    source = FakeModelSource()
    cache = BackendModelCache(cache_root=tmp_path / "models", source=source)
    job = _job(model_sha="0" * 64)

    with pytest.raises(ModelChecksumError, match="model checksum"):
        cache.ensure_model(job)

    final_dir = tmp_path / "models" / "model-1" / job.model_sha256
    assert not final_dir.exists()
    assert list(final_dir.parent.glob(f".{job.model_sha256}-*")) == []
    assert source.config_downloads == 0


def test_config_checksum_mismatch_never_installs_revision(tmp_path: Path) -> None:
    source = FakeModelSource()
    cache = BackendModelCache(cache_root=tmp_path / "models", source=source)
    job = _job(config_sha="0" * 64)

    with pytest.raises(ModelChecksumError, match="config checksum"):
        cache.ensure_model(job)

    final_dir = tmp_path / "models" / "model-1" / job.model_sha256
    assert not final_dir.exists()
    assert list(final_dir.parent.glob(f".{job.model_sha256}-*")) == []
    assert source.model_downloads == 1
    assert source.config_downloads == 1


def test_download_failure_leaves_no_final_or_partial_revision(tmp_path: Path) -> None:
    source = FakeModelSource(fail_config=True)
    cache = BackendModelCache(cache_root=tmp_path / "models", source=source)
    job = _job()

    with pytest.raises(ModelDownloadError, match="config unavailable"):
        cache.ensure_model(job)

    final_dir = tmp_path / "models" / "model-1" / job.model_sha256
    assert not final_dir.exists()
    assert list(final_dir.parent.glob(f".{job.model_sha256}-*")) == []


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


def test_different_model_ids_never_share_cache_revision(tmp_path: Path) -> None:
    source = FakeModelSource()
    cache = BackendModelCache(cache_root=tmp_path / "models", source=source)

    first = cache.ensure_model(_job(voice_model_id="model-a"))
    second = cache.ensure_model(_job(voice_model_id="model-b"))

    assert first != second
    assert first.parent.name == "model-a"
    assert second.parent.name == "model-b"
    assert source.model_downloads == 2
    assert source.config_downloads == 2


def test_cache_prunes_least_recent_revision_and_keeps_current(tmp_path: Path) -> None:
    source = FakeModelSource()
    cache_root = tmp_path / "models"
    unlimited = BackendModelCache(
        cache_root=cache_root,
        source=source,
        max_cache_bytes=1024 * 1024,
    )
    first = unlimited.ensure_model(_job(voice_model_id="model-a"))
    second_job = _job(voice_model_id="model-b")
    second = unlimited.ensure_model(second_job)

    os.utime(first / "installed.json", ns=(1, 1))
    os.utime(second / "installed.json", ns=(2, 2))
    current_size = _size(second)

    pruning_cache = BackendModelCache(
        cache_root=cache_root,
        source=source,
        max_cache_bytes=current_size,
    )
    resolved = pruning_cache.ensure_model(second_job)

    assert resolved == second
    assert second.exists()
    assert not first.exists()


def test_cache_never_prunes_current_revision_even_when_it_exceeds_limit(tmp_path: Path) -> None:
    source = FakeModelSource()
    cache = BackendModelCache(
        cache_root=tmp_path / "models",
        source=source,
        max_cache_bytes=1,
    )

    resolved = cache.ensure_model(_job())

    assert resolved.exists()
    assert (resolved / "model.onnx").is_file()


def test_cache_rejects_non_positive_size_limit(tmp_path: Path) -> None:
    with pytest.raises(ValueError, match="must be > 0"):
        BackendModelCache(
            cache_root=tmp_path / "models",
            source=FakeModelSource(),
            max_cache_bytes=0,
        )
