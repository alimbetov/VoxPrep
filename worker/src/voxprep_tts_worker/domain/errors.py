from __future__ import annotations


class WorkerError(RuntimeError):
    code = "WORKER_ERROR"


class BackendError(WorkerError):
    code = "BACKEND_ERROR"


class BackendAuthenticationError(BackendError):
    code = "WORKER_AUTH_FAILED"


class BackendTransportError(BackendError):
    code = "BACKEND_TEMPORARILY_UNAVAILABLE"


class BackendProtocolError(BackendError):
    code = "INVALID_BACKEND_RESPONSE"


class ModelUnavailableError(WorkerError):
    code = "VOICE_MODEL_NOT_FOUND"


class ModelDownloadError(WorkerError):
    code = "VOICE_MODEL_DOWNLOAD_FAILED"


class ModelChecksumError(WorkerError):
    code = "VOICE_MODEL_CHECKSUM_MISMATCH"


class ModelCacheInstallError(WorkerError):
    code = "VOICE_MODEL_CACHE_INSTALL_FAILED"


class ModelLoadError(WorkerError):
    code = "VOICE_MODEL_LOAD_FAILED"


class SynthesisError(WorkerError):
    code = "PIPER_SYNTHESIS_FAILED"


class PostprocessError(WorkerError):
    code = "FFMPEG_FAILED"


class AudioQcError(WorkerError):
    code = "AUDIO_QC_FAILED"


class LeaseLostError(WorkerError):
    code = "LEASE_LOST"
