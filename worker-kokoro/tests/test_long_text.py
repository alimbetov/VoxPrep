from __future__ import annotations

import sys
import types
import wave
from dataclasses import replace
from datetime import datetime, timezone
from uuid import uuid4

import numpy as np
import pytest

from voxprep_kokoro_worker.adapters.text_chunks import split_text
from voxprep_kokoro_worker.adapters.audio import KokoroSynthesizer
from voxprep_kokoro_worker.domain.errors import SynthesisError
from voxprep_kokoro_worker.domain.job import ClaimedJob


def make_job(text):
    return ClaimedJob(
        job_id=str(uuid4()), file_id=str(uuid4()), content_revision_id=str(uuid4()),
        audio_role="lesson", normalized_tts_text=text, language="en-US",
        voice_model_id=str(uuid4()), voice_model_code="kokoro-test",
        model_sha256="", config_sha256="", fingerprint="a"*64,
        lease_token=str(uuid4()), lease_until=datetime.now(timezone.utc),
        engine="KOKORO", manifest_sha256="b"*64, voice_code="af_heart"
    )


def test_long_text_chunks_preserve_words_in_order():
    text = "The first sentence ends here. Another sentence follows! " * 100
    chunks = split_text(text)
    assert len(chunks) > 1
    assert all(0 < len(c) <= 400 for c in chunks)
    assert " ".join(chunks) == " ".join(text.split())


def test_chunking_prefers_sentence_boundary():
    text = "One sentence. " + "next " * 10 + "End."
    chunks = split_text(text, limit=35)
    assert chunks[0] == "One sentence."
    assert " ".join(chunks) == " ".join(text.split())


@pytest.mark.parametrize("text", ["", " ", "x" * 12001, "x" * 401])
def test_bounded_text_rejects_bad_input(text):
    with pytest.raises(SynthesisError):
        split_text(text)


def test_long_text_generates_single_wav_without_full_pcm_concatenation(tmp_path, monkeypatch):
    model = tmp_path / "onnx" / "model_quantized.onnx"
    model.parent.mkdir(parents=True)
    model.write_bytes(b"fake")
    monkeypatch.setattr(
        "voxprep_kokoro_worker.adapters.audio.ensure_voices_archive",
        lambda root: root / "voices.bin",
    )
    calls = []
    class FakeKokoro:
        def __init__(self, *args):
            pass
        def create(self, text, **kwargs):
            calls.append(text)
            return np.full(2400, 0.1, dtype=np.float32), 24000
    monkeypatch.setitem(sys.modules, "kokoro_onnx", types.SimpleNamespace(Kokoro=FakeKokoro))
    job = make_job("A valid Kokoro sentence. " * 40)
    target = tmp_path / "out.wav"
    assert KokoroSynthesizer().synthesize(job=job, model_dir=tmp_path, output_wav=target) == target
    assert len(calls) > 1
    with wave.open(str(target), "rb") as wav:
        assert wav.getnchannels() == 1
        assert wav.getframerate() == 24000
        assert wav.getnframes() == len(calls) * 2400


def test_inconsistent_sample_rate_fails_closed(tmp_path, monkeypatch):
    model = tmp_path / "onnx" / "model_quantized.onnx"
    model.parent.mkdir(parents=True)
    model.write_bytes(b"fake")
    monkeypatch.setattr(
        "voxprep_kokoro_worker.adapters.audio.ensure_voices_archive",
        lambda root: root / "voices.bin",
    )
    class FakeKokoro:
        def __init__(self, *args):
            self.count = 0
        def create(self, text, **kwargs):
            self.count += 1
            return np.ones(2400, dtype=np.float32), 24000 if self.count == 1 else 22050
    monkeypatch.setitem(sys.modules, "kokoro_onnx", types.SimpleNamespace(Kokoro=FakeKokoro))
    with pytest.raises(SynthesisError, match="sample rates"):
        KokoroSynthesizer().synthesize(
            job=make_job("A long sentence. " * 50),
            model_dir=tmp_path, output_wav=tmp_path / "out.wav"
        )
