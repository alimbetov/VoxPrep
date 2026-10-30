from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


@dataclass(frozen=True, slots=True)
class ClaimedJob:
    job_id: str
    file_id: str
    content_revision_id: str
    audio_role: str
    normalized_tts_text: str
    language: str
    voice_model_id: str
    voice_model_code: str
    model_sha256: str
    config_sha256: str
    fingerprint: str
    lease_token: str
    lease_until: datetime


@dataclass(frozen=True, slots=True)
class AudioArtifact:
    path: Path
    content_type: str
    audio_profile: str
    sha256: str
    size_bytes: int
    duration_ms: int | None = None
