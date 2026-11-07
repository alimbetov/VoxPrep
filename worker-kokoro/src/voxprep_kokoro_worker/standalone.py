"""Standalone authenticated Kokoro HTTP API.

This is an opt-in synchronous API, NOT the VoxPrep V2 poller. The server
limits work to one inference at a time, persists completed MP3s atomically,
and can optionally mirror results to S3-compatible RustFS.
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging
import math
import os
import shutil
import signal
import tempfile
import threading
from dataclasses import dataclass
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit
from uuid import uuid4

from voxprep_kokoro_worker.adapters.audio import FfmpegPostprocessor, KokoroSynthesizer
from voxprep_kokoro_worker.adapters.model_cache import KokoroModelCache
from voxprep_kokoro_worker.adapters.pinned_sources import PinnedModelSource
from voxprep_kokoro_worker.adapters.voice_bundle import SUPPORTED_VOICES
from voxprep_kokoro_worker.domain.job import ClaimedJob

LOG = logging.getLogger(__name__)
MAX_BODY = 16384
MAX_OUTPUT_BYTES = 16 * 1024 * 1024


@dataclass(frozen=True)
class StandaloneSettings:
    token: str
    host: str
    port: int
    manifest_path: Path
    cache_dir: Path
    temp_dir: Path
    output_dir: Path
    local_model_dir: Path | None
    hf_repo: str | None
    model_s3_bucket: str | None
    model_s3_prefix: str
    output_s3_bucket: str | None
    output_s3_prefix: str
    s3_endpoint_url: str | None
    s3_region: str | None

    @classmethod
    def from_env(cls, env=None):
        env = os.environ if env is None else env
        token = env.get("STANDALONE_API_TOKEN", "")
        if len(token) < 24 or token != token.strip():
            raise ValueError("STANDALONE_API_TOKEN must be at least 24 non-whitespace characters")
        host = env.get("STANDALONE_HOST", "127.0.0.1")
        if host not in ("127.0.0.1", "::1", "localhost") and not env.get("STANDALONE_ALLOW_REMOTE") == "true":
            raise ValueError("Non-loopback binding requires explicit STANDALONE_ALLOW_REMOTE=true and reverse proxy TLS")
        port = int(env.get("STANDALONE_PORT", "8086"))
        if not 1 <= port <= 65535:
            raise ValueError("Invalid standalone port")
        def required_path(key):
            value = env.get(key)
            if not value:
                raise ValueError(key + " is required")
            return Path(value).expanduser()
        def optional_path(key):
            return Path(env[key]).expanduser() if env.get(key) else None
        return cls(
            token, host, port, required_path("STANDALONE_MANIFEST_PATH"),
            required_path("MODEL_CACHE_DIR"), required_path("TEMP_DIR"),
            required_path("STANDALONE_OUTPUT_DIR"), optional_path("STANDALONE_MODEL_DIR"),
            env.get("STANDALONE_HF_REPO"), env.get("STANDALONE_MODEL_S3_BUCKET"),
            env.get("STANDALONE_MODEL_S3_PREFIX", ""),
            env.get("STANDALONE_OUTPUT_S3_BUCKET"),
            env.get("STANDALONE_OUTPUT_S3_PREFIX", ""),
            env.get("STANDALONE_S3_ENDPOINT_URL"),
            env.get("STANDALONE_S3_REGION"),
        )


class StandaloneService:
    def __init__(self, settings, *, synthesizer=None, postprocessor=None):
        self.settings = settings
        for path in (settings.cache_dir, settings.temp_dir, settings.output_dir):
            path.mkdir(parents=True, exist_ok=True)
        if settings.output_dir.is_symlink():
            raise ValueError("Symlink output directory is forbidden")
        if settings.manifest_path.stat().st_size > 65536:
            raise ValueError("Model manifest is too large")
        self.manifest = json.loads(settings.manifest_path.read_text(encoding="utf-8"))
        self.source = PinnedModelSource(
            manifest=self.manifest, local_dir=settings.local_model_dir,
            hf_repo=settings.hf_repo, s3_bucket=settings.model_s3_bucket,
            s3_prefix=settings.model_s3_prefix,
            s3_endpoint_url=settings.s3_endpoint_url, s3_region=settings.s3_region)
        self.cache = KokoroModelCache(settings.cache_dir, self.source)
        self.synthesizer = synthesizer or KokoroSynthesizer()
        self.postprocessor = postprocessor or FfmpegPostprocessor()
        self.busy = threading.BoundedSemaphore(1)
        self.ready = False
        self._s3 = None

    def _job(self, *, text: str, voice: str, speed: float) -> ClaimedJob:
        language = SUPPORTED_VOICES[voice]
        digest = hashlib.sha256(
            json.dumps([self.manifest["manifestSha256"], voice, speed, text],
                       ensure_ascii=False, separators=(",", ":")).encode("utf-8")).hexdigest()
        return ClaimedJob(
            job_id=str(uuid4()), file_id=str(uuid4()),
            content_revision_id=str(uuid4()), audio_role="narration",
            normalized_tts_text=text, language=language,
            voice_model_id=str(uuid4()), voice_model_code=self.manifest["modelCode"],
            model_sha256="", config_sha256="", fingerprint=digest,
            lease_token=str(uuid4()), lease_until=datetime.now(timezone.utc),
            engine="KOKORO", manifest_sha256=self.manifest["manifestSha256"],
            voice_code=voice, speed=speed,
            bundle_model_code=self.manifest["modelCode"],
            voice_artifact_sha256=next(
                (a["sha256"] for a in self.manifest["artifacts"]
                 if a["path"] == f"voices/{voice}.bin"), ""),
        )

    def startup(self) -> None:
        # Validate canonical manifest and pre-install at least the primary
        # model and voice bundle before advertising readiness.
        first = next(iter(SUPPORTED_VOICES))
        with self.cache.hold_model(self._job(text="Health probe", voice=first, speed=1.0)):
            pass
        self.ready = True

    def synthesize(self, data: dict) -> dict:
        if not isinstance(data, dict) or set(data) != {"text", "voiceCode", "speed"}:
            raise ValueError("Require exactly text, voiceCode, speed")
        text = data["text"]
        voice = data["voiceCode"]
        speed = data["speed"]
        if not isinstance(text, str) or not text.strip() or len(text) > 12000 or "\x00" in text:
            raise ValueError("Invalid text length or content")
        if voice not in SUPPORTED_VOICES:
            raise ValueError("Unsupported voiceCode")
        if isinstance(speed, bool) or not isinstance(speed, (int, float)) or not math.isfinite(speed) or not 0.5 <= speed <= 2:
            raise ValueError("Speed must be between 0.5 and 2")
        if not self.busy.acquire(blocking=False):
            raise RuntimeError("Worker busy")
        try:
            job = self._job(text=text.strip(), voice=voice, speed=float(speed))
            work = Path(tempfile.mkdtemp(prefix="standalone-", dir=self.settings.temp_dir))
            try:
                with self.cache.hold_model(job) as model_dir:
                    wav = self.synthesizer.synthesize(
                        job=job, model_dir=model_dir, output_wav=work / "audio.wav")
                artifact = self.postprocessor.postprocess(
                    job=job, input_wav=wav, output_mp3=work / "audio.mp3")
                if not artifact.path.is_file() or not 0 < artifact.size_bytes <= MAX_OUTPUT_BYTES:
                    raise ValueError("Audio output exceeds configured bounds")
                with artifact.path.open("rb") as source:
                    digest = hashlib.file_digest(source, "sha256").hexdigest()
                if artifact.path.stat().st_size != artifact.size_bytes or digest != artifact.sha256:
                    raise ValueError("Output checksum or size mismatch")
                output_id = job.job_id
                if self.settings.output_s3_bucket:
                    self._upload_s3(artifact.path, output_id, digest)
                final = self.settings.output_dir / (output_id + ".mp3")
                artifact.path.replace(final)
                info = {
                    "id": output_id, "sha256": digest, "sizeBytes": artifact.size_bytes,
                    "durationMs": artifact.duration_ms, "audioProfile": artifact.audio_profile,
                    "voiceCode": voice, "manifestSha256": job.manifest_sha256,
                    "downloadPath": f"/v1/tts/jobs/{output_id}/audio",
                    "s3Key": self._object_key(output_id) if self.settings.output_s3_bucket else None,
                }
                pending = self.settings.output_dir / (output_id + ".json.tmp")
                pending.write_text(json.dumps(info, sort_keys=True), encoding="utf-8")
                pending.replace(self.settings.output_dir / (output_id + ".json"))
                LOG.info("standalone synthesis succeeded: id=%s sha256=%s", output_id, digest)
                return info
            finally:
                shutil.rmtree(work, ignore_errors=True)
        finally:
            self.busy.release()

    def _object_key(self, output_id: str) -> str:
        return "/".join(p for p in (self.settings.output_s3_prefix.strip("/"),
                                    output_id + ".mp3") if p)

    def _upload_s3(self, path: Path, output_id: str, sha256: str) -> None:
        import boto3
        if self._s3 is None:
            self._s3 = boto3.client("s3", endpoint_url=self.settings.s3_endpoint_url,
                                   region_name=self.settings.s3_region)
        with path.open("rb") as stream:
            self._s3.upload_fileobj(
                stream, self.settings.output_s3_bucket, self._object_key(output_id),
                ExtraArgs={"ContentType": "audio/mpeg", "Metadata": {"sha256": sha256}})

    def find(self, output_id: str):
        try:
            from uuid import UUID
            if str(UUID(output_id)) != output_id:
                return None
        except ValueError:
            return None
        meta = self.settings.output_dir / (output_id + ".json")
        media = self.settings.output_dir / (output_id + ".mp3")
        if not (meta.is_file() and media.is_file()) or meta.is_symlink() or media.is_symlink():
            return None
        data = json.loads(meta.read_text(encoding="utf-8"))
        if data["id"] != output_id or media.stat().st_size != data["sizeBytes"]:
            return None
        return data


def make_server(settings: StandaloneSettings, service: StandaloneService):
    class Handler(BaseHTTPRequestHandler):
        server_version = "KokoroStandalone/0.1"
        def log_message(self, format, *args):
            LOG.info("standalone HTTP: " + format, *args)

        def respond(self, status: int, obj: dict):
            data = json.dumps(obj, ensure_ascii=False).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("X-Content-Type-Options", "nosniff")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def authorized(self):
            value = self.headers.get("Authorization", "")
            if not hmac.compare_digest(value, "Bearer " + settings.token):
                self.respond(401, {"error": "Unauthorized"})
                return False
            return True

        def do_GET(self):
            path = urlsplit(self.path).path
            if path == "/health/live":
                return self.respond(200, {"status": "UP"})
            if not self.authorized():
                return
            if path == "/health/ready":
                return self.respond(200 if service.ready else 503,
                                    {"status": "READY" if service.ready else "NOT_READY"})
            parts = path.split("/")
            if len(parts) == 5 and parts[:4] == ["", "v1", "tts", "jobs"]:
                data = service.find(parts[4])
                return self.respond(200, data) if data else self.respond(404, {"error": "Not found"})
            if len(parts) == 6 and parts[:4] == ["", "v1", "tts", "jobs"] and parts[5] == "audio":
                data = service.find(parts[4])
                if data is None:
                    return self.respond(404, {"error": "Not found"})
                media = service.settings.output_dir / (parts[4] + ".mp3")
                self.send_response(200)
                self.send_header("Content-Type", "audio/mpeg")
                self.send_header("Content-Length", str(data["sizeBytes"]))
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                with media.open("rb") as f:
                    while block := f.read(64 * 1024):
                        self.wfile.write(block)
                return
            self.respond(404, {"error": "Not found"})

        def do_POST(self):
            if urlsplit(self.path).path != "/v1/tts/jobs":
                return self.respond(404, {"error": "Not found"})
            if not self.authorized():
                return
            if not service.ready:
                return self.respond(503, {"error": "Model not ready"})
            try:
                size = int(self.headers.get("Content-Length", "0"))
            except ValueError:
                return self.respond(400, {"error": "Invalid Content-Length"})
            if not 0 < size <= MAX_BODY or self.headers.get("Content-Type", "").split(";")[0] != "application/json":
                return self.respond(413, {"error": "Invalid request size or media type"})
            try:
                data = json.loads(self.rfile.read(size))
                result = service.synthesize(data)
            except (ValueError, TypeError, json.JSONDecodeError):
                return self.respond(400, {"error": "Invalid synthesis request"})
            except RuntimeError as exc:
                if str(exc) == "Worker busy":
                    return self.respond(429, {"error": "Worker busy"})
                LOG.exception("Standalone job failed")
                return self.respond(503, {"error": "Synthesis unavailable"})
            except Exception:
                LOG.exception("Standalone job failed")
                return self.respond(503, {"error": "Synthesis unavailable"})
            self.respond(201, result)

    class Server(ThreadingHTTPServer):
        daemon_threads = True
        request_queue_size = 8

    return Server((settings.host, settings.port), Handler)


def main() -> int:
    logging.basicConfig(level=logging.INFO)
    try:
        settings = StandaloneSettings.from_env()
        service = StandaloneService(settings)
        service.startup()
    except Exception:
        LOG.exception("Kokoro standalone initialization failed")
        return 2
    server = make_server(settings, service)
    def stop(*_):
        threading.Thread(target=server.shutdown, daemon=True).start()
    signal.signal(signal.SIGINT, stop)
    signal.signal(signal.SIGTERM, stop)
    try:
        server.serve_forever(poll_interval=0.25)
    finally:
        service.ready = False
        server.server_close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
