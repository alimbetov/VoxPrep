"""K3 acceptance: REAL cached model + three voices -> WAV -> MP3.

No mocks or network access. Requires fully downloaded, SHA-verified model_dir
created by Backend staging and Worker cache. Never used as a substitute for
full Backend/RustFS/MVC acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import tempfile
from datetime import datetime, timedelta, timezone
from pathlib import Path
from uuid import uuid4

from voxprep_kokoro_worker.adapters.audio import KokoroSynthesizer, FfmpegPostprocessor
from voxprep_kokoro_worker.adapters.voice_bundle import SUPPORTED_VOICES
from voxprep_kokoro_worker.domain.job import ClaimedJob


def run(model_dir: Path, destination: Path) -> dict:
    destination.mkdir(parents=True, exist_ok=True)
    model_dir = model_dir.resolve(strict=True)
    voices = {
        "af_heart": "Your lesson begins with this short English sentence.",
        "am_michael": "Hello, what would you like to practice today?",
        "bf_emma": "Good morning. Shall we practise British pronunciation?",
    }
    synthesis = KokoroSynthesizer()
    mp3 = FfmpegPostprocessor()
    results = []
    for code, text in voices.items():
        job = ClaimedJob(
            job_id=str(uuid4()), file_id=str(uuid4()), content_revision_id=str(uuid4()),
            audio_role="pronunciation", normalized_tts_text=text,
            language=SUPPORTED_VOICES[code], voice_model_id=str(uuid4()),
            voice_model_code="kokoro-education", model_sha256="a"*64,
            config_sha256="b"*64, fingerprint="c"*64, lease_token=str(uuid4()),
            lease_until=datetime.now(timezone.utc)+timedelta(minutes=5),
            engine="KOKORO", manifest_sha256="d"*64,
            voice_code=code, speed=1.0)
        wav = destination / f"{code}.wav"
        target = destination / f"{code}.mp3"
        synthesis.synthesize(job=job, model_dir=model_dir, output_wav=wav)
        result = mp3.postprocess(job=job, input_wav=wav, output_mp3=target)
        results.append({
            "voice": code, "language": job.language,
            "wav_bytes": wav.stat().st_size,
            "mp3_bytes": result.size_bytes,
            "mp3_sha256": result.sha256,
            "duration_ms": result.duration_ms,
            "audio_profile": result.audio_profile,
        })
    report = {"model_dir": str(model_dir), "results": results}
    (destination / "k3-real-inference-report.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8")
    return report


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-dir", required=True, type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    report = run(args.model_dir, args.output_dir)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
