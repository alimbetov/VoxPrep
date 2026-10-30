from __future__ import annotations

import logging
import signal
import sys
import threading

from voxprep_tts_worker.adapters.audio import FfmpegPostprocessor, PiperSynthesizer
from voxprep_tts_worker.adapters.backend_http import HttpBackendAdapter
from voxprep_tts_worker.adapters.model_cache import BackendModelCache
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


def build_production_loop(
    settings: WorkerSettings,
    shutdown: threading.Event,
) -> tuple[WorkerLoop, HttpBackendAdapter]:
    backend = HttpBackendAdapter(
        base_url=settings.base_url,
        worker_token=settings.worker_token,
        connect_timeout_seconds=settings.http_connect_timeout_seconds,
        request_timeout_seconds=settings.http_request_timeout_seconds,
    )
    model_cache = BackendModelCache(
        cache_root=settings.model_cache_dir,
        source=backend,
        max_cache_bytes=settings.model_cache_max_bytes,
    )
    processor = JobProcessor(
        worker_id=settings.worker_id,
        temp_dir=settings.temp_dir,
        backend=backend,
        model_cache=model_cache,
        synthesizer=PiperSynthesizer(max_loaded_models=settings.max_loaded_models),
        postprocessor=FfmpegPostprocessor(),
        heartbeat_interval_seconds=settings.lease_heartbeat_interval_seconds,
    )
    loop = WorkerLoop(
        worker_id=settings.worker_id,
        backend=backend,
        processor=processor,
        poll_interval_seconds=settings.poll_interval_seconds,
        shutdown=shutdown,
    )
    return loop, backend


def main() -> int:
    try:
        settings = WorkerSettings.from_env()
    except ConfigurationError as exc:
        print(f"configuration error: {exc}", file=sys.stderr)
        return 2

    _configure_logging(settings.log_level)
    shutdown = threading.Event()
    _install_signal_handlers(shutdown)

    logger.info(
        "functional TTS worker active",
        extra={"worker_id": settings.worker_id, "base_url": settings.base_url},
    )

    loop, backend = build_production_loop(settings, shutdown)
    try:
        loop.run()
    finally:
        backend.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
