from __future__ import annotations
import hashlib
from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4
import pytest
from voxprep_kokoro_worker.adapters.model_cache import canonical_hash, validate_manifest, KokoroModelCache
from voxprep_kokoro_worker.domain.errors import BackendProtocolError, ModelChecksumError
from voxprep_kokoro_worker.domain.job import ClaimedJob

def job(manifest_hash: str) -> ClaimedJob:
    return ClaimedJob(
        job_id=str(uuid4()), file_id=str(uuid4()), content_revision_id=str(uuid4()),
        audio_role="pronunciation", normalized_tts_text="Hello", language="en-US",
        voice_model_id=str(uuid4()), voice_model_code="kokoro-example",
        model_sha256="b"*64, config_sha256="c"*64, fingerprint="d"*64,
        lease_token=str(uuid4()), lease_until=datetime.now(timezone.utc),
        engine="KOKORO", manifest_sha256=manifest_hash, voice_code="af_heart")

def manifest(data: bytes = b"verified-onnx", path: str = "onnx/model_quantized.onnx"):
    entry = {"path": path, "role": "MODEL", "sha256": hashlib.sha256(data).hexdigest(),
             "sizeBytes": len(data), "mediaType": "application/octet-stream",
             "assetId": str(uuid4())}
    return {"modelCode": "kokoro-example", "sourceRevision": "a"*40,
            "manifestSha256": canonical_hash("KOKORO", "a"*40, [entry]),
            "artifacts": [entry]}

def test_manifest_rejects_traversal():
    m = manifest(path="../secret")
    with pytest.raises(BackendProtocolError):
        validate_manifest(m, job(m["manifestSha256"]))

def test_manifest_rejects_tampered_sha():
    m = manifest()
    m["artifacts"][0]["sha256"] = "0"*64
    with pytest.raises(BackendProtocolError):
        validate_manifest(m, job(m["manifestSha256"]))

def test_verified_cache_hit_and_corruption_repair(tmp_path):
    payload = b"verified-onnx"
    m = manifest(payload)
    j = job(m["manifestSha256"])
    class Source:
        calls = 0
        def fetch_manifest(self, code):
            return m
        def download_artifact(self, *, model_code, asset_id, destination, max_bytes):
            self.calls += 1
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(payload)
    source = Source()
    cache = KokoroModelCache(tmp_path, source)
    installed = cache.ensure_model(j)
    assert source.calls == 1
    assert cache.ensure_model(j) == installed
    assert source.calls == 1
    (installed / m["artifacts"][0]["path"]).write_bytes(b"corrupt")
    cache.ensure_model(j)
    assert source.calls == 2

def test_wrong_download_hash_not_installed(tmp_path):
    m = manifest()
    class BadSource:
        def fetch_manifest(self, code): return m
        def download_artifact(self, *, destination, **kwargs):
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(b"mismatch")
    with pytest.raises(ModelChecksumError):
        KokoroModelCache(tmp_path, BadSource()).ensure_model(job(m["manifestSha256"]))
    assert not (tmp_path / m["manifestSha256"]).exists()


def test_claim_voice_sha_is_fenced_to_manifest():
    from dataclasses import replace
    voice = b"voice-vectors"
    m = manifest()
    entry = {"path": "voices/af_heart.bin", "role": "VOICE",
             "sha256": hashlib.sha256(voice).hexdigest(),
             "sizeBytes": len(voice), "mediaType": "application/octet-stream",
             "assetId": str(uuid4())}
    m["artifacts"].append(entry)
    m["manifestSha256"] = canonical_hash("KOKORO", m["sourceRevision"], m["artifacts"])
    base = job(m["manifestSha256"])
    assert validate_manifest(m, replace(base, voice_artifact_sha256=entry["sha256"]))
    with pytest.raises(BackendProtocolError, match="voice artifact"):
        validate_manifest(m, replace(base, voice_artifact_sha256="0" * 64))
    with pytest.raises(BackendProtocolError, match="voice artifact"):
        validate_manifest(m, replace(base, voice_code="am_michael", voice_artifact_sha256=entry["sha256"]))


def test_concurrent_cache_install_downloads_only_once(tmp_path):
    from concurrent.futures import ThreadPoolExecutor
    import threading
    import time
    payload = b"verified-onnx"
    m = manifest(payload)
    j = job(m["manifestSha256"])

    class Source:
        calls = 0
        mutex = threading.Lock()

        def fetch_manifest(self, code):
            return m

        def download_artifact(self, *, destination, **kwargs):
            with self.mutex:
                self.calls += 1
            time.sleep(0.025)
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(payload)

    source = Source()
    cache = KokoroModelCache(tmp_path, source)
    with ThreadPoolExecutor(max_workers=8) as pool:
        paths = list(pool.map(cache.ensure_model, [j] * 8))
    assert len(set(paths)) == 1
    assert source.calls == 1


def test_symlinked_cache_directory_is_rejected(tmp_path):
    from voxprep_kokoro_worker.domain.errors import ModelCacheInstallError
    m = manifest()
    target = tmp_path / "other"
    target.mkdir()
    (tmp_path / m["manifestSha256"]).symlink_to(target, target_is_directory=True)

    class Source:
        def fetch_manifest(self, code):
            return m

    with pytest.raises(ModelCacheInstallError, match="Symlinked"):
        KokoroModelCache(tmp_path, Source()).ensure_model(job(m["manifestSha256"]))


def test_cache_repair_waits_while_model_in_use(tmp_path):
    from concurrent.futures import ThreadPoolExecutor
    import threading
    import time

    payload = b"verified-onnx"
    m = manifest(payload)
    j = job(m["manifestSha256"])
    entered = threading.Event()
    release = threading.Event()
    repair_started = threading.Event()

    class Source:
        calls = 0
        def fetch_manifest(self, code):
            return m
        def download_artifact(self, *, destination, **kwargs):
            self.calls += 1
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(payload)

    source = Source()
    cache = KokoroModelCache(tmp_path, source)
    path = cache.ensure_model(j)
    (path / m["artifacts"][0]["path"]).write_bytes(b"corrupt")

    def holder():
        with cache.hold_model(j) as directory:
            entered.set()
            assert (directory / m["artifacts"][0]["path"]).read_bytes() == payload
            assert release.wait(3)

    def second():
        assert entered.wait(3)
        repair_started.set()
        return cache.ensure_model(j)

    with ThreadPoolExecutor(max_workers=2) as pool:
        future_holder = pool.submit(holder)
        future_repair = pool.submit(second)
        assert entered.wait(3)
        assert repair_started.wait(3)
        time.sleep(0.1)
        assert not future_repair.done()
        release.set()
        future_holder.result(timeout=3)
        assert future_repair.result(timeout=3) == path
