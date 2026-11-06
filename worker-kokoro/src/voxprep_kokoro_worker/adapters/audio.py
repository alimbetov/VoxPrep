from __future__ import annotations
import hashlib
import json
import subprocess
import wave
from typing import Callable
from pathlib import Path
from voxprep_kokoro_worker.domain.job import ClaimedJob, AudioArtifact
from voxprep_kokoro_worker.domain.errors import AudioQcError, ModelLoadError, SynthesisError, PostprocessError, LeaseLostError
from voxprep_kokoro_worker.adapters.voice_bundle import ensure_voices_archive, SUPPORTED_VOICES
from voxprep_kokoro_worker.adapters.text_chunks import split_text

PROFILE = "mp3-mono-24k-64k-v1"

class KokoroSynthesizer:
    """ONNX inference adapter with local three-voice NPZ conversion.

    Input ONNX and voice style vectors are verified by model cache first.
    Graph/runtime compatibility must be demonstrated with real audio before K3.
    """
    def synthesize(self, *, job: ClaimedJob, model_dir: Path, output_wav: Path,
                   check_lease: Callable[[], None] | None = None) -> Path:
        model_path = model_dir / "onnx" / "model_quantized.onnx"
        if not model_path.is_file() or model_path.is_symlink():
            raise ModelLoadError("Kokoro ONNX model is missing")
        if SUPPORTED_VOICES.get(job.voice_code) != job.language:
            raise SynthesisError("Unsupported voice/locale pair")
        voices_path = ensure_voices_archive(model_dir)
        if not 0.5 <= job.speed <= 2:
            raise SynthesisError("Unsupported Kokoro speed")
        chunks = split_text(job.normalized_tts_text)
        try:
            from kokoro_onnx import Kokoro
            import numpy as np

            engine = Kokoro(str(model_path), str(voices_path))
            output_wav.parent.mkdir(parents=True, exist_ok=True)
            sample_rate_expected = None
            total_frames = 0
            with wave.open(str(output_wav), "wb") as wav:
                wav.setnchannels(1)
                wav.setsampwidth(2)
                for chunk in chunks:
                    if check_lease is not None:
                        check_lease()
                    samples, sample_rate = engine.create(
                        chunk, voice=job.voice_code, speed=job.speed,
                        lang="en-us" if job.language == "en-US" else "en-gb"
                    )
                    pcm = np.asarray(samples, dtype=np.float32)
                    if (pcm.ndim != 1 or pcm.size == 0
                        or not np.isfinite(pcm).all()
                        or not isinstance(sample_rate, (int, np.integer))
                        or not 8000 <= sample_rate <= 48000
                        or pcm.size > int(sample_rate) * 120):
                        raise SynthesisError("Invalid or oversized Kokoro PCM chunk")
                    if sample_rate_expected is None:
                        sample_rate_expected = int(sample_rate)
                        wav.setframerate(sample_rate_expected)
                    elif sample_rate_expected != int(sample_rate):
                        raise SynthesisError("Inconsistent Kokoro sample rates")
                    total_frames += pcm.size
                    if total_frames > sample_rate_expected * 1200:
                        raise SynthesisError("Kokoro job exceeds 20-minute audio limit")
                    # Stream PCM per chunk to the WAV file. Do not concatenate
                    # all samples into one large in-memory array.
                    pcm = np.clip(pcm, -1.0, 1.0)
                    wav.writeframes((pcm * 32767).astype("<i2").tobytes())
                    if check_lease is not None:
                        check_lease()
            return output_wav
        except (SynthesisError, LeaseLostError):
            raise
        except Exception as exc:
            raise SynthesisError("Kokoro ONNX inference failed") from exc

class FfmpegPostprocessor:
    def postprocess(self, *, job: ClaimedJob, input_wav: Path, output_mp3: Path) -> AudioArtifact:
        del job
        if not input_wav.is_file() or input_wav.stat().st_size <= 44:
            raise PostprocessError("Empty WAV input")
        try:
            subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(input_wav),
            "-vn", "-ac", "1", "-ar", "24000", "-codec:a", "libmp3lame",
            "-b:a", "64k", str(output_mp3)], check=True, timeout=120, capture_output=True)
        except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired) as exc:
            raise PostprocessError("FFmpeg conversion failed") from exc
        try:
            result = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "a:0",
            "-show_entries", "stream=codec_name,sample_rate,channels,bit_rate:format=duration",
            "-of", "json", str(output_mp3)], check=True, capture_output=True, timeout=20)
            data = json.loads(result.stdout)
            stream = data["streams"][0]
            duration = float(data["format"]["duration"])
        except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired, ValueError, KeyError, IndexError, TypeError) as exc:
            raise AudioQcError("Invalid MP3 metadata") from exc
        if (stream["codec_name"] != "mp3" or int(stream["sample_rate"]) != 24000
            or int(stream["channels"]) != 1 or not 60000 <= int(stream["bit_rate"]) <= 68000
            or duration <= 0):
            raise AudioQcError("MP3 profile mismatch")
        digest = hashlib.sha256()
        size = 0
        with output_mp3.open("rb") as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b""):
                digest.update(block)
                size += len(block)
        return AudioArtifact(output_mp3, "audio/mpeg", PROFILE,
                             digest.hexdigest(), size,
                             max(1, round(duration * 1000)))
