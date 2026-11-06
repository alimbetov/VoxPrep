# K2 development image. Runtime/phonemizer compatibility and pinned OCI digest
# must be qualified on native ARM64 + AMD64 before publication.
FROM python:3.12.16-slim-bookworm
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 \
    MODEL_CACHE_DIR=/var/lib/voxprep/kokoro/models \
    TEMP_DIR=/tmp/voxprep-kokoro
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg espeak-ng libsndfile1 && rm -rf /var/lib/apt/lists/*
COPY pyproject.toml ./
COPY src ./src
RUN python -m pip install --no-cache-dir . \
    && useradd -r -u 10002 -m kokoro \
    && mkdir -p "$MODEL_CACHE_DIR" "$TEMP_DIR" \
    && chown -R kokoro:kokoro /var/lib/voxprep/kokoro "$TEMP_DIR"
USER kokoro
ENTRYPOINT ["voxprep-kokoro-worker"]
