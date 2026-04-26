"""Asset integrity verification for kiss core_pack bundles.

Provides functions to verify the integrity of bundled assets using
pre-computed SHA-256 checksums stored in sha256sums.txt.
"""

import hashlib
from pathlib import Path


class AssetCorruptionError(RuntimeError):
    """Raised when a bundled asset fails integrity verification.

    Attributes:
        asset_path: Relative path (within core_pack) of the corrupted file,
                    or 'sha256sums.txt missing' if the checksum file itself is missing.
    """

    def __init__(self, asset_path: str):
        self.asset_path = asset_path
        super().__init__(f"Asset integrity check failed: {asset_path}")


def verify_asset_integrity(core_pack_root: Path) -> None:
    """Verify SHA-256 checksums of all bundled assets.

    Reads sha256sums.txt and computes live hashes for each listed file.
    Treats the checksums file as the source of truth: only files listed
    in sha256sums.txt are verified.

    Args:
        core_pack_root: Absolute path to the core_pack directory.

    Raises:
        AssetCorruptionError: If any asset hash mismatches or if
                              sha256sums.txt is missing.
    """
    sums_file = core_pack_root / "sha256sums.txt"

    # Check that sha256sums.txt exists
    if not sums_file.exists():
        raise AssetCorruptionError("sha256sums.txt missing")

    # Read and parse the checksums file
    try:
        sums_text = sums_file.read_text(encoding="utf-8")
    except Exception as e:
        raise AssetCorruptionError(f"sha256sums.txt (failed to read: {e})") from e

    # Parse each line: <hash>  <relative-path>
    for line_num, line in enumerate(sums_text.splitlines(), start=1):
        line = line.strip()
        if not line:
            # Empty lines are allowed
            continue

        parts = line.split(None, 1)  # Split on whitespace, max 2 parts
        if len(parts) != 2:
            raise AssetCorruptionError(
                f"sha256sums.txt (malformed line {line_num}: {line!r})"
            )

        expected_hash, rel_path = parts

        # Compute the actual hash of the file
        abs_path = core_pack_root / rel_path
        if not abs_path.exists():
            raise AssetCorruptionError(rel_path)

        try:
            actual_hash = _compute_file_hash(abs_path)
        except Exception as e:
            raise AssetCorruptionError(
                f"{rel_path} (failed to read: {e})"
            ) from e

        # Compare hashes
        if actual_hash != expected_hash:
            raise AssetCorruptionError(rel_path)


def _compute_file_hash(path: Path) -> str:
    """Compute SHA-256 hash of a file, reading in 64KB chunks.

    Args:
        path: Absolute path to the file.

    Returns:
        Hexadecimal digest of the file's SHA-256 hash.
    """
    hasher = hashlib.sha256()
    with open(path, "rb") as f:
        while True:
            chunk = f.read(65536)  # 64 KB chunks
            if not chunk:
                break
            hasher.update(chunk)
    return hasher.hexdigest()
