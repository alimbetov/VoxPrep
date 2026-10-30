from __future__ import annotations

import tempfile
import wave
from datetime import datetime, timezone
from pathlib import Path

from voxprep_tts_worker.adapters.audio import FfmpegPostprocessor
from voxprep_tts_worker.domain.job import ClaimedJob


def main() -> int:
    with tempfile.TemporaryDirectory(prefix="voxprep-audio-smoke-") as temp:
        root = Path(temp)
        wav_path = root / "input.wav"
        mp3_path = root / "output.mp3"

        with wave.open(str(wav_path), "wb") as wav_file:
            wav_file.setnchannels(1)
            wav_file.setsampwidth(2)
            wav_file.setframerate(24000)
            wav_file.writeframes(b"\x00\x00" * 2400)

        job = ClaimedJob(
            job_id="smoke-job",
            file_id="smoke-file",
            content_revision_id="smoke-revision",
            audio_role="PRIMARY",
            normalized_tts_text="smoke",
            language="en-US",
            voice_model_id="smoke-model",
            voice_model_code="smoke-model",
            model_sha256="a" * 64,
            config_sha256="b" * 64,
            fingerprint="c" * 64,
            lease_token="smoke-lease",
            lease_until=datetime(2030, 1, 1, tzinfo=timezone.utc),
        )
        artifact = FfmpegPostprocessor().postprocess(
            job=job,
            input_wav=wav_path,
            output_mp3=mp3_path,
        )
        assert artifact.content_type == "audio/mpeg"
        assert artifact.audio_profile == "mp3-mono-24k-64k-v1"
        assert artifact.size_bytes > 0
        assert artifact.duration_ms is not None and artifact.duration_ms > 0

    print("audio runtime smoke ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
