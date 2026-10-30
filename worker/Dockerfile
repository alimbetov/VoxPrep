FROM python:3.12-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MODEL_CACHE_DIR=/var/lib/voxprep/tts/models \
    TEMP_DIR=/tmp/voxprep-tts

WORKDIR /app

COPY pyproject.toml ./
COPY src ./src

RUN pip install --no-cache-dir . \
    && mkdir -p "${MODEL_CACHE_DIR}" "${TEMP_DIR}"

VOLUME ["/var/lib/voxprep/tts/models"]

ENTRYPOINT ["voxprep-tts-worker"]
