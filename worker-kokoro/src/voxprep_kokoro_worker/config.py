from __future__ import annotations
import os
import socket
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlparse

class ConfigurationError(ValueError):
    pass

@dataclass(frozen=True)
class WorkerSettings:
    base_url: str
    token: str
    worker_id: str
    cache_dir: Path
    temp_dir: Path
    poll_seconds: float
    heartbeat_seconds: float
    timeout_seconds: float
    max_artifact_bytes: int

    @classmethod
    def from_env(cls, env: dict[str, str] | None = None) -> "WorkerSettings":
        env = os.environ if env is None else env
        base_url = env.get("BASE_URL", "").rstrip("/")
        parsed = urlparse(base_url)
        if parsed.scheme not in ("https", "http") or not parsed.netloc:
            raise ConfigurationError("BASE_URL must be http(s)")
        token = env.get("KOKORO_WORKER_TOKEN", "")
        if not token or token != token.strip():
            raise ConfigurationError("KOKORO_WORKER_TOKEN is required")
        worker_id = (env.get("WORKER_ID") or socket.gethostname()).strip()
        if not worker_id or len(worker_id) > 128:
            raise ConfigurationError("Invalid WORKER_ID")
        try:
            poll = float(env.get("POLL_SECONDS", "2"))
            heartbeat = float(env.get("HEARTBEAT_SECONDS", "10"))
            timeout = float(env.get("HTTP_TIMEOUT_SECONDS", "30"))
            max_bytes = int(env.get("MAX_ARTIFACT_BYTES", str(256 * 1024 * 1024)))
        except ValueError as exc:
            raise ConfigurationError("Invalid numeric worker configuration") from exc
        if min(poll, heartbeat, timeout) <= 0 or not 0 < max_bytes <= 2 * 1024**3:
            raise ConfigurationError("Worker limits must be positive")
        cache = Path(env.get("MODEL_CACHE_DIR", "/var/lib/voxprep/kokoro/models"))
        temp = Path(env.get("TEMP_DIR", "/tmp/voxprep-kokoro"))
        for directory in (cache, temp):
            directory.mkdir(parents=True, exist_ok=True)
        return cls(base_url, token, worker_id, cache, temp, poll, heartbeat, timeout, max_bytes)
