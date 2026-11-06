from __future__ import annotations
import hashlib
import re
import shutil
import tempfile
from pathlib import Path
from voxprep_kokoro_worker.domain.errors import (
    BackendProtocolError, ModelChecksumError, ModelCacheInstallError
)
from voxprep_kokoro_worker.domain.job import ClaimedJob
from voxprep_kokoro_worker.ports.backend import ModelSourcePort

_HEX = re.compile(r"^[0-9a-f]{64}$")
_PATH = re.compile(r"^[A-Za-z0-9_./-]+$")

def canonical_hash(engine: str, revision: str, artifacts: list[dict]) -> str:
    values = ["tts-manifest-v1", engine, revision]
    for a in sorted(artifacts, key=lambda entry: entry["path"]):
        values.extend([a["path"], a["role"], a["sha256"],
                       str(a["sizeBytes"]), a["mediaType"]])
    canonical = "".join(f"{len(v.encode('utf-8'))}:{v}" for v in values)
    return hashlib.sha256(canonical.encode("utf-8")).hexdigest()

def validate_manifest(data: dict, job: ClaimedJob) -> list[dict]:
    if data.get("modelCode") != (job.bundle_model_code or job.voice_model_code):
        raise BackendProtocolError("Wrong bundle model code")
    if not _HEX.fullmatch(str(data.get("manifestSha256", ""))):
        raise BackendProtocolError("Invalid bundle hash")
    if data["manifestSha256"] != job.manifest_sha256:
        raise BackendProtocolError("Claim/bundle revision mismatch")
    entries = data.get("artifacts")
    if not isinstance(entries, list) or not 1 <= len(entries) <= 64:
        raise BackendProtocolError("Invalid artifact set")
    paths = set()
    for a in entries:
        if not isinstance(a, dict):
            raise BackendProtocolError("Invalid artifact entry")
        name = a.get("path")
        if (not isinstance(name, str) or len(name) > 256 or not _PATH.fullmatch(name)
            or name.startswith(".") or name.startswith("/") or "//" in name
            or any(part in (".", "..", "") for part in name.split("/"))):
            raise BackendProtocolError("Unsafe artifact path")
        if name in paths:
            raise BackendProtocolError("Duplicate artifact path")
        paths.add(name)
        if (not _HEX.fullmatch(str(a.get("sha256", "")))
            or type(a.get("sizeBytes")) is not int
            or not 0 < a["sizeBytes"] <= 2 * 1024**3
            or not isinstance(a.get("role"), str)
            or not isinstance(a.get("mediaType"), str)):
            raise BackendProtocolError("Invalid artifact metadata")
        try:
            from uuid import UUID
            UUID(a["assetId"])
        except (KeyError, ValueError, TypeError) as e:
            raise BackendProtocolError("Missing artifact ID") from e
    if canonical_hash("KOKORO", data.get("sourceRevision", ""), entries) != data["manifestSha256"]:
        raise BackendProtocolError("Bundle canonical hash mismatch")
    return entries

def file_hash(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024*1024), b""):
            h.update(chunk)
    return h.hexdigest()

class KokoroModelCache:
    def __init__(self, root: Path, source: ModelSourcePort, max_artifact_bytes: int = 256*1024*1024):
        self.root = root
        self.source = source
        self.max_artifact_bytes = max_artifact_bytes

    def ensure_model(self, job: ClaimedJob) -> Path:
        bundle_code = job.bundle_model_code or job.voice_model_code
        data = self.source.fetch_manifest(bundle_code)
        artifacts = validate_manifest(data, job)
        directory = self.root / job.manifest_sha256
        if directory.is_dir() and all(
            (directory / entry["path"]).is_file()
            and (directory / entry["path"]).stat().st_size == entry["sizeBytes"]
            and file_hash(directory / entry["path"]) == entry["sha256"]
            for entry in artifacts
        ):
            return directory
        self.root.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix=".kokoro-", dir=self.root) as staging:
            work = Path(staging)
            for entry in artifacts:
                target = work / entry["path"]
                self.source.download_artifact(model_code=bundle_code,
                    asset_id=entry["assetId"], destination=target,
                    max_bytes=min(self.max_artifact_bytes, entry["sizeBytes"]))
                if target.stat().st_size != entry["sizeBytes"] or file_hash(target) != entry["sha256"]:
                    raise ModelChecksumError("Kokoro artifact hash/size mismatch")
            if directory.exists():
                shutil.rmtree(directory)
            work.rename(directory)
        return directory
