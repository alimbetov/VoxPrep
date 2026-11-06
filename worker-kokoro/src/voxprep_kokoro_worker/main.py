from __future__ import annotations
import logging
import signal
import threading
from voxprep_kokoro_worker.adapters.backend_http import KokoroBackend
from voxprep_kokoro_worker.adapters.model_cache import KokoroModelCache
from voxprep_kokoro_worker.adapters.audio import KokoroSynthesizer, FfmpegPostprocessor
from voxprep_kokoro_worker.application.job_processor import JobProcessor
from voxprep_kokoro_worker.application.worker_loop import WorkerLoop
from voxprep_kokoro_worker.config import WorkerSettings, ConfigurationError

logger = logging.getLogger(__name__)

def build_loop(settings: WorkerSettings, stop: threading.Event):
    backend = KokoroBackend(settings.base_url, settings.token, settings.timeout_seconds)
    cache = KokoroModelCache(settings.cache_dir, backend, settings.max_artifact_bytes)
    processor = JobProcessor(worker_id=settings.worker_id, temp_dir=settings.temp_dir,
        backend=backend, model_cache=cache, synthesizer=KokoroSynthesizer(),
        postprocessor=FfmpegPostprocessor(),
        heartbeat_interval_seconds=settings.heartbeat_seconds)
    return WorkerLoop(worker_id=settings.worker_id, backend=backend,
        processor=processor, poll_interval_seconds=settings.poll_seconds, shutdown=stop), backend

def main() -> int:
    import sys
    try:
        settings = WorkerSettings.from_env()
    except ConfigurationError as e:
        print("Kokoro Worker configuration error: " + str(e), file=sys.stderr)
        return 2
    logging.basicConfig(level=logging.INFO)
    stop = threading.Event()
    signal.signal(signal.SIGTERM, lambda *_: stop.set())
    signal.signal(signal.SIGINT, lambda *_: stop.set())
    loop, backend = build_loop(settings, stop)
    try:
        loop.run()
    finally:
        backend.close()
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
