"""Prepare an immutable four-artifact manifest from reviewed model files.

The manifest is local configuration. It does not assert that any HF revision
was independently verified; operators must provide the real 40-hex upstream
commit and independently review redistribution rights.
"""
from __future__ import annotations

import argparse
import json
import re
import uuid
from pathlib import Path

from voxprep_kokoro_worker.adapters.model_cache import canonical_hash, file_hash
from voxprep_kokoro_worker.adapters.voice_bundle import SUPPORTED_VOICES

_REV = re.compile(r"^[0-9a-fA-F]{40}$")


def create_manifest(source: Path, model_code: str, revision: str) -> dict:
    if not _REV.fullmatch(revision):
        raise ValueError("Source revision must be a pinned 40-hex commit")
    if not re.fullmatch(r"[A-Za-z0-9_.-]{3,120}", model_code):
        raise ValueError("Invalid model code")
    names = ["onnx/model_quantized.onnx"] + [
        "voices/" + voice + ".bin" for voice in SUPPORTED_VOICES
    ]
    entries = []
    for name in names:
        file = source / name
        if not file.is_file() or file.is_symlink() or not file.resolve().is_relative_to(source.resolve()):
            raise ValueError("Missing or unsafe artifact: " + name)
        size = file.stat().st_size
        if not 0 < size <= 256 * 1024 * 1024:
            raise ValueError("Artifact size outside supported limits: " + name)
        digest = file_hash(file)
        entries.append({
            "assetId": str(uuid.uuid5(uuid.NAMESPACE_URL, model_code + "/" + revision + "/" + name + "/" + digest)),
            "path": name, "role": "MODEL" if name.startswith("onnx/") else "VOICE",
            "sha256": digest, "sizeBytes": size,
            "mediaType": "application/octet-stream",
        })
    return {
        "modelCode": model_code,
        "sourceRevision": revision,
        "manifestSha256": canonical_hash("KOKORO", revision, entries),
        "artifacts": entries,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Write pinned Kokoro manifest from reviewed files")
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--model-code", required=True)
    parser.add_argument("--revision", required=True, help="full upstream 40-hex commit")
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.output.is_symlink():
        parser.error("Output must not be a symlink")
    manifest = create_manifest(args.source, args.model_code, args.revision)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_name(args.output.name + ".tmp")
    temporary.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    temporary.replace(args.output)
    print("Pinned Kokoro manifest:", manifest["manifestSha256"])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
