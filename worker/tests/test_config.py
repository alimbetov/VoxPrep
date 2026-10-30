from pathlib import Path

import pytest

from voxprep_tts_worker import config
from voxprep_tts_worker.config import ConfigurationError, WorkerSettings


def _env(tmp_path: Path) -> dict[str, str]:
    return {
        "BASE_URL": "https://api.voxprep.example/",
        "WORKER_TOKEN": "test-secret",
        "HOSTNAME": "container-123",
        "MODEL_CACHE_DIR": str(tmp_path / "models"),
        "TEMP_DIR": str(tmp_path / "tmp"),
    }


def test_settings_normalize_base_url_use_hostname_and_apply_defaults(tmp_path: Path) -> None:
    settings = WorkerSettings.from_env(_env(tmp_path))

    assert settings.base_url == "https://api.voxprep.example"
    assert settings.worker_id == "container-123"
    assert settings.model_cache_dir.is_dir()
    assert settings.temp_dir.is_dir()
    assert settings.poll_interval_seconds == 2.0
    assert settings.lease_heartbeat_interval_seconds == 10.0
    assert settings.http_connect_timeout_seconds == 5.0
    assert settings.http_request_timeout_seconds == 30.0
    assert settings.max_loaded_models == 2
    assert settings.log_level == "INFO"


def test_explicit_worker_id_and_runtime_values_override_defaults(tmp_path: Path) -> None:
    env = _env(tmp_path)
    env.update(
        {
            "WORKER_ID": "tts-worker-01",
            "POLL_INTERVAL_SECONDS": "0.5",
            "LEASE_HEARTBEAT_INTERVAL_SECONDS": "3",
            "HTTP_CONNECT_TIMEOUT_SECONDS": "2.5",
            "HTTP_REQUEST_TIMEOUT_SECONDS": "15",
            "MAX_LOADED_MODELS": "4",
            "LOG_LEVEL": "debug",
        }
    )

    settings = WorkerSettings.from_env(env)

    assert settings.worker_id == "tts-worker-01"
    assert settings.poll_interval_seconds == 0.5
    assert settings.lease_heartbeat_interval_seconds == 3.0
    assert settings.http_connect_timeout_seconds == 2.5
    assert settings.http_request_timeout_seconds == 15.0
    assert settings.max_loaded_models == 4
    assert settings.log_level == "DEBUG"


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


@pytest.mark.parametrize(
    "base_url",
    ["ftp://backend.example", "https:///missing-host", "backend.example"],
)
def test_non_http_or_non_absolute_base_url_is_rejected(tmp_path: Path, base_url: str) -> None:
    env = _env(tmp_path)
    env["BASE_URL"] = base_url

    with pytest.raises(ConfigurationError, match="absolute http"):
        WorkerSettings.from_env(env)


@pytest.mark.parametrize(
    ("name", "value", "message"),
    [
        ("POLL_INTERVAL_SECONDS", "0", "must be > 0"),
        ("HTTP_CONNECT_TIMEOUT_SECONDS", "abc", "must be a number"),
        ("MAX_LOADED_MODELS", "0", "must be > 0"),
        ("MAX_LOADED_MODELS", "1.5", "must be an integer"),
    ],
)
def test_numeric_configuration_validation(
    tmp_path: Path, name: str, value: str, message: str
) -> None:
    env = _env(tmp_path)
    env[name] = value

    with pytest.raises(ConfigurationError, match=message):
        WorkerSettings.from_env(env)


def test_worker_identity_must_not_resolve_to_blank(monkeypatch, tmp_path: Path) -> None:
    env = _env(tmp_path)
    env["HOSTNAME"] = ""
    env.pop("WORKER_ID", None)
    monkeypatch.setattr(config.socket, "gethostname", lambda: "")

    with pytest.raises(ConfigurationError, match="must not be blank"):
        WorkerSettings.from_env(env)


def test_model_cache_directory_must_be_writable_directory(tmp_path: Path) -> None:
    not_a_directory = tmp_path / "models"
    not_a_directory.write_text("file", encoding="utf-8")
    env = _env(tmp_path)
    env["MODEL_CACHE_DIR"] = str(not_a_directory)

    with pytest.raises(ConfigurationError, match="MODEL_CACHE_DIR is not writable"):
        WorkerSettings.from_env(env)
