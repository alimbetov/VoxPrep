from __future__ import annotations
from datetime import datetime, timezone
from uuid import uuid4
import httpx
import pytest
from voxprep_kokoro_worker.adapters.backend_http import KokoroBackend
from voxprep_kokoro_worker.domain.errors import (
    BackendProtocolError, BackendTransportError, BackendAuthenticationError
)

def test_v2_claim_refuses_backend_disabled_503():
    def handler(req):
        assert req.url.path == "/internal/v2/tts/jobs/claim"
        assert req.headers["authorization"] == "Bearer kokoro-only"
        assert req.read() == b'{"workerId":"test","supportedEngine":"KOKORO"}'
        return httpx.Response(503)
    adapter = KokoroBackend("http://localhost:8080", "kokoro-only", transport=httpx.MockTransport(handler))
    with pytest.raises(BackendTransportError):
        adapter.claim("test")
    adapter.close()

def test_piper_claim_never_treated_as_kokoro():
    def handler(req):
        return httpx.Response(200, json={"engine": "PIPER"})
    adapter = KokoroBackend("http://localhost:8080", "kokoro-only", transport=httpx.MockTransport(handler))
    with pytest.raises(BackendProtocolError):
        adapter.claim("test")
    adapter.close()

def test_v2_wrong_token_fails_closed():
    adapter = KokoroBackend("http://localhost:8080", "wrong", transport=httpx.MockTransport(
        lambda req: httpx.Response(401)))
    with pytest.raises(BackendAuthenticationError):
        adapter.claim("test")
    adapter.close()
