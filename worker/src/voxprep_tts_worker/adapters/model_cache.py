from __future__ import annotations

import hashlib
import json
import shutil
import tempfile
from pathlib import Path

from voxprep_tts_worker.domain.errors import (
    ModelCacheInstallError,
    ModelChecksumError,
)
from voxprep_tts_worker.domain.job import ClaimedJob
from voxprep_tts_worker.ports.backend import ModelSourcePort

_DEFAULT_MAX_CACHE_BYTES = 5 * 1024 * 1024 * 1024


class BackendModelCache:
    def __init__(
        self,
        *,
        cache_root: Path,
        source: ModelSourcePort,
        max_cache_bytes: int = _DEFAULT_MAX_CACHE_BYTES,
    ) -> None:
        if max_cache_bytes <= 0:
            raise ValueError("max_cache_bytes must be > 0")
        self._cache_root = cache_root
        self._source = source
        self._max_cache_bytes = max_cache_bytes

    def ensure_model(self, job: ClaimedJob) -> Path:
        final_dir = self._cache_root / job.voice_model_id / job.model_sha256
        model_path = final_dir / "model.onnx"
        config_path = final_dir / "model.onnx.json"

        if self._is_valid(model_path, job.model_sha256) and self._is_valid(
            config_path, job.config_sha256
        ):
            self._mark_used(final_dir)
            self._prune(protected=final_dir)
            return final_dir

        if final_dir.exists():
            shutil.rmtree(final_dir, ignore_errors=True)

        parent = final_dir.parent
        parent.mkdir(parents=True, exist_ok=True)
        temp_dir = Path(tempfile.mkdtemp(prefix=f".{job.model_sha256}-", dir=parent))

        try:
            temp_model = temp_dir / "model.onnx"
            temp_config = temp_dir / "model.onnx.json"
            self._source.download_model(job=job, destination=temp_model)
            self._verify(temp_model, job.model_sha256, "model")
            self._source.download_config(job=job, destination=temp_config)
            self._verify(temp_config, job.config_sha256, "config")

            (temp_dir / "installed.json").write_text(
                json.dumps(
                    {
                        "voiceModelId": job.voice_model_id,
                        "voiceModelCode": job.voice_model_code,
                        "modelSha256": job.model_sha256,
                        "configSha256": job.config_sha256,
                    },
                    sort_keys=True,
                ),
                encoding="utf-8",
            )

            if final_dir.exists():
                if self._is_valid(model_path, job.model_sha256) and self._is_valid(
                    config_path, job.config_sha256
                ):
                    self._mark_used(final_dir)
                    self._prune(protected=final_dir)
                    return final_dir
                shutil.rmtree(final_dir, ignore_errors=True)

            temp_dir.rename(final_dir)
            self._mark_used(final_dir)
            self._prune(protected=final_dir)
            return final_dir
        except ModelChecksumError:
            raise
        except OSError as exc:
            raise ModelCacheInstallError("Voice model cache installation failed") from exc
        finally:
            if temp_dir.exists():
                shutil.rmtree(temp_dir, ignore_errors=True)

    def _prune(self, *, protected: Path) -> None:
        revisions: list[tuple[int, int, Path]] = []
        total_bytes = 0
        if not self._cache_root.exists():
            return

        for model_dir in self._cache_root.iterdir():
            if not model_dir.is_dir() or model_dir.name.startswith("."):
                continue
            for revision_dir in model_dir.iterdir():
                if not revision_dir.is_dir() or revision_dir.name.startswith("."):
                    continue
                size_bytes = _directory_size(revision_dir)
                marker = revision_dir / "installed.json"
                try:
                    last_used_ns = (marker if marker.exists() else revision_dir).stat().st_mtime_ns
                except OSError:
                    last_used_ns = 0
                revisions.append((last_used_ns, size_bytes, revision_dir))
                total_bytes += size_bytes

        if total_bytes <= self._max_cache_bytes:
            return

        for _, size_bytes, revision_dir in sorted(revisions, key=lambda item: item[0]):
            if total_bytes <= self._max_cache_bytes:
                break
            if revision_dir == protected:
                continue
            shutil.rmtree(revision_dir, ignore_errors=True)
            if revision_dir.exists():
                continue
            total_bytes -= size_bytes
            try:
                revision_dir.parent.rmdir()
            except OSError:
                pass

    @staticmethod
    def _mark_used(revision_dir: Path) -> None:
        marker = revision_dir / "installed.json"
        try:
            marker.touch()
        except OSError:
            pass

    @staticmethod
    def _is_valid(path: Path, expected_sha256: str) -> bool:
        return path.is_file() and _sha256(path) == expected_sha256

    @staticmethod
    def _verify(path: Path, expected_sha256: str, artifact_name: str) -> None:
        actual = _sha256(path)
        if actual != expected_sha256:
            raise ModelChecksumError(
                f"Voice model {artifact_name} checksum mismatch"
            )


def _directory_size(path: Path) -> int:
    total = 0
    for item in path.rglob("*"):
        if not item.is_file():
            continue
        try:
            total += item.stat().st_size
        except OSError:
            continue
    return total


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    try:
        with path.open("rb") as file:
            for chunk in iter(lambda: file.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError as exc:
        raise ModelCacheInstallError("Voice model cache file cannot be read") from exc
    return digest.hexdigest()
