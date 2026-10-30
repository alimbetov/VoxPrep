from __future__ import annotations

import logging
import shutil
import tempfile
from contextlib import nullcontext
from pathlib import Path

from voxprep_tts_worker.application.heartbeat import LeaseHeartbeat
from voxprep_tts_worker.domain.errors import LeaseLostError, WorkerError
from voxprep_tts_worker.domain.job import ClaimedJob
from voxprep_tts_worker.ports.backend import BackendPort, ModelCachePort
from voxprep_tts_worker.ports.synthesizer import PostprocessorPort, SynthesizerPort

logger = logging.getLogger(__name__)


class JobProcessor:
    def __init__(
        self,
        *,
        worker_id: str,
        temp_dir: Path,
        backend: BackendPort,
        model_cache: ModelCachePort,
        synthesizer: SynthesizerPort,
        postprocessor: PostprocessorPort,
        heartbeat_interval_seconds: float | None = None,
    ) -> None:
        self._worker_id = worker_id
        self._temp_dir = temp_dir
        self._backend = backend
        self._model_cache = model_cache
        self._synthesizer = synthesizer
        self._postprocessor = postprocessor
        self._heartbeat_interval_seconds = heartbeat_interval_seconds

    def process(self, job: ClaimedJob) -> None:
        job_dir = Path(tempfile.mkdtemp(prefix=f"{job.job_id}-", dir=self._temp_dir))
        source_wav = job_dir / "source.wav"
        output_mp3 = job_dir / "output.mp3"

        logger.info(
            "processing job",
            extra={"worker_id": self._worker_id, "job_id": job.job_id, "file_id": job.file_id},
        )

        heartbeat = (
            LeaseHeartbeat(
                backend=self._backend,
                worker_id=self._worker_id,
                job=job,
                interval_seconds=self._heartbeat_interval_seconds,
            )
            if self._heartbeat_interval_seconds is not None
            else None
        )

        try:
            with heartbeat if heartbeat is not None else nullcontext():
                model_dir = self._model_cache.ensure_model(job)
                if heartbeat is not None:
                    heartbeat.assert_owned()

                wav_path = self._synthesizer.synthesize(
                    job=job,
                    model_dir=model_dir,
                    output_wav=source_wav,
                )
                if heartbeat is not None:
                    heartbeat.assert_owned()

                artifact = self._postprocessor.postprocess(
                    job=job,
                    input_wav=wav_path,
                    output_mp3=output_mp3,
                )
                if heartbeat is not None:
                    heartbeat.assert_owned()

                self._backend.upload_output(
                    worker_id=self._worker_id,
                    job=job,
                    artifact=artifact,
                )
        except LeaseLostError:
            logger.warning(
                "lease lost; result will not be finalized",
                extra={"worker_id": self._worker_id, "job_id": job.job_id, "file_id": job.file_id},
            )
        except WorkerError as exc:
            logger.exception(
                "classified worker failure",
                extra={"worker_id": self._worker_id, "job_id": job.job_id, "file_id": job.file_id},
            )
            try:
                if heartbeat is not None:
                    heartbeat.assert_owned()
                self._backend.fail(
                    worker_id=self._worker_id,
                    job=job,
                    error_code=exc.code,
                    error_message=str(exc),
                )
            except LeaseLostError:
                logger.warning(
                    "lease lost before failure could be reported",
                    extra={"worker_id": self._worker_id, "job_id": job.job_id},
                )
        finally:
            shutil.rmtree(job_dir, ignore_errors=True)
