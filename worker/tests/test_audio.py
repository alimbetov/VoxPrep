from __future__ import annotations

import shutil
import wave
from datetime import datetime, timezone
from pathlib import Path

import pytest

from voxprep_tts_worker.adapters import audio
from voxprep_tts_worker.adapters.audio import FfmpegPostprocessor, PiperSynthesizer
from voxprep_tts_worker.domain.job import ClaimedJob


def _job() -> ClaimedJob:
    return ClaimedJob(
        job_id="job-1",
        file_id="file-1",
        content_revision_id="revision-1",
        audio_role="PRIMARY",
        normalized_tts_text="Hello from VoxPrep",
        language="en-US",
        voice_model_id="model-1",
        voice_model_code="voice-1",
        model_sha256="a" * 64,
        config_sha256="b" * 64,
        fingerprint="c" * 64,
        lease_token="lease-1",
        lease_until=datetime(2030, 1, 1, tzinfo=timezone.utc),
    )


class FakeVoice:
    def synthesize_wav(self, text: str, wav_file: wave.Wave_write) -> None:
        assert text == "Hello from VoxPrep"
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(22050)
        wav_file.writeframes(b"\x00\x00" * 2205)


def test_piper_synthesizer_loads_exact_cached_model(monkeypatch, tmp_path: Path) -> None:
    model_dir = tmp_path / "model"
    model_dir.mkdir()
    model_path = model_dir / "model.onnx"
    config_path = model_dir / "model.onnx.json"
    model_path.write_bytes(b"fake-model")
    config_path.write_text("{}", encoding="utf-8")
    seen: dict[str, Path] = {}

    def fake_load(model: Path, *, config_path: Path):
        seen["model"] = Path(model)
        seen["config"] = Path(config_path)
        return FakeVoice()

    monkeypatch.setattr(audio.PiperVoice, "load", fake_load)

    output = PiperSynthesizer().synthesize(
        job=_job(),
        model_dir=model_dir,
        output_wav=tmp_path / "voice.wav",
    )

    assert output.is_file()
    assert output.stat().st_size > 44
    assert seen == {"model": model_path, "config": config_path}


@pytest.mark.skipif(
    shutil.which("ffmpeg") is None or shutil.which("ffprobe") is None,
    reason="FFmpeg is unavailable on this test host",
)
def test_ffmpeg_postprocessor_produces_qualified_mp3(tmp_path: Path) -> None:
    wav_path = tmp_path / "input.wav"
    with wave.open(str(wav_path), "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(22050)
        wav_file.writeframes(b"\x00\x00" * 2205)

    artifact = FfmpegPostprocessor().postprocess(
        job=_job(),
        input_wav=wav_path,
        output_mp3=tmp_path / "output.mp3",
    )

    assert artifact.path.is_file()
    assert artifact.content_type == "audio/mpeg"
    assert artifact.audio_profile == "mp3-mono-24k-64k-v1"
    assert artifact.size_bytes > 0
    assert artifact.duration_ms is not None and artifact.duration_ms > 0
    assert len(artifact.sha256) == 64
