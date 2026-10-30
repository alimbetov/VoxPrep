from __future__ import annotations

import logging
import threading

from voxprep_tts_worker.application.job_processor import JobProcessor
from voxprep_tts_worker.domain.errors import BackendTransportError
from voxprep_tts_worker.ports.backend import BackendPort

logger = logging.getLogger(__name__)


class WorkerLoop:
    def __init__(
        self,
        *,
        worker_id: str,
        backend: BackendPort,
        processor: JobProcessor,
        poll_interval_seconds: float,
        shutdown: threading.Event,
    ) -> None:
        self._worker_id = worker_id
        self._backend = backend
        self._processor = processor
        self._poll_interval_seconds = poll_interval_seconds
        self._shutdown = shutdown

    def run_once(self) -> bool:
        if self._shutdown.is_set():
            return False

        try:
            job = self._backend.claim(self._worker_id)
        except BackendTransportError:
            logger.warning(
                "backend temporarily unavailable while claiming work",
                extra={"worker_id": self._worker_id},
                exc_info=True,
            )
            return False

        if job is None:
            return False

        self._processor.process(job)
        return True

    def run(self) -> None:
        logger.info("worker polling started", extra={"worker_id": self._worker_id})
        while not self._shutdown.is_set():
            processed = self.run_once()
            if not processed:
                self._shutdown.wait(self._poll_interval_seconds)
        logger.info("worker polling stopped", extra={"worker_id": self._worker_id})
