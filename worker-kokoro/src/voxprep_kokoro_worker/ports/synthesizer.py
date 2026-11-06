from __future__ import annotations
from pathlib import Path
from typing import Protocol
from voxprep_kokoro_worker.domain.job import ClaimedJob, AudioArtifact

class SynthesizerPort(Protocol):
    def synthesize(self, *, job: ClaimedJob, model_dir: Path, output_wav: Path) -> Path: ...

class PostprocessorPort(Protocol):
    def postprocess(self, *, job: ClaimedJob, input_wav: Path, output_mp3: Path) -> AudioArtifact: ...
