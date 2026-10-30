from __future__ import annotations

from pathlib import Path
from typing import Protocol

from voxprep_tts_worker.domain.job import AudioArtifact, ClaimedJob


class BackendPort(Protocol):
    def claim(self, worker_id: str) -> ClaimedJob | None:
        """Claim at most one backend-owned TTS job."""

    def heartbeat(self, *, worker_id: str, job: ClaimedJob) -> None:
        """Extend the current job lease or raise when ownership is lost."""

    def upload_output(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        artifact: AudioArtifact,
    ) -> None:
        """Upload one generated immutable audio asset for the current lease."""

    def fail(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        error_code: str,
        error_message: str,
    ) -> None:
        """Report a classified worker failure while the lease is still owned."""


class ModelSourcePort(Protocol):
    def download_model(self, *, job: ClaimedJob, destination: Path) -> None:
        """Stream the exact claimed ONNX model revision into destination."""

    def download_config(self, *, job: ClaimedJob, destination: Path) -> None:
        """Stream the exact claimed Piper config revision into destination."""


class ModelCachePort(Protocol):
    def ensure_model(self, job: ClaimedJob) -> Path:
        """Return the local directory containing the exact claimed model revision."""
