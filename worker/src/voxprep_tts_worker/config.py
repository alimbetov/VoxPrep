from __future__ import annotations

import os
import socket
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse


class ConfigurationError(ValueError):
    """Raised when worker runtime configuration is invalid."""


@dataclass(frozen=True, slots=True)
class WorkerSettings:
    base_url: str
    worker_token: str
    worker_id: str
    model_cache_dir: Path
    temp_dir: Path
    poll_interval_seconds: float
    lease_heartbeat_interval_seconds: float
    http_connect_timeout_seconds: float
    http_request_timeout_seconds: float
    max_loaded_models: int
    log_level: str

    @classmethod
    def from_env(cls, environ: dict[str, str] | None = None) -> "WorkerSettings":
        env = os.environ if environ is None else environ

        base_url = _required(env, "BASE_URL").rstrip("/")
        parsed = urlparse(base_url)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ConfigurationError("BASE_URL must be an absolute http(s) URL")

        worker_token = _required(env, "WORKER_TOKEN")
        worker_id = (env.get("WORKER_ID") or env.get("HOSTNAME") or socket.gethostname()).strip()
        if not worker_id:
            raise ConfigurationError("WORKER_ID/HOSTNAME must not be blank")

        settings = cls(
            base_url=base_url,
            worker_token=worker_token,
            worker_id=worker_id,
            model_cache_dir=Path(env.get("MODEL_CACHE_DIR", "/var/lib/voxprep/tts/models")),
            temp_dir=Path(env.get("TEMP_DIR", "/tmp/voxprep-tts")),
            poll_interval_seconds=_positive_float(env, "POLL_INTERVAL_SECONDS", 2.0),
            lease_heartbeat_interval_seconds=_positive_float(
                env, "LEASE_HEARTBEAT_INTERVAL_SECONDS", 10.0
            ),
            http_connect_timeout_seconds=_positive_float(
                env, "HTTP_CONNECT_TIMEOUT_SECONDS", 5.0
            ),
            http_request_timeout_seconds=_positive_float(
                env, "HTTP_REQUEST_TIMEOUT_SECONDS", 30.0
            ),
            max_loaded_models=_positive_int(env, "MAX_LOADED_MODELS", 2),
            log_level=(env.get("LOG_LEVEL", "INFO").strip().upper() or "INFO"),
        )
        settings.ensure_directories()
        return settings

    def ensure_directories(self) -> None:
        _ensure_writable_directory(self.model_cache_dir, "MODEL_CACHE_DIR")
        _ensure_writable_directory(self.temp_dir, "TEMP_DIR")


def _required(env: dict[str, str] | os._Environ[str], name: str) -> str:
    value = env.get(name)
    if value is None or not value.strip():
        raise ConfigurationError(f"{name} is required")
    return value.strip()


def _positive_float(
    env: dict[str, str] | os._Environ[str], name: str, default: float
) -> float:
    raw = env.get(name)
    if raw is None or not raw.strip():
        return default
    try:
        value = float(raw)
    except ValueError as exc:
        raise ConfigurationError(f"{name} must be a number") from exc
    if value <= 0:
        raise ConfigurationError(f"{name} must be > 0")
    return value


def _positive_int(
    env: dict[str, str] | os._Environ[str], name: str, default: int
) -> int:
    raw = env.get(name)
    if raw is None or not raw.strip():
        return default
    try:
        value = int(raw)
    except ValueError as exc:
        raise ConfigurationError(f"{name} must be an integer") from exc
    if value <= 0:
        raise ConfigurationError(f"{name} must be > 0")
    return value


def _ensure_writable_directory(path: Path, variable_name: str) -> None:
    try:
        path.mkdir(parents=True, exist_ok=True)
        probe = path / ".voxprep-write-probe"
        probe.write_text("ok", encoding="utf-8")
        probe.unlink()
    except OSError as exc:
        raise ConfigurationError(f"{variable_name} is not writable") from exc
