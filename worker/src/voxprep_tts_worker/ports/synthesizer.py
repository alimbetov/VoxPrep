from __future__ import annotations

from pathlib import Path
from typing import Protocol

from voxprep_tts_worker.domain.job import AudioArtifact, ClaimedJob


class SynthesizerPort(Protocol):
    def synthesize(self, *, job: ClaimedJob, model_dir: Path, output_wav: Path) -> Path:
        """Synthesize the claimed normalized text into a temporary WAV file."""


class PostprocessorPort(Protocol):
    def postprocess(self, *, job: ClaimedJob, input_wav: Path, output_mp3: Path) -> AudioArtifact:
        """Convert temporary WAV into the qualified production MP3 artifact."""
