#!/usr/bin/env python3
"""
Generate SHA-256 checksums for bundled assets in core_pack.

Walks the bundled asset tree at build/core_pack/ and emits
build/core_pack/sha256sums.txt with one <hash>  <relative-path>
line per file. The hash and path are separated by two spaces. Paths are
relative to core_pack/ and use forward slashes only.

This script is idempotent and deterministic — lines are sorted alphabetically
by path, and the sha256sums.txt file itself is excluded from checksums.
"""

import sys
import hashlib
from pathlib import Path


def compute_file_hash(path: Path) -> str:
    """Compute SHA-256 hash of a file, reading in 64KB chunks."""
    hasher = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(65536)  # 64 KB chunks
            if not chunk:
                break
            hasher.update(chunk)
    return hasher.hexdigest()


def generate_checksums(core_pack_root: Path) -> None:
    """
    Walk the core_pack directory and generate sha256sums.txt.

    Args:
        core_pack_root: Absolute path to the core_pack directory.

    Raises:
        SystemExit: If core_pack_root does not exist or is not a directory.
    """
    if not core_pack_root.is_dir():
        print(f"[error] core_pack directory not found: {core_pack_root}", file=sys.stderr)
        sys.exit(1)

    # Collect all files (excluding sha256sums.txt itself)
    file_hashes: dict[str, str] = {}
    sums_file = core_pack_root / "sha256sums.txt"

    for file_path in sorted(core_pack_root.rglob("*")):
        if not file_path.is_file():
            continue
        if file_path == sums_file:
            continue

        rel_path = file_path.relative_to(core_pack_root)
        # Normalize to POSIX-style paths (forward slashes)
        rel_path_str = rel_path.as_posix()
        file_hash = compute_file_hash(file_path)
        file_hashes[rel_path_str] = file_hash

    # Write sha256sums.txt with sorted lines
    lines = [
        f"{file_hash}  {rel_path}"
        for rel_path, file_hash in sorted(file_hashes.items())
    ]

    sums_file.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {len(lines)} checksums in {sums_file}")


def main():
    """Main entry point for the script."""
    # Determine the core_pack directory
    # Run from repo root: python scripts/generate-checksums.py
    repo_root = Path(__file__).parent.parent
    core_pack_root = repo_root / "build" / "core_pack"

    generate_checksums(core_pack_root)


if __name__ == "__main__":
    main()
