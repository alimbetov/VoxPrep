from __future__ import annotations

import hashlib
import json
import threading
from dataclasses import replace
from pathlib import Path
from uuid import uuid4

import httpx
import pytest

from voxprep_kokoro_worker.adapters.model_cache import canonical_hash
from voxprep_kokoro_worker.adapters.pinned_sources import PinnedModelSource
from voxprep_kokoro_worker.domain.job import AudioArtifact
from voxprep_kokoro_worker.standalone import (
    StandaloneService, StandaloneSettings, make_server,
)


def fixture(tmp_path):
    source_dir = tmp_path / "source"
    entries = []
    for name in (
        "onnx/model_quantized.onnx", "voices/af_heart.bin",
        "voices/am_michael.bin", "voices/bf_emma.bin"
    ):
        value = ("verified:" + name).encode()
        file = source_dir / name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_bytes(value)
        entries.append({
            "assetId": str(uuid4()), "path": name,
            "role": "MODEL" if name.startswith("onnx/") else "VOICE",
            "sha256": hashlib.sha256(value).hexdigest(),
            "sizeBytes": len(value), "mediaType": "application/octet-stream"
        })
    revision = "a" * 40
    manifest = {
        "modelCode": "kokoro-standalone-qa", "sourceRevision": revision,
        "artifacts": entries,
        "manifestSha256": canonical_hash("KOKORO", revision, entries)
    }
    path = tmp_path / "manifest.json"
    path.write_text(json.dumps(manifest), encoding="utf-8")
    settings = StandaloneSettings(
        token="a-test-token-longer-than-24-chars", host="127.0.0.1", port=0,
        manifest_path=path, cache_dir=tmp_path / "cache",
        temp_dir=tmp_path / "temp", output_dir=tmp_path / "out",
        local_model_dir=source_dir, hf_repo=None, model_s3_bucket=None,
        model_s3_prefix="", output_s3_bucket=None, output_s3_prefix="",
        s3_endpoint_url=None, s3_region=None
    )
    return settings, manifest


class FakeSynth:
    def synthesize(self, *, job, model_dir, output_wav, check_lease=None):
        assert (model_dir / "onnx/model_quantized.onnx").is_file()
        assert job.voice_code == "af_heart"
        output_wav.write_bytes(b"dummy-wav")
        return output_wav


class FakePost:
    def postprocess(self, *, job, input_wav, output_mp3):
        assert input_wav.read_bytes() == b"dummy-wav"
        output_mp3.write_bytes(b"safe-mp3-output")
        value = output_mp3.read_bytes()
        return AudioArtifact(output_mp3, "audio/mpeg", "test-profile",
                             hashlib.sha256(value).hexdigest(), len(value), 1234)


def test_bootstrap_from_local_manifest_without_backend(tmp_path):
    settings, manifest = fixture(tmp_path)
    service = StandaloneService(settings, synthesizer=FakeSynth(), postprocessor=FakePost())
    service.startup()
    assert service.ready
    assert (settings.cache_dir / manifest["manifestSha256"] / "voices/bf_emma.bin").is_file()
    # A subsequent process uses the verified on-disk cache even if the
    # source directory disappears.
    for f in settings.local_model_dir.rglob("*.bin"):
        f.unlink()
    (settings.local_model_dir / "onnx/model_quantized.onnx").unlink()
    second = StandaloneService(settings, synthesizer=FakeSynth(), postprocessor=FakePost())
    second.startup()
    assert second.ready


def test_standalone_api_auth_output_recovery_and_corruption_rejection(tmp_path):
    settings, _ = fixture(tmp_path)
    service = StandaloneService(settings, synthesizer=FakeSynth(), postprocessor=FakePost())
    service.startup()
    server = make_server(settings, service)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        url = "http://127.0.0.1:" + str(server.server_address[1])
        with httpx.Client(base_url=url, timeout=10) as client:
            assert client.get("/health/live").status_code == 200
            assert client.get("/health/ready").status_code == 401
            headers = {"Authorization": "Bearer " + settings.token}
            assert client.get("/health/ready", headers=headers).json()["status"] == "READY"
            body = {"text": "Hello everyone.", "voiceCode": "af_heart", "speed": 1.0}
            assert client.post("/v1/tts/jobs", json=body).status_code == 401
            assert client.post("/v1/tts/jobs", headers=headers, json=body | {"unexpected": 1}).status_code == 400
            invalid = body | {"voiceCode": "af_unknown"}
            assert client.post("/v1/tts/jobs", headers=headers, json=invalid).status_code == 400
            assert client.post("/v1/tts/jobs", headers=headers, json=body | {"speed": float("nan")}).status_code == 400
            with service.busy:
                pass
            response = client.post("/v1/tts/jobs", headers=headers, json=body)
            assert response.status_code == 201
            info = response.json()
            assert info["sha256"] == hashlib.sha256(b"safe-mp3-output").hexdigest()
            assert client.get(info["downloadPath"], headers=headers).content == b"safe-mp3-output"
            # Metadata survives an HTTP process restart.
            restarted = StandaloneService(settings, synthesizer=FakeSynth(), postprocessor=FakePost())
            assert restarted.find(info["id"]) == info
            (settings.output_dir / (info["id"] + ".mp3")).write_bytes(b"tampered-output")
            assert service.find(info["id"]) is None
            assert client.get(info["downloadPath"], headers=headers).status_code == 404
    finally:
        server.shutdown()
        server.server_close()
        thread.join(timeout=5)


def test_standalone_enforces_single_inference_slot(tmp_path):
    settings, _ = fixture(tmp_path)
    service = StandaloneService(settings, synthesizer=FakeSynth(), postprocessor=FakePost())
    service.startup()
    assert service.busy.acquire(blocking=False)
    try:
        with pytest.raises(RuntimeError, match="Worker busy"):
            service.synthesize({"text": "Hello", "voiceCode": "af_heart", "speed": 1})
    finally:
        service.busy.release()


def test_rejects_unpinned_hf_revision(tmp_path):
    settings, manifest = fixture(tmp_path)
    manifest["sourceRevision"] = "main"
    with pytest.raises(ValueError, match="pinned"):
        PinnedModelSource(manifest=manifest, hf_repo="org/model")


def test_s3_model_provider_and_output_adapter_use_pinned_keys(tmp_path, monkeypatch):
    import sys
    from types import SimpleNamespace
    settings, manifest = fixture(tmp_path)
    calls = []
    objects = {
        "verified/" + entry["path"]:
            (settings.local_model_dir / entry["path"]).read_bytes()
        for entry in manifest["artifacts"]
    }

    class Body:
        def __init__(self, value):
            from io import BytesIO
            self.stream = BytesIO(value)
        def read(self, n): return self.stream.read(n)
        def close(self): self.stream.close()

    class S3:
        def get_object(self, *, Bucket, Key):
            calls.append(("get", Bucket, Key))
            return {"Body": Body(objects[Key])}
        def upload_fileobj(self, stream, bucket, key, ExtraArgs):
            calls.append(("put", bucket, key, ExtraArgs["Metadata"]["sha256"]))
            assert stream.read() == b"safe-mp3-output"

    monkeypatch.setitem(sys.modules, "boto3", SimpleNamespace(client=lambda *a, **kw: S3()))
    s3_settings = replace(
        settings, local_model_dir=None, model_s3_bucket="private-models",
        model_s3_prefix="verified", output_s3_bucket="audio",
        output_s3_prefix="generated")
    service = StandaloneService(
        s3_settings, synthesizer=FakeSynth(), postprocessor=FakePost())
    service.startup()
    info = service.synthesize({"text": "Hi", "voiceCode": "af_heart", "speed": 1})
    assert info["s3Key"] == "generated/" + info["id"] + ".mp3"
    assert len([c for c in calls if c[0] == "get"]) == 4
    assert len([c for c in calls if c[0] == "put"]) == 1


def test_config_requires_secret_and_explicit_remote_bind(tmp_path):
    from voxprep_kokoro_worker.standalone import StandaloneSettings
    from voxprep_kokoro_worker.standalone import StandaloneService
    env = {
        "STANDALONE_API_TOKEN": "valid-secret-more-than-24-characters",
        "STANDALONE_MANIFEST_PATH": str(tmp_path / "bundle.json"),
        "MODEL_CACHE_DIR": str(tmp_path / "cache"),
        "TEMP_DIR": str(tmp_path / "temp"),
        "STANDALONE_OUTPUT_DIR": str(tmp_path / "output"),
        "STANDALONE_MODEL_DIR": str(tmp_path / "model"),
        "STANDALONE_HOST": "0.0.0.0",
    }
    with pytest.raises(ValueError, match="Non-loopback"):
        StandaloneSettings.from_env(env)
    env["STANDALONE_HOST"] = "127.0.0.1"
    assert StandaloneSettings.from_env(env).host == "127.0.0.1"
