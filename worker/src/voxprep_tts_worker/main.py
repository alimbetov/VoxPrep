from __future__ import annotations

import logging
import signal
import sys
import threading

from voxprep_tts_worker.adapters.foundation import (
    FoundationBackend,
    FoundationModelCache,
    FoundationPostprocessor,
    FoundationSynthesizer,
)
from voxprep_tts_worker.application.job_processor import JobProcessor
from voxprep_tts_worker.application.worker_loop import WorkerLoop
from voxprep_tts_worker.config import ConfigurationError, WorkerSettings

logger = logging.getLogger(__name__)


def _configure_logging(level: str) -> None:
    logging.basicConfig(
        level=getattr(logging, level, logging.INFO),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )


def _install_signal_handlers(shutdown: threading.Event) -> None:
    def request_shutdown(signum: int, _frame: object) -> None:
        logger.info("shutdown requested", extra={"signal": signum})
        shutdown.set()

    signal.signal(signal.SIGTERM, request_shutdown)
    signal.signal(signal.SIGINT, request_shutdown)


def build_foundation_loop(
    settings: WorkerSettings,
    shutdown: threading.Event,
) -> WorkerLoop:
    backend = FoundationBackend()
    processor = JobProcessor(
        worker_id=settings.worker_id,
        temp_dir=settings.temp_dir,
        backend=backend,
        model_cache=FoundationModelCache(),
        synthesizer=FoundationSynthesizer(),
        postprocessor=FoundationPostprocessor(),
    )
    return WorkerLoop(
        worker_id=settings.worker_id,
        backend=backend,
        processor=processor,
        poll_interval_seconds=settings.poll_interval_seconds,
        shutdown=shutdown,
    )


def main() -> int:
    try:
        settings = WorkerSettings.from_env()
    except ConfigurationError as exc:
        print(f"configuration error: {exc}", file=sys.stderr)
        return 2

    _configure_logging(settings.log_level)
    shutdown = threading.Event()
    _install_signal_handlers(shutdown)

    logger.warning(
        "W1 foundation runtime active; real Backend HTTP adapter is introduced in W2",
        extra={"worker_id": settings.worker_id, "base_url": settings.base_url},
    )

    loop = build_foundation_loop(settings, shutdown)
    loop.run()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
