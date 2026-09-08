#!/usr/bin/env python3
"""Verify a provisioned Hermes cache and copy it into Android assets.

This script is deliberately offline: it has no download path. A missing or
unfixed digest is an error, rather than an opportunity to fetch a replacement.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import re
from pathlib import Path

SHA256 = 64
PLACEHOLDER_WORDS = ("LOCKED_", "TODO", "PLACEHOLDER", "REPLACE", "CHANGEME")


def digest(path: Path) -> str:
    if path.is_file():
        h = hashlib.sha256()
        with path.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                h.update(chunk)
        return h.hexdigest()
    if path.is_dir():
        h = hashlib.sha256()
        for child in sorted(p for p in path.rglob("*") if p.is_file()):
            h.update(str(child.relative_to(path)).encode())
            h.update(digest(child).encode())
        return h.hexdigest()
    raise ValueError(f"artifact is not a file or directory: {path}")


def require_sha(value: object, label: str) -> str:
    if not isinstance(value, str) or len(value) != SHA256:
        raise ValueError(f"{label} must contain a 64-character SHA-256 digest")
    lowered = value.lower()
    if lowered != value or any(word.lower() in lowered for word in PLACEHOLDER_WORDS):
        raise ValueError(f"{label} contains an unfixed or placeholder digest")
    if any(ch not in "0123456789abcdef" for ch in value) or len(set(value)) == 1:
        raise ValueError(f"{label} contains an invalid or placeholder digest")
    return value


def validate_lock_values(value: object, label: str) -> None:
    if isinstance(value, dict):
        for key, child in value.items():
            child_label = f"{label}.{key}"
            if key == "sha256":
                require_sha(child, child_label)
            elif isinstance(child, str) and any(word.lower() in child.lower() for word in PLACEHOLDER_WORDS):
                raise ValueError(f"{child_label} contains an unfixed value")
            validate_lock_values(child, child_label)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            validate_lock_values(child, f"{label}[{index}]")


def safe_relative(value: object, label: str) -> Path:
    if not isinstance(value, str):
        raise ValueError(f"{label} must be a relative path")
    path = Path(value)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError(f"{label} escapes its root: {value}")
    return path


def validate_requirements(path: Path) -> None:
    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if "LOCKED_" in line or "TODO" in line or "PLACEHOLDER" in line:
            raise ValueError(f"{path}:{line_number} contains an unfixed dependency")
        for value in re.findall(r"--hash=sha256:([0-9a-f]{64})", line):
            require_sha(value, f"{path}:{line_number}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True, help="pre-provisioned offline cache")
    parser.add_argument("--output", type=Path, required=True, help="Android assets destination")
    parser.add_argument("--manifest", type=Path, default=Path(__file__).with_name("manifest.json"))
    parser.add_argument(
        "--requirements",
        type=Path,
        default=Path(__file__).with_name("requirements-aarch64.lock"),
    )
    parser.add_argument(
        "--licenses",
        type=Path,
        default=Path(__file__).with_name("LICENSES.txt"),
    )
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    validate_lock_values(manifest, "manifest")
    validate_requirements(args.requirements)
    artifacts = manifest.get("artifacts")
    if not isinstance(artifacts, list) or not artifacts:
        raise ValueError("manifest must define artifacts")
    for index, artifact in enumerate(artifacts):
        label = f"artifacts[{index}]"
        require_sha(artifact.get("sha256"), f"{label}.sha256")
        source = args.input / safe_relative(artifact.get("source"), f"{label}.source")
        target = args.output / safe_relative(artifact.get("target"), f"{label}.target")
        if not source.exists():
            raise FileNotFoundError(f"missing provisioned Hermes artifact: {source}")
        actual = digest(source)
        if actual != artifact["sha256"]:
            raise ValueError(f"hash mismatch for {artifact['name']}: {actual} != {artifact['sha256']}")
        target.parent.mkdir(parents=True, exist_ok=True)
        if source.is_dir():
            if target.exists():
                shutil.rmtree(target)
            shutil.copytree(source, target)
        else:
            shutil.copy2(source, target)
        if artifact["name"] == "proot":
            target.chmod(target.stat().st_mode | 0o111)
    shutil.copy2(args.manifest, args.output / "hermes/runtime.json")
    shutil.copy2(args.requirements, args.output / "hermes/requirements-aarch64.lock")
    shutil.copy2(args.licenses, args.output / "hermes/LICENSES.txt")


if __name__ == "__main__":
    main()
