from pathlib import Path

import pytest

from voxprep_tts_worker.config import ConfigurationError, WorkerSettings


def _env(tmp_path: Path) -> dict[str, str]:
    return {
        "BASE_URL": "https://api.voxprep.example/",
        "WORKER_TOKEN": "test-secret",
        "HOSTNAME": "container-123",
        "MODEL_CACHE_DIR": str(tmp_path / "models"),
        "TEMP_DIR": str(tmp_path / "tmp"),
    }


def test_settings_normalize_base_url_and_use_hostname(tmp_path: Path) -> None:
    settings = WorkerSettings.from_env(_env(tmp_path))

    assert settings.base_url == "https://api.voxprep.example"
    assert settings.worker_id == "container-123"
    assert settings.model_cache_dir.is_dir()
    assert settings.temp_dir.is_dir()


def test_explicit_worker_id_overrides_hostname(tmp_path: Path) -> None:
    env = _env(tmp_path)
    env["WORKER_ID"] = "tts-worker-01"

    settings = WorkerSettings.from_env(env)

    assert settings.worker_id == "tts-worker-01"


def test_missing_base_url_fails_fast_without_secret_in_message(tmp_path: Path) -> None:
    env = _env(tmp_path)
    del env["BASE_URL"]

    with pytest.raises(ConfigurationError, match="BASE_URL is required") as exc_info:
        WorkerSettings.from_env(env)

    assert "test-secret" not in str(exc_info.value)


def test_missing_worker_token_fails_fast(tmp_path: Path) -> None:
    env = _env(tmp_path)
    del env["WORKER_TOKEN"]

    with pytest.raises(ConfigurationError, match="WORKER_TOKEN is required"):
        WorkerSettings.from_env(env)


def test_non_http_base_url_is_rejected(tmp_path: Path) -> None:
    env = _env(tmp_path)
    env["BASE_URL"] = "ftp://backend.example"

    with pytest.raises(ConfigurationError, match="absolute http"):
        WorkerSettings.from_env(env)


def test_numeric_configuration_must_be_positive(tmp_path: Path) -> None:
    env = _env(tmp_path)
    env["POLL_INTERVAL_SECONDS"] = "0"

    with pytest.raises(ConfigurationError, match="POLL_INTERVAL_SECONDS must be > 0"):
        WorkerSettings.from_env(env)
