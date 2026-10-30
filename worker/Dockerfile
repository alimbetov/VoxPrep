FROM python:3.12.16-slim-bookworm@sha256:e697c81897302a4c4333bade000d98038fbb21eb064f8ee1fd42d02ebcd9d337

ARG PIP_VERSION=26.2.2
ARG FFMPEG_DEBIAN_VERSION=7:5.1.9-0+deb12u1
ARG WORKER_UID=10001
ARG WORKER_GID=10001

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    MODEL_CACHE_DIR=/var/lib/voxprep/tts/models \
    TEMP_DIR=/tmp/voxprep-tts

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       "ffmpeg=${FFMPEG_DEBIAN_VERSION}" \
    && rm -rf /var/lib/apt/lists/* \
    && ffmpeg -version \
    && ffprobe -version

COPY pyproject.toml constraints.txt ./
COPY src ./src

RUN python -m pip install --no-cache-dir "pip==${PIP_VERSION}" \
    && python -m pip install --no-cache-dir -c constraints.txt . \
    && python -m pip check \
    && python -m pip show piper-tts | grep -F "Version: 1.4.2" \
    && python -c "import onnxruntime, piper; assert onnxruntime.__version__ == '1.31.1'; print('piper runtime import ok')" \
    && mkdir -p "${MODEL_CACHE_DIR}" "${TEMP_DIR}" \
    && chown -R "${WORKER_UID}:${WORKER_GID}" /var/lib/voxprep "${TEMP_DIR}"

VOLUME ["/var/lib/voxprep/tts/models"]

USER ${WORKER_UID}:${WORKER_GID}

ENTRYPOINT ["voxprep-tts-worker"]
