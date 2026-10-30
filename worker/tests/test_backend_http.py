from __future__ import annotations

import json
from datetime import datetime, timezone

import httpx
import pytest

from voxprep_tts_worker.adapters.backend_http import HttpBackendAdapter
from voxprep_tts_worker.domain.errors import (
    BackendAuthenticationError,
    BackendProtocolError,
    BackendTransportError,
    LeaseLostError,
)
from voxprep_tts_worker.domain.job import ClaimedJob


def _claim_payload() -> dict[str, object]:
    return {
        "jobId": "job-123",
        "fileId": "file-456",
        "contentRevisionId": "revision-789",
        "audioRole": "PRIMARY",
        "normalizedTtsText": "Tell me about yourself.",
        "language": "en-US",
        "voiceModelId": "model-1",
        "voiceModelCode": "en_US-lessac-high-v1",
        "modelSha256": "a" * 64,
        "configSha256": "b" * 64,
        "fingerprint": "c" * 64,
        "leaseToken": "lease-abc",
        "leaseUntil": "2030-01-01T00:00:00Z",
    }


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


def _adapter(handler, *, token: str = "worker-secret") -> HttpBackendAdapter:
    return HttpBackendAdapter(
        base_url="https://backend.example",
        worker_token=token,
        connect_timeout_seconds=5,
        request_timeout_seconds=30,
        transport=httpx.MockTransport(handler),
    )


def test_claim_204_returns_none_and_sends_worker_token() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.method == "POST"
        assert request.url.path == "/internal/v1/tts/jobs/claim"
        assert request.headers["Authorization"] == "Bearer worker-secret"
        assert json.loads(request.content) == {"workerId": "worker-01"}
        return httpx.Response(204)

    adapter = _adapter(handler)
    try:
        assert adapter.claim("worker-01") is None
    finally:
        adapter.close()


def test_claim_200_parses_backend_owned_identity_and_lease() -> None:
    adapter = _adapter(lambda request: httpx.Response(200, json=_claim_payload()))
    try:
        job = adapter.claim("worker-01")
    finally:
        adapter.close()

    assert job is not None
    assert job.job_id == "job-123"
    assert job.file_id == "file-456"
    assert job.lease_token == "lease-abc"
    assert job.model_sha256 == "a" * 64
    assert job.lease_until == datetime(2030, 1, 1, tzinfo=timezone.utc)


def test_claim_malformed_payload_fails_closed() -> None:
    payload = _claim_payload()
    payload["modelSha256"] = "not-a-sha"
    adapter = _adapter(lambda request: httpx.Response(200, json=payload))
    try:
        with pytest.raises(BackendProtocolError, match="modelSha256"):
            adapter.claim("worker-01")
    finally:
        adapter.close()


def test_authentication_failure_never_exposes_worker_token() -> None:
    token = "super-secret-worker-token"
    adapter = _adapter(lambda request: httpx.Response(401), token=token)
    try:
        with pytest.raises(BackendAuthenticationError) as raised:
            adapter.claim("worker-01")
    finally:
        adapter.close()

    assert token not in str(raised.value)


def test_transient_status_is_classified_without_blind_retry() -> None:
    calls = 0

    def handler(request: httpx.Request) -> httpx.Response:
        nonlocal calls
        calls += 1
        return httpx.Response(503)

    adapter = _adapter(handler)
    try:
        with pytest.raises(BackendTransportError, match="503"):
            adapter.claim("worker-01")
    finally:
        adapter.close()

    assert calls == 1


def test_transport_exception_is_classified() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        raise httpx.ConnectTimeout("timeout", request=request)

    adapter = _adapter(handler)
    try:
        with pytest.raises(BackendTransportError, match="Backend request failed"):
            adapter.claim("worker-01")
    finally:
        adapter.close()


def test_heartbeat_sends_current_lease_and_maps_conflict_to_lease_lost() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen.update(json.loads(request.content))
        assert request.url.path == "/internal/v1/tts/jobs/job-123/heartbeat"
        return httpx.Response(409)

    adapter = _adapter(handler)
    try:
        with pytest.raises(LeaseLostError):
            adapter.heartbeat(worker_id="worker-01", job=_job())
    finally:
        adapter.close()

    assert seen == {"workerId": "worker-01", "leaseToken": "lease-abc"}


def test_fail_reports_job_file_lease_and_classified_error() -> None:
    seen: dict[str, object] = {}

    def handler(request: httpx.Request) -> httpx.Response:
        seen.update(json.loads(request.content))
        assert request.url.path == "/internal/v1/tts/jobs/job-123/fail"
        return httpx.Response(204)

    adapter = _adapter(handler)
    try:
        adapter.fail(
            worker_id="worker-01",
            job=_job(),
            error_code="PIPER_SYNTHESIS_FAILED",
            error_message="synthesis failed",
        )
    finally:
        adapter.close()

    assert seen == {
        "workerId": "worker-01",
        "fileId": "file-456",
        "leaseToken": "lease-abc",
        "errorCode": "PIPER_SYNTHESIS_FAILED",
        "errorMessage": "synthesis failed",
    }
