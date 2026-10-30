from __future__ import annotations

import json
import shutil
import subprocess
import wave
from datetime import datetime, timezone
from pathlib import Path
from types import SimpleNamespace

import pytest

from voxprep_tts_worker.adapters import audio
from voxprep_tts_worker.adapters.audio import FfmpegPostprocessor, PiperSynthesizer
from voxprep_tts_worker.domain.errors import (
    AudioQcError,
    ModelLoadError,
    PostprocessError,
    SynthesisError,
)
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


class EmptyVoice:
    def synthesize_wav(self, text: str, wav_file: wave.Wave_write) -> None:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(22050)


class FailingVoice:
    def synthesize_wav(self, text: str, wav_file: wave.Wave_write) -> None:
        raise RuntimeError("boom")


def _installed_model(tmp_path: Path, name: str = "model") -> Path:
    model_dir = tmp_path / name
    model_dir.mkdir()
    (model_dir / "model.onnx").write_bytes(f"fake-{name}".encode())
    (model_dir / "model.onnx.json").write_text("{}", encoding="utf-8")
    return model_dir


def test_piper_synthesizer_loads_exact_cached_model(monkeypatch, tmp_path: Path) -> None:
    model_dir = _installed_model(tmp_path)
    model_path = model_dir / "model.onnx"
    config_path = model_dir / "model.onnx.json"
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


def test_piper_voice_cache_reuses_and_evicts_lru(monkeypatch, tmp_path: Path) -> None:
    model_dirs = {
        name: _installed_model(tmp_path, name)
        for name in ("model-a", "model-b", "model-c")
    }
    load_calls: list[str] = []

    def fake_load(model: Path, *, config_path: Path):
        del config_path
        load_calls.append(Path(model).parent.name)
        return FakeVoice()

    monkeypatch.setattr(audio.PiperVoice, "load", fake_load)
    synthesizer = PiperSynthesizer(max_loaded_models=2)

    for index, name in enumerate(("model-a", "model-b", "model-a", "model-c", "model-b")):
        synthesizer.synthesize(
            job=_job(),
            model_dir=model_dirs[name],
            output_wav=tmp_path / f"voice-{index}.wav",
        )

    assert load_calls == ["model-a", "model-b", "model-c", "model-b"]
    assert len(synthesizer._voices) == 2


def test_piper_rejects_invalid_loaded_model_limit() -> None:
    with pytest.raises(ValueError, match="must be > 0"):
        PiperSynthesizer(max_loaded_models=0)


@pytest.mark.parametrize("missing_name", ["model.onnx", "model.onnx.json"])
def test_piper_rejects_incomplete_model_installation(tmp_path: Path, missing_name: str) -> None:
    model_dir = _installed_model(tmp_path)
    (model_dir / missing_name).unlink()

    with pytest.raises(ModelLoadError, match="incomplete"):
        PiperSynthesizer().synthesize(
            job=_job(),
            model_dir=model_dir,
            output_wav=tmp_path / "voice.wav",
        )


def test_piper_model_load_failure_is_classified(monkeypatch, tmp_path: Path) -> None:
    model_dir = _installed_model(tmp_path)

    def fail_load(*args, **kwargs):
        raise RuntimeError("invalid ONNX")

    monkeypatch.setattr(audio.PiperVoice, "load", fail_load)

    with pytest.raises(ModelLoadError, match="could not be loaded"):
        PiperSynthesizer().synthesize(
            job=_job(), model_dir=model_dir, output_wav=tmp_path / "voice.wav"
        )


def test_piper_synthesis_failure_is_classified(monkeypatch, tmp_path: Path) -> None:
    model_dir = _installed_model(tmp_path)
    monkeypatch.setattr(audio.PiperVoice, "load", lambda *args, **kwargs: FailingVoice())

    with pytest.raises(SynthesisError, match="Piper synthesis failed"):
        PiperSynthesizer().synthesize(
            job=_job(), model_dir=model_dir, output_wav=tmp_path / "voice.wav"
        )


def test_piper_empty_wav_is_rejected(monkeypatch, tmp_path: Path) -> None:
    model_dir = _installed_model(tmp_path)
    monkeypatch.setattr(audio.PiperVoice, "load", lambda *args, **kwargs: EmptyVoice())

    with pytest.raises(SynthesisError, match="empty WAV"):
        PiperSynthesizer().synthesize(
            job=_job(), model_dir=model_dir, output_wav=tmp_path / "voice.wav"
        )


def test_ffmpeg_rejects_missing_input_wav(tmp_path: Path) -> None:
    with pytest.raises(PostprocessError, match="missing or empty"):
        FfmpegPostprocessor().postprocess(
            job=_job(),
            input_wav=tmp_path / "missing.wav",
            output_mp3=tmp_path / "output.mp3",
        )


def test_ffmpeg_nonzero_exit_is_classified(monkeypatch, tmp_path: Path) -> None:
    wav_path = tmp_path / "input.wav"
    wav_path.write_bytes(b"RIFF-data")
    monkeypatch.setattr(
        audio.subprocess,
        "run",
        lambda *args, **kwargs: SimpleNamespace(returncode=1, stdout="", stderr="bad input"),
    )

    with pytest.raises(PostprocessError, match="conversion failed"):
        FfmpegPostprocessor().postprocess(
            job=_job(), input_wav=wav_path, output_mp3=tmp_path / "output.mp3"
        )


def test_ffmpeg_start_failure_is_classified(monkeypatch, tmp_path: Path) -> None:
    wav_path = tmp_path / "input.wav"
    wav_path.write_bytes(b"RIFF-data")

    def fail_start(*args, **kwargs):
        raise OSError("ffmpeg missing")

    monkeypatch.setattr(audio.subprocess, "run", fail_start)

    with pytest.raises(PostprocessError, match="could not be started"):
        FfmpegPostprocessor().postprocess(
            job=_job(), input_wav=wav_path, output_mp3=tmp_path / "output.mp3"
        )


def test_ffprobe_invalid_metadata_is_rejected(monkeypatch, tmp_path: Path) -> None:
    mp3 = tmp_path / "output.mp3"
    mp3.write_bytes(b"mp3")
    monkeypatch.setattr(
        audio.subprocess,
        "run",
        lambda *args, **kwargs: SimpleNamespace(
            returncode=0,
            stdout=json.dumps({"streams": [], "format": {"duration": "1.0"}}),
            stderr="",
        ),
    )

    with pytest.raises(AudioQcError, match="metadata is invalid"):
        FfmpegPostprocessor()._inspect(mp3)


@pytest.mark.parametrize(
    ("codec", "sample_rate", "channels", "bit_rate", "duration", "message"),
    [
        ("aac", "24000", 1, "64000", "1.0", "codec is not MP3"),
        ("mp3", "48000", 1, "64000", "1.0", "sample rate is not 24 kHz"),
        ("mp3", "24000", 2, "64000", "1.0", "not mono"),
        ("mp3", "24000", 1, "96000", "1.0", "outside the 64 kbps profile"),
        ("mp3", "24000", 1, "64000", "0", "duration is not positive"),
    ],
)
def test_ffprobe_profile_mismatch_is_rejected(
    monkeypatch,
    tmp_path: Path,
    codec: str,
    sample_rate: str,
    channels: int,
    bit_rate: str,
    duration: str,
    message: str,
) -> None:
    mp3 = tmp_path / "output.mp3"
    mp3.write_bytes(b"mp3")
    payload = {
        "streams": [
            {
                "codec_name": codec,
                "sample_rate": sample_rate,
                "channels": channels,
                "bit_rate": bit_rate,
            }
        ],
        "format": {"duration": duration},
    }
    monkeypatch.setattr(
        audio.subprocess,
        "run",
        lambda *args, **kwargs: SimpleNamespace(
            returncode=0, stdout=json.dumps(payload), stderr=""
        ),
    )

    with pytest.raises(AudioQcError, match=message):
        FfmpegPostprocessor()._inspect(mp3)


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
