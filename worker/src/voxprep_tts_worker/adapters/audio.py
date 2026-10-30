from __future__ import annotations

import hashlib
import json
import subprocess
import wave
from pathlib import Path

from piper import PiperVoice

from voxprep_tts_worker.domain.errors import (
    AudioQcError,
    ModelLoadError,
    PostprocessError,
    SynthesisError,
)
from voxprep_tts_worker.domain.job import AudioArtifact, ClaimedJob

_AUDIO_PROFILE = "mp3-mono-24k-64k-v1"


class PiperSynthesizer:
    def synthesize(
        self,
        *,
        job: ClaimedJob,
        model_dir: Path,
        output_wav: Path,
    ) -> Path:
        model_path = model_dir / "model.onnx"
        config_path = model_dir / "model.onnx.json"
        if not model_path.is_file() or not config_path.is_file():
            raise ModelLoadError("Installed Piper model is incomplete")

        try:
            voice = PiperVoice.load(model_path, config_path=config_path)
        except Exception as exc:
            raise ModelLoadError("Piper voice model could not be loaded") from exc

        try:
            output_wav.parent.mkdir(parents=True, exist_ok=True)
            with wave.open(str(output_wav), "wb") as wav_file:
                voice.synthesize_wav(job.normalized_tts_text, wav_file)
        except Exception as exc:
            raise SynthesisError("Piper synthesis failed") from exc

        if not output_wav.is_file() or output_wav.stat().st_size <= 44:
            raise SynthesisError("Piper produced an empty WAV artifact")
        return output_wav


class FfmpegPostprocessor:
    def __init__(self, *, ffmpeg_bin: str = "ffmpeg", ffprobe_bin: str = "ffprobe") -> None:
        self._ffmpeg_bin = ffmpeg_bin
        self._ffprobe_bin = ffprobe_bin

    def postprocess(
        self,
        *,
        job: ClaimedJob,
        input_wav: Path,
        output_mp3: Path,
    ) -> AudioArtifact:
        del job
        if not input_wav.is_file() or input_wav.stat().st_size == 0:
            raise PostprocessError("Input WAV is missing or empty")

        output_mp3.parent.mkdir(parents=True, exist_ok=True)
        command = [
            self._ffmpeg_bin,
            "-y",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(input_wav),
            "-vn",
            "-ac",
            "1",
            "-ar",
            "24000",
            "-codec:a",
            "libmp3lame",
            "-b:a",
            "64k",
            str(output_mp3),
        ]
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError as exc:
            raise PostprocessError("FFmpeg could not be started") from exc

        if result.returncode != 0:
            raise PostprocessError("FFmpeg conversion failed")

        return self._inspect(output_mp3)

    def _inspect(self, output_mp3: Path) -> AudioArtifact:
        if not output_mp3.is_file() or output_mp3.stat().st_size == 0:
            raise AudioQcError("Generated MP3 is missing or empty")

        command = [
            self._ffprobe_bin,
            "-v",
            "error",
            "-select_streams",
            "a:0",
            "-show_entries",
            "stream=codec_name,sample_rate,channels:format=duration",
            "-of",
            "json",
            str(output_mp3),
        ]
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=False,
            )
        except OSError as exc:
            raise AudioQcError("ffprobe could not be started") from exc

        if result.returncode != 0:
            raise AudioQcError("ffprobe rejected generated MP3")

        try:
            payload = json.loads(result.stdout)
            stream = payload["streams"][0]
            duration_seconds = float(payload["format"]["duration"])
            codec_name = stream["codec_name"]
            sample_rate = int(stream["sample_rate"])
            channels = int(stream["channels"])
        except (KeyError, IndexError, TypeError, ValueError, json.JSONDecodeError) as exc:
            raise AudioQcError("Generated MP3 metadata is invalid") from exc

        if codec_name != "mp3":
            raise AudioQcError("Generated audio codec is not MP3")
        if sample_rate != 24000:
            raise AudioQcError("Generated MP3 sample rate is not 24 kHz")
        if channels != 1:
            raise AudioQcError("Generated MP3 is not mono")
        if duration_seconds <= 0:
            raise AudioQcError("Generated MP3 duration is not positive")

        return AudioArtifact(
            path=output_mp3,
            content_type="audio/mpeg",
            audio_profile=_AUDIO_PROFILE,
            sha256=_sha256(output_mp3),
            size_bytes=output_mp3.stat().st_size,
            duration_ms=max(1, round(duration_seconds * 1000)),
        )


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file:
        for chunk in iter(lambda: file.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
