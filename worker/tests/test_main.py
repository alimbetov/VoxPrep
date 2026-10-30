from __future__ import annotations

import signal
import threading
from pathlib import Path

import pytest

from voxprep_tts_worker import main as main_module
from voxprep_tts_worker.adapters.audio import FfmpegPostprocessor, PiperSynthesizer
from voxprep_tts_worker.adapters.backend_http import HttpBackendAdapter
from voxprep_tts_worker.adapters.model_cache import BackendModelCache
from voxprep_tts_worker.config import ConfigurationError, WorkerSettings


def _settings(tmp_path: Path) -> WorkerSettings:
    model_cache_dir = tmp_path / "models"
    temp_dir = tmp_path / "tmp"
    model_cache_dir.mkdir()
    temp_dir.mkdir()
    return WorkerSettings(
        base_url="https://backend.example",
        worker_token="worker-secret",
        worker_id="worker-01",
        model_cache_dir=model_cache_dir,
        temp_dir=temp_dir,
        poll_interval_seconds=0.1,
        lease_heartbeat_interval_seconds=10.0,
        http_connect_timeout_seconds=5.0,
        http_request_timeout_seconds=30.0,
        max_loaded_models=2,
        model_cache_max_bytes=123456,
        log_level="INFO",
    )


def test_signal_handlers_set_shared_shutdown_event(monkeypatch) -> None:
    handlers: dict[int, object] = {}

    def capture(signum: int, handler: object) -> None:
        handlers[signum] = handler

    monkeypatch.setattr(main_module.signal, "signal", capture)
    shutdown = threading.Event()

    main_module._install_signal_handlers(shutdown)

    assert signal.SIGTERM in handlers
    assert signal.SIGINT in handlers
    assert shutdown.is_set() is False
    handlers[signal.SIGTERM](signal.SIGTERM, None)  # type: ignore[operator]
    assert shutdown.is_set() is True


def test_build_production_loop_wires_real_functional_adapters(tmp_path: Path) -> None:
    settings = _settings(tmp_path)
    loop, backend = main_module.build_production_loop(settings, threading.Event())
    try:
        assert isinstance(backend, HttpBackendAdapter)
        assert loop._backend is backend
        processor = loop._processor
        assert processor._backend is backend
        assert isinstance(processor._model_cache, BackendModelCache)
        assert processor._model_cache._source is backend
        assert processor._model_cache._max_cache_bytes == 123456
        assert isinstance(processor._synthesizer, PiperSynthesizer)
        assert processor._synthesizer._max_loaded_models == 2
        assert isinstance(processor._postprocessor, FfmpegPostprocessor)
        assert processor._heartbeat_interval_seconds == 10.0
    finally:
        backend.close()


def test_main_runs_loop_and_always_closes_backend(monkeypatch, tmp_path: Path) -> None:
    settings = _settings(tmp_path)

    class FakeLoop:
        def __init__(self) -> None:
            self.ran = False

        def run(self) -> None:
            self.ran = True

    class FakeBackend:
        def __init__(self) -> None:
            self.closed = False

        def close(self) -> None:
            self.closed = True

    loop = FakeLoop()
    backend = FakeBackend()
    monkeypatch.setattr(
        main_module.WorkerSettings,
        "from_env",
        classmethod(lambda cls: settings),
    )
    monkeypatch.setattr(main_module, "_install_signal_handlers", lambda shutdown: None)
    monkeypatch.setattr(
        main_module,
        "build_production_loop",
        lambda actual_settings, shutdown: (loop, backend),
    )

    assert main_module.main() == 0
    assert loop.ran is True
    assert backend.closed is True


def test_main_closes_backend_when_loop_raises(monkeypatch, tmp_path: Path) -> None:
    settings = _settings(tmp_path)

    class FailingLoop:
        def run(self) -> None:
            raise RuntimeError("loop failed")

    class FakeBackend:
        def __init__(self) -> None:
            self.closed = False

        def close(self) -> None:
            self.closed = True

    backend = FakeBackend()
    monkeypatch.setattr(
        main_module.WorkerSettings,
        "from_env",
        classmethod(lambda cls: settings),
    )
    monkeypatch.setattr(main_module, "_install_signal_handlers", lambda shutdown: None)
    monkeypatch.setattr(
        main_module,
        "build_production_loop",
        lambda actual_settings, shutdown: (FailingLoop(), backend),
    )

    with pytest.raises(RuntimeError, match="loop failed"):
        main_module.main()

    assert backend.closed is True


def test_main_invalid_configuration_returns_exit_2(monkeypatch, capsys) -> None:
    def fail_config(cls):
        raise ConfigurationError("BASE_URL is required")

    monkeypatch.setattr(
        main_module.WorkerSettings,
        "from_env",
        classmethod(fail_config),
    )

    assert main_module.main() == 2
    captured = capsys.readouterr()
    assert "configuration error: BASE_URL is required" in captured.err
