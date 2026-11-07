import hashlib
from pathlib import Path

import pytest

from voxprep_kokoro_worker.adapters.model_cache import canonical_hash
from voxprep_kokoro_worker.manifest_cli import create_manifest


def files(tmp_path):
    for name in [
        "onnx/model_quantized.onnx",
        "voices/af_heart.bin",
        "voices/am_michael.bin",
        "voices/bf_emma.bin",
    ]:
        file = tmp_path / name
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_bytes(name.encode())


def test_generates_stable_four_artifact_canonical_manifest(tmp_path):
    files(tmp_path)
    one = create_manifest(tmp_path, "kokoro-review-v1", "a" * 40)
    two = create_manifest(tmp_path, "kokoro-review-v1", "a" * 40)
    assert one == two
    assert len(one["artifacts"]) == 4
    assert one["manifestSha256"] == canonical_hash(
        "KOKORO", "a" * 40, one["artifacts"])
    assert one["artifacts"][0]["sha256"] == hashlib.sha256(
        b"onnx/model_quantized.onnx").hexdigest()


def test_rejects_floating_revision_and_missing_assets(tmp_path):
    files(tmp_path)
    with pytest.raises(ValueError, match="pinned"):
        create_manifest(tmp_path, "kokoro-review-v1", "main")
    (tmp_path / "voices/bf_emma.bin").unlink()
    with pytest.raises(ValueError, match="Missing or unsafe"):
        create_manifest(tmp_path, "kokoro-review-v1", "a" * 40)


def test_rejects_symlinked_model_source(tmp_path):
    files(tmp_path)
    file = tmp_path / "voices/af_heart.bin"
    target = tmp_path / "outside.bin"
    target.write_bytes(b"unsafe")
    file.unlink()
    file.symlink_to(target)
    with pytest.raises(ValueError, match="unsafe"):
        create_manifest(tmp_path, "kokoro-review-v1", "a" * 40)
