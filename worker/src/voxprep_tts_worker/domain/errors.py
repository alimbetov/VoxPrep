from __future__ import annotations


class WorkerError(RuntimeError):
    code = "WORKER_ERROR"


class ModelUnavailableError(WorkerError):
    code = "VOICE_MODEL_NOT_FOUND"


class SynthesisError(WorkerError):
    code = "PIPER_SYNTHESIS_FAILED"


class PostprocessError(WorkerError):
    code = "FFMPEG_FAILED"


class AudioQcError(WorkerError):
    code = "AUDIO_QC_FAILED"


class LeaseLostError(WorkerError):
    code = "LEASE_LOST"
