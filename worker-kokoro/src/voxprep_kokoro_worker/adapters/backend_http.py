from __future__ import annotations
import re
from datetime import datetime
from pathlib import Path
from uuid import UUID
import httpx
from voxprep_kokoro_worker.domain.job import ClaimedJob, AudioArtifact
from voxprep_kokoro_worker.domain.errors import (
    BackendAuthenticationError, BackendTransportError, BackendProtocolError,
    LeaseLostError, ModelDownloadError
)

_HEX = re.compile(r"^[0-9a-f]{64}$")

class KokoroBackend:
    """Only V2 endpoints. Never use Piper V1 as implicit fallback."""
    def __init__(self, base_url: str, token: str, timeout_seconds: float = 30,
                 transport: httpx.BaseTransport | None = None):
        self._client = httpx.Client(base_url=base_url,
            headers={"Authorization": "Bearer " + token}, timeout=timeout_seconds,
            transport=transport)
    def close(self) -> None:
        self._client.close()

    @staticmethod
    def _require(response: httpx.Response, allowed: set[int], lease: bool = False) -> None:
        if response.status_code in allowed:
            return
        if response.status_code in (401, 403):
            raise BackendAuthenticationError("Backend rejected Kokoro identity")
        if lease and response.status_code in (409, 410):
            raise LeaseLostError("Stale Kokoro lease")
        if response.status_code >= 500 or response.status_code == 429:
            raise BackendTransportError("Backend V2 unavailable: " + str(response.status_code))
        raise BackendProtocolError("Unexpected HTTP status " + str(response.status_code))

    def claim(self, worker_id: str) -> ClaimedJob | None:
        try:
            r = self._client.post("/internal/v2/tts/jobs/claim",
                json={"workerId": worker_id, "supportedEngine": "KOKORO"})
        except httpx.TransportError as e:
            raise BackendTransportError("V2 claim transport error") from e
        if r.status_code == 204:
            return None
        self._require(r, {200})
        try:
            data = r.json()
            if not isinstance(data, dict) or data.get("engine") != "KOKORO":
                raise BackendProtocolError("Claim is not Kokoro")
            for key in ("manifestSha256", "fingerprint", "modelSha256", "configSha256"):
                if not _HEX.fullmatch(str(data.get(key, ""))):
                    raise BackendProtocolError("Missing/invalid V2 " + key)
            for key in ("jobId", "fileId", "contentRevisionId", "voiceModelId", "leaseToken"):
                UUID(data[key])
            until = datetime.fromisoformat(data["leaseUntil"].replace("Z", "+00:00"))
            if until.tzinfo is None or until.utcoffset() is None:
                raise BackendProtocolError("Missing lease timezone")
            return ClaimedJob(
                job_id=data["jobId"], file_id=data["fileId"],
                content_revision_id=data["contentRevisionId"],
                audio_role=data["audioRole"], normalized_tts_text=data["normalizedTtsText"],
                language=data["language"], voice_model_id=data["voiceModelId"],
                voice_model_code=data["voiceModelCode"], model_sha256=data["modelSha256"],
                config_sha256=data["configSha256"], fingerprint=data["fingerprint"],
                lease_token=data["leaseToken"], lease_until=until,
                engine="KOKORO", manifest_sha256=data["manifestSha256"],
                voice_code=data["voiceCode"], speed=float(data.get("speed", 1)))
        except BackendProtocolError:
            raise
        except (KeyError, TypeError, ValueError, OverflowError) as exc:
            raise BackendProtocolError("Malformed V2 Kokoro claim") from exc

    def heartbeat(self, *, worker_id: str, job: ClaimedJob) -> None:
        try:
            r = self._client.post(f"/internal/v2/tts/jobs/{job.job_id}/heartbeat",
                json={"workerId": worker_id, "leaseToken": job.lease_token})
        except httpx.TransportError as e:
            raise BackendTransportError("V2 heartbeat transport error") from e
        self._require(r, {200, 204}, lease=True)

    def fail(self, *, worker_id: str, job: ClaimedJob,
             error_code: str, error_message: str) -> None:
        try:
            r = self._client.post(f"/internal/v2/tts/jobs/{job.job_id}/fail",
                json={"workerId": worker_id, "fileId": job.file_id,
                    "leaseToken": job.lease_token, "errorCode": error_code,
                    "errorMessage": error_message[:1000]})
        except httpx.TransportError as e:
            raise BackendTransportError("V2 fail transport error") from e
        self._require(r, {200, 204}, lease=True)

    def upload_output(self, *, worker_id: str, job: ClaimedJob,
                      artifact: AudioArtifact) -> None:
        try:
            with artifact.path.open("rb") as stream:
                r = self._client.post(f"/internal/v2/tts/jobs/{job.job_id}/output",
                    data={"workerId": worker_id, "fileId": job.file_id,
                          "leaseToken": job.lease_token, "fingerprint": job.fingerprint,
                          "voiceModelId": job.voice_model_id,
                          "manifestSha256": job.manifest_sha256,
                          "audioProfile": artifact.audio_profile, "sha256": artifact.sha256,
                          "sizeBytes": str(artifact.size_bytes),
                          "durationMs": str(artifact.duration_ms or 0)},
                    files={"file": ("output.mp3", stream, "audio/mpeg")})
        except (OSError, httpx.TransportError) as e:
            raise BackendTransportError("V2 output upload failed") from e
        self._require(r, {200, 201, 204}, lease=True)

    def fetch_manifest(self, model_code: str) -> dict:
        try:
            r = self._client.get("/internal/v2/tts/bundles/" + model_code)
        except httpx.TransportError as e:
            raise BackendTransportError("Manifest fetch failed") from e
        self._require(r, {200})
        try:
            data = r.json()
        except ValueError as e:
            raise BackendProtocolError("Invalid manifest JSON") from e
        if not isinstance(data, dict):
            raise BackendProtocolError("Invalid manifest payload")
        return data

    def download_artifact(self, *, model_code: str, asset_id: str,
                          destination: Path, max_bytes: int) -> None:
        UUID(asset_id)
        destination.parent.mkdir(parents=True, exist_ok=True)
        try:
            with self._client.stream("GET",
                f"/internal/v2/tts/bundles/{model_code}/artifacts/{asset_id}") as r:
                self._require(r, {200})
                total = 0
                with destination.open("wb") as output:
                    for chunk in r.iter_bytes(chunk_size=1024*1024):
                        total += len(chunk)
                        if total > max_bytes:
                            raise ModelDownloadError("Artifact exceeds configured maximum")
                        output.write(chunk)
        except httpx.TransportError as e:
            raise ModelDownloadError("V2 artifact download failed") from e
