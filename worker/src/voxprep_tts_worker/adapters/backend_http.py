from __future__ import annotations

import re
from datetime import datetime
from pathlib import Path
from typing import Any

import httpx

from voxprep_tts_worker.domain.errors import (
    BackendAuthenticationError,
    BackendProtocolError,
    BackendTransportError,
    LeaseLostError,
    ModelDownloadError,
    ModelUnavailableError,
)
from voxprep_tts_worker.domain.job import AudioArtifact, ClaimedJob

_SHA256_RE = re.compile(r"^[0-9a-fA-F]{64}$")


class HttpBackendAdapter:
    """Synchronous Backend adapter for the complete Worker HTTP boundary."""

    def __init__(
        self,
        *,
        base_url: str,
        worker_token: str,
        connect_timeout_seconds: float,
        request_timeout_seconds: float,
        transport: httpx.BaseTransport | None = None,
    ) -> None:
        timeout = httpx.Timeout(
            request_timeout_seconds,
            connect=connect_timeout_seconds,
        )
        self._client = httpx.Client(
            base_url=base_url,
            headers={"Authorization": f"Bearer {worker_token}"},
            timeout=timeout,
            transport=transport,
        )

    def close(self) -> None:
        self._client.close()

    def claim(self, worker_id: str) -> ClaimedJob | None:
        response = self._request(
            "POST",
            "/internal/v1/tts/jobs/claim",
            json={"workerId": worker_id},
        )
        if response.status_code == 204:
            return None
        self._require_success(response, expected={200}, lease_sensitive=False)
        return _parse_claim(response)

    def heartbeat(self, *, worker_id: str, job: ClaimedJob) -> None:
        response = self._request(
            "POST",
            f"/internal/v1/tts/jobs/{job.job_id}/heartbeat",
            json={
                "workerId": worker_id,
                "leaseToken": job.lease_token,
            },
        )
        self._require_success(response, expected={200, 204}, lease_sensitive=True)

    def fail(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        error_code: str,
        error_message: str,
    ) -> None:
        response = self._request(
            "POST",
            f"/internal/v1/tts/jobs/{job.job_id}/fail",
            json={
                "workerId": worker_id,
                "fileId": job.file_id,
                "leaseToken": job.lease_token,
                "errorCode": error_code,
                "errorMessage": error_message,
            },
        )
        self._require_success(response, expected={200, 204}, lease_sensitive=True)

    def upload_output(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        artifact: AudioArtifact,
    ) -> None:
        try:
            with artifact.path.open("rb") as audio_file:
                response = self._client.post(
                    f"/internal/v1/tts/jobs/{job.job_id}/output",
                    data={
                        "workerId": worker_id,
                        "fileId": job.file_id,
                        "leaseToken": job.lease_token,
                        "fingerprint": job.fingerprint,
                        "voiceModelId": job.voice_model_id,
                        "audioProfile": artifact.audio_profile,
                        "sha256": artifact.sha256,
                        "sizeBytes": str(artifact.size_bytes),
                        "durationMs": "" if artifact.duration_ms is None else str(artifact.duration_ms),
                    },
                    files={
                        "file": (
                            artifact.path.name,
                            audio_file,
                            artifact.content_type,
                        )
                    },
                )
        except OSError as exc:
            raise BackendProtocolError("Generated audio artifact cannot be opened") from exc
        except httpx.TransportError as exc:
            raise BackendTransportError(
                "Backend request failed for POST /internal/v1/tts/jobs/{jobId}/output"
            ) from exc

        self._require_success(response, expected={200, 201, 204}, lease_sensitive=True)

    def download_model(self, *, job: ClaimedJob, destination: Path) -> None:
        self._download_to(
            path=f"/internal/v1/tts/models/{job.voice_model_id}/model",
            destination=destination,
        )

    def download_config(self, *, job: ClaimedJob, destination: Path) -> None:
        self._download_to(
            path=f"/internal/v1/tts/models/{job.voice_model_id}/config",
            destination=destination,
        )

    def _download_to(self, *, path: str, destination: Path) -> None:
        destination.parent.mkdir(parents=True, exist_ok=True)
        try:
            with self._client.stream("GET", path) as response:
                if response.status_code == 404:
                    raise ModelUnavailableError("Backend does not expose the claimed voice model")
                self._require_success(response, expected={200}, lease_sensitive=False)
                with destination.open("wb") as output:
                    for chunk in response.iter_bytes():
                        output.write(chunk)
        except ModelUnavailableError:
            raise
        except BackendAuthenticationError:
            raise
        except BackendTransportError:
            raise
        except httpx.TransportError as exc:
            raise ModelDownloadError("Voice model download failed") from exc
        except OSError as exc:
            raise ModelDownloadError("Voice model download cannot be written locally") from exc

    def _request(self, method: str, path: str, **kwargs: Any) -> httpx.Response:
        try:
            return self._client.request(method, path, **kwargs)
        except httpx.TransportError as exc:
            raise BackendTransportError(
                f"Backend request failed for {method} {path}"
            ) from exc

    @staticmethod
    def _require_success(
        response: httpx.Response,
        *,
        expected: set[int],
        lease_sensitive: bool,
    ) -> None:
        if response.status_code in expected:
            return
        if response.status_code in {401, 403}:
            raise BackendAuthenticationError("Backend rejected WORKER_TOKEN")
        if lease_sensitive and response.status_code in {409, 410}:
            raise LeaseLostError("Backend rejected stale job lease")
        if response.status_code == 429 or response.status_code >= 500:
            raise BackendTransportError(
                f"Backend is temporarily unavailable (HTTP {response.status_code})"
            )
        raise BackendProtocolError(
            f"Unexpected Backend response status: HTTP {response.status_code}"
        )


def _parse_claim(response: httpx.Response) -> ClaimedJob:
    try:
        payload = response.json()
    except ValueError as exc:
        raise BackendProtocolError("Claim response is not valid JSON") from exc
    if not isinstance(payload, dict):
        raise BackendProtocolError("Claim response must be a JSON object")

    lease_until_text = _required_text(payload, "leaseUntil")
    try:
        lease_until = datetime.fromisoformat(lease_until_text.replace("Z", "+00:00"))
    except ValueError as exc:
        raise BackendProtocolError("Claim leaseUntil is not valid ISO-8601") from exc
    if lease_until.tzinfo is None or lease_until.utcoffset() is None:
        raise BackendProtocolError("Claim leaseUntil must include a timezone")

    return ClaimedJob(
        job_id=_required_text(payload, "jobId"),
        file_id=_required_text(payload, "fileId"),
        content_revision_id=_required_text(payload, "contentRevisionId"),
        audio_role=_required_text(payload, "audioRole"),
        normalized_tts_text=_required_text(payload, "normalizedTtsText"),
        language=_required_text(payload, "language"),
        voice_model_id=_required_text(payload, "voiceModelId"),
        voice_model_code=_required_text(payload, "voiceModelCode"),
        model_sha256=_required_sha256(payload, "modelSha256"),
        config_sha256=_required_sha256(payload, "configSha256"),
        fingerprint=_required_sha256(payload, "fingerprint"),
        lease_token=_required_text(payload, "leaseToken"),
        lease_until=lease_until,
    )


def _required_text(payload: dict[str, Any], name: str) -> str:
    value = payload.get(name)
    if not isinstance(value, str) or not value.strip():
        raise BackendProtocolError(f"Claim field {name} must be a non-empty string")
    return value


def _required_sha256(payload: dict[str, Any], name: str) -> str:
    value = _required_text(payload, name)
    if _SHA256_RE.fullmatch(value) is None:
        raise BackendProtocolError(f"Claim field {name} must be a SHA-256 hex digest")
    return value.lower()
