from __future__ import annotations

from pathlib import Path

from voxprep_tts_worker.domain.job import AudioArtifact, ClaimedJob


class FoundationBackend:
    """Safe foundation adapter used until the full production pipeline is ready.

    It intentionally claims no work. W2 provides a real HTTP control adapter,
    but production composition remains fail-closed until model, synthesis and
    output-upload adapters can complete a claimed job end-to-end.
    """

    def claim(self, worker_id: str) -> ClaimedJob | None:
        return None

    def heartbeat(self, *, worker_id: str, job: ClaimedJob) -> None:
        raise AssertionError("foundation backend cannot heartbeat a real job")

    def upload_output(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        artifact: AudioArtifact,
    ) -> None:
        raise AssertionError("foundation backend cannot upload output")

    def fail(
        self,
        *,
        worker_id: str,
        job: ClaimedJob,
        error_code: str,
        error_message: str,
    ) -> None:
        raise AssertionError("foundation backend cannot report failure")


class FoundationModelCache:
    def ensure_model(self, job: ClaimedJob) -> Path:
        raise AssertionError("foundation model cache cannot resolve models")


class FoundationSynthesizer:
    def synthesize(self, *, job: ClaimedJob, model_dir: Path, output_wav: Path) -> Path:
        raise AssertionError("foundation synthesizer cannot synthesize")


class FoundationPostprocessor:
    def postprocess(self, *, job: ClaimedJob, input_wav: Path, output_mp3: Path) -> AudioArtifact:
        raise AssertionError("foundation postprocessor cannot process audio")
