from __future__ import annotations

from pathlib import Path

from voxprep_tts_worker.domain.job import AudioArtifact, ClaimedJob


class FoundationBackend:
    """W1-only backend adapter.

    It intentionally claims no work. W2 replaces this adapter with the real
    machine-token authenticated HTTP adapter without changing orchestration.
    """

    def claim(self, worker_id: str) -> ClaimedJob | None:
        return None

    def upload_output(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        artifact: AudioArtifact,
    ) -> None:
        raise AssertionError("W1 foundation backend cannot upload output")

    def fail(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        error_code: str,
        error_message: str,
    ) -> None:
        raise AssertionError("W1 foundation backend cannot report failure")


class FoundationModelCache:
    def ensure_model(self, job: ClaimedJob) -> Path:
        raise AssertionError("W1 foundation model cache cannot resolve models")


class FoundationSynthesizer:
    def synthesize(self, *, job: ClaimedJob, model_dir: Path, output_wav: Path) -> Path:
        raise AssertionError("W1 foundation synthesizer cannot synthesize")


class FoundationPostprocessor:
    def postprocess(self, *, job: ClaimedJob, input_wav: Path, output_mp3: Path) -> AudioArtifact:
        raise AssertionError("W1 foundation postprocessor cannot process audio")
