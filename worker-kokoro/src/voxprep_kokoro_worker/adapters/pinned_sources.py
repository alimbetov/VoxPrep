"""Pinned model sources for backend-independent Kokoro operation.

The manifest is an operator-reviewed local JSON file. Source providers deliver
only its named artifacts; KokoroModelCache verifies the canonical manifest and
the exact SHA-256 and size of every artifact before inference.
"""
from __future__ import annotations

import re
import shutil
from pathlib import Path
from urllib.parse import quote

import httpx

from voxprep_kokoro_worker.domain.errors import ModelDownloadError

_REVISION = re.compile(r"^[a-fA-F0-9]{40}$")
_REPO = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")


class PinnedModelSource:
    def __init__(
        self,
        *,
        manifest: dict,
        local_dir: Path | None = None,
        hf_repo: str | None = None,
        s3_bucket: str | None = None,
        s3_prefix: str = "",
        s3_endpoint_url: str | None = None,
        s3_region: str | None = None,
    ) -> None:
        if not isinstance(manifest, dict):
            raise ValueError("Model manifest must be a JSON object")
        if not (local_dir or hf_repo or s3_bucket):
            raise ValueError("At least one model source must be configured")
        if hf_repo and (not _REPO.fullmatch(hf_repo) or
                        not _REVISION.fullmatch(str(manifest.get("sourceRevision", "")))):
            raise ValueError("Hugging Face requires a valid repository and pinned 40-hex revision")
        if s3_prefix.startswith("/") or ".." in s3_prefix.split("/"):
            raise ValueError("Invalid object-store prefix")
        if s3_endpoint_url and not (
            s3_endpoint_url.startswith("https://") or
            s3_endpoint_url.startswith("http://127.0.0.1:") or
            s3_endpoint_url.startswith("http://localhost:")
        ):
            raise ValueError("S3 endpoint must use HTTPS (or loopback for development)")
        self.manifest = manifest
        self.local_dir = local_dir
        self.hf_repo = hf_repo
        self.s3_bucket = s3_bucket
        self.s3_prefix = s3_prefix.strip("/")
        self.s3_endpoint_url = s3_endpoint_url
        self.s3_region = s3_region
        self._s3 = None

    def fetch_manifest(self, model_code: str) -> dict:
        if model_code != self.manifest.get("modelCode"):
            raise ModelDownloadError("Unexpected model code")
        return self.manifest

    def download_artifact(
        self, *, model_code: str, asset_id: str, destination: Path, max_bytes: int
    ) -> None:
        if model_code != self.manifest.get("modelCode"):
            raise ModelDownloadError("Model code mismatch")
        matches = [item for item in self.manifest.get("artifacts", [])
                   if item.get("assetId") == asset_id]
        if len(matches) != 1:
            raise ModelDownloadError("Unknown model artifact identity")
        entry = matches[0]
        if entry["sizeBytes"] > max_bytes:
            raise ModelDownloadError("Pinned artifact exceeds configured limit")
        # Artifact path is validated by KokoroModelCache.validate_manifest
        # before this method is called.
        key = entry["path"]
        destination.parent.mkdir(parents=True, exist_ok=True)
        errors: list[str] = []
        if self.local_dir:
            try:
                source = (self.local_dir / key)
                if not source.is_file() or source.is_symlink():
                    raise OSError("Local model file unavailable or symlinked")
                if not source.resolve().is_relative_to(self.local_dir.resolve()):
                    raise OSError("Local model path escapes its root")
                with source.open("rb") as inp, destination.open("wb") as out:
                    self._copy_bounded(inp, out, max_bytes)
                return
            except (OSError, ModelDownloadError) as exc:
                destination.unlink(missing_ok=True)
                errors.append("local: " + type(exc).__name__)
        if self.s3_bucket:
            try:
                # Only the optional standalone S3 mode imports boto3.
                import boto3
                if self._s3 is None:
                    self._s3 = boto3.client(
                        "s3", endpoint_url=self.s3_endpoint_url,
                        region_name=self.s3_region)
                object_key = "/".join(part for part in (self.s3_prefix, key) if part)
                with destination.open("wb") as out:
                    response = self._s3.get_object(Bucket=self.s3_bucket, Key=object_key)
                    try:
                        self._copy_bounded(response["Body"], out, max_bytes)
                    finally:
                        response["Body"].close()
                return
            except Exception as exc:
                destination.unlink(missing_ok=True)
                errors.append("s3: " + type(exc).__name__)
        if self.hf_repo:
            try:
                revision = self.manifest["sourceRevision"]
                url = ("https://huggingface.co/" + self.hf_repo + "/resolve/" +
                       revision + "/" + quote(key, safe="/"))
                with httpx.stream("GET", url, follow_redirects=True, timeout=120) as response:
                    response.raise_for_status()
                    with destination.open("wb") as out:
                        size = 0
                        for chunk in response.iter_bytes(chunk_size=1024 * 1024):
                            size += len(chunk)
                            if size > max_bytes:
                                raise ModelDownloadError("Artifact exceeds configured limit")
                            out.write(chunk)
                return
            except (httpx.HTTPError, OSError, ModelDownloadError) as exc:
                destination.unlink(missing_ok=True)
                errors.append("hf: " + type(exc).__name__)
        raise ModelDownloadError("All pinned model sources unavailable: " + ", ".join(errors))

    @staticmethod
    def _copy_bounded(inp, out, limit: int) -> None:
        copied = 0
        while data := inp.read(1024 * 1024):
            copied += len(data)
            if copied > limit:
                raise ModelDownloadError("Artifact exceeds configured limit")
            out.write(data)
