from __future__ import annotations

import re
from voxprep_kokoro_worker.domain.errors import SynthesisError

MAX_TEXT_CHARS = 12000
MAX_CHUNK_CHARS = 400
MAX_CHUNKS = 128


def split_text(text: str, limit: int = MAX_CHUNK_CHARS) -> list[str]:
    if not isinstance(text, str) or not text.strip() or len(text) > MAX_TEXT_CHARS:
        raise SynthesisError('Empty or oversized Kokoro job text')
    if not 1 <= limit <= 500:
        raise ValueError('Invalid inference chunk limit')
    words = text.split()
    if not words or any(len(word) > limit for word in words):
        raise SynthesisError('Unbreakable token exceeds inference limit')
    chunks = []
    current = ''
    for word in words:
        candidate = current + ' ' + word if current else word
        if len(candidate) > limit:
            chunks.append(current)
            current = word
        else:
            current = candidate
        if len(chunks) >= MAX_CHUNKS:
            raise SynthesisError('Too many Kokoro inference chunks')
    if current:
        chunks.append(current)
    if len(chunks) > MAX_CHUNKS:
        raise SynthesisError('Too many Kokoro inference chunks')
    return chunks
