from __future__ import annotations
import numpy as np
import pytest

from voxprep_kokoro_worker.adapters.voice_bundle import (
    SUPPORTED_VOICES,
    ensure_voices_archive,
)
from voxprep_kokoro_worker.domain.errors import ModelLoadError


def write_styles(root, *, rows=510):
    voices = root / "voices"
    voices.mkdir(parents=True, exist_ok=True)
    for idx, name in enumerate(SUPPORTED_VOICES):
        values = np.full((rows, 1, 256), (idx + 1) / 10, dtype="<f4")
        (voices / (name + ".bin")).write_bytes(values.tobytes())


def test_three_educational_voices_are_packed_as_named_npz(tmp_path):
    write_styles(tmp_path)
    archive = ensure_voices_archive(tmp_path)
    assert archive.name == "voices.bin"
    with np.load(archive, allow_pickle=False) as saved:
        assert set(saved.files) == {"af_heart", "am_michael", "bf_emma"}
        for name in saved.files:
            assert saved[name].shape == (510, 1, 256)
            assert np.isfinite(saved[name]).all()


def test_corrupt_style_vector_is_rejected(tmp_path):
    write_styles(tmp_path)
    (tmp_path / "voices" / "am_michael.bin").write_bytes(b"bad-size")
    with pytest.raises(ModelLoadError):
        ensure_voices_archive(tmp_path)
    assert not (tmp_path / "voices.bin").exists()


def test_nan_style_vector_is_rejected(tmp_path):
    write_styles(tmp_path)
    path = tmp_path / "voices" / "bf_emma.bin"
    bad = np.fromfile(path, dtype="<f4")
    bad[0] = np.nan
    path.write_bytes(bad.tobytes())
    with pytest.raises(ModelLoadError):
        ensure_voices_archive(tmp_path)


def test_missing_british_voice_fails_closed(tmp_path):
    write_styles(tmp_path)
    (tmp_path / "voices" / "bf_emma.bin").unlink()
    with pytest.raises(ModelLoadError):
        ensure_voices_archive(tmp_path)


def test_archive_rebuilt_from_verified_source_not_trusted_old_cache(tmp_path):
    write_styles(tmp_path)
    first = ensure_voices_archive(tmp_path)
    first.write_bytes(b"corrupted derived artifact")
    second = ensure_voices_archive(tmp_path)
    with np.load(second, allow_pickle=False) as saved:
        assert set(saved.files) == set(SUPPORTED_VOICES)
