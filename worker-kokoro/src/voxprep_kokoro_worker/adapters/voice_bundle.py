"""Adapt pinned ONNX-community per-voice float32 style arrays to kokoro-onnx NPZ.

Inputs MUST be downloaded and SHA-256 verified by KokoroModelCache first.
The generated voices.bin is a disposable local derivative, never a new
unreviewed upstream source or a replacement for the manifest's raw hashes.
"""
from __future__ import annotations

import os
from pathlib import Path
from tempfile import NamedTemporaryFile

from voxprep_kokoro_worker.domain.errors import ModelLoadError

SUPPORTED_VOICES = {
    "af_heart": "en-US",
    "am_michael": "en-US",
    "bf_emma": "en-GB",
}
VOICE_STYLE_WIDTH = 256
MAX_VOICE_SIZE = 4 * 1024 * 1024


def ensure_voices_archive(model_dir: Path) -> Path:
    """Build small deterministic-name NPZ of three validated voice files.

    Fails closed on missing voices, inconsistent shape, NaN/Inf or excess size.
    Never reads executable metadata or uses pickle.
    """
    import numpy as np

    archive = model_dir / "voices.bin"
    if archive.is_file():
        # This is a derived artifact, not a trusted source; do not trust an
        # arbitrary pre-existing archive. Recreate from source on each run.
        archive.unlink()
    voices = {}
    for name in SUPPORTED_VOICES:
        path = model_dir / "voices" / f"{name}.bin"
        if not path.is_file() or path.is_symlink():
            raise ModelLoadError(f"Missing validated Kokoro style vectors for {name}")
        size = path.stat().st_size
        if size <= 0 or size > MAX_VOICE_SIZE or size % (4 * VOICE_STYLE_WIDTH):
            raise ModelLoadError(f"Unexpected Kokoro style vector size for {name}")
        array = np.fromfile(path, dtype="<f4")
        if array.size < 256 * VOICE_STYLE_WIDTH or not np.isfinite(array).all():
            raise ModelLoadError(f"Invalid Kokoro style vectors for {name}")
        voices[name] = array.reshape(-1, 1, VOICE_STYLE_WIDTH)
    model_dir.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with NamedTemporaryFile(prefix=".voices-", suffix=".npz", dir=model_dir, delete=False) as out:
            temporary = Path(out.name)
            np.savez(out, **voices)
            out.flush()
            os.fsync(out.fileno())
        os.replace(temporary, archive)
        return archive
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
