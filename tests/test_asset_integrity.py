"""Tests for asset integrity verification."""

import pytest
import tempfile
import shutil
from pathlib import Path

from kiss_cli._integrity import (
    AssetCorruptionError,
    verify_asset_integrity,
)


@pytest.fixture
def temp_dir():
    """Create a temporary directory for tests."""
    tmpdir = tempfile.mkdtemp()
    yield Path(tmpdir)
    shutil.rmtree(tmpdir)


@pytest.fixture
def core_pack_with_sums(temp_dir):
    """Create a core_pack directory with sample files and checksums.

    Returns:
        Path to the core_pack directory.
    """
    core_pack = temp_dir / "core_pack"
    core_pack.mkdir()

    # Create some sample files
    (core_pack / "file1.txt").write_text("hello world")
    (core_pack / "file2.txt").write_text("goodbye world")

    subdir = core_pack / "subdir"
    subdir.mkdir()
    (subdir / "nested.txt").write_text("nested content")

    # Create a correct sha256sums.txt
    sums = [
        "5eb63bbbe01eeed093cb22bb8f5acdc3  file1.txt",
        "6c743e8a5ba5e28f8f5e13d8f4d2c8a5  file2.txt",
        "a8e7f3e5c2b1a9d4f6c3e1b8a9d4f6c3  subdir/nested.txt",
    ]

    # Compute actual hashes
    import hashlib

    def sha256_file(path):
        h = hashlib.sha256()
        with open(path, "rb") as f:
            h.update(f.read())
        return h.hexdigest()

    sums = [
        f"{sha256_file(core_pack / 'file1.txt')}  file1.txt",
        f"{sha256_file(core_pack / 'file2.txt')}  file2.txt",
        f"{sha256_file(subdir / 'nested.txt')}  subdir/nested.txt",
    ]

    (core_pack / "sha256sums.txt").write_text("\n".join(sums) + "\n")

    return core_pack


def test_sha256sums_present_in_package():
    """Assert sha256sums.txt exists in the installed package.

    ``kiss_cli/core_pack/`` is a build-time staging directory populated
    by ``scripts/hatch_build_hooks.py`` and only exists in built wheels —
    skip when running from a source checkout.
    """
    import importlib.resources

    try:
        sums_file = importlib.resources.files("kiss_cli").joinpath(
            "core_pack", "sha256sums.txt"
        )
        content = sums_file.read_text(encoding="utf-8")
        assert len(content) > 0, "sha256sums.txt exists but is empty"
    except (FileNotFoundError, AttributeError, ModuleNotFoundError):
        pytest.skip("sha256sums.txt not present in installed package (expected in wheel build)")


def test_verify_asset_integrity_passes_on_fresh_tree(core_pack_with_sums):
    """Test that verification passes when all files are intact."""
    # Should not raise
    verify_asset_integrity(core_pack_with_sums)


def test_verify_asset_integrity_raises_on_missing_sums(temp_dir):
    """Test that verification raises when sha256sums.txt is missing."""
    core_pack = temp_dir / "core_pack"
    core_pack.mkdir()
    (core_pack / "file.txt").write_text("content")

    with pytest.raises(AssetCorruptionError, match="sha256sums.txt missing"):
        verify_asset_integrity(core_pack)


def test_verify_asset_integrity_raises_on_missing_file(core_pack_with_sums):
    """Test that verification raises when a referenced file is missing."""
    # Remove one of the files
    (core_pack_with_sums / "file1.txt").unlink()

    with pytest.raises(AssetCorruptionError, match="file1.txt"):
        verify_asset_integrity(core_pack_with_sums)


def test_verify_asset_integrity_raises_on_corrupted_file(core_pack_with_sums):
    """Test that verification raises when a file's hash mismatches."""
    # Corrupt one of the files
    (core_pack_with_sums / "file1.txt").write_text("corrupted content")

    with pytest.raises(AssetCorruptionError, match="file1.txt"):
        verify_asset_integrity(core_pack_with_sums)


def test_verify_asset_integrity_allows_extra_files(core_pack_with_sums):
    """Test that verification ignores extra files not in sums."""
    # Add a file that's not in sha256sums.txt
    (core_pack_with_sums / "extra.txt").write_text("extra content")

    # Should not raise — extra files are allowed
    verify_asset_integrity(core_pack_with_sums)


def test_verify_asset_integrity_error_message(core_pack_with_sums):
    """Test the error message format."""
    (core_pack_with_sums / "file2.txt").write_text("modified")

    try:
        verify_asset_integrity(core_pack_with_sums)
        pytest.fail("Expected AssetCorruptionError")
    except AssetCorruptionError as e:
        assert "file2.txt" in str(e)
        assert e.asset_path == "file2.txt"


def test_verify_asset_integrity_with_empty_lines(core_pack_with_sums):
    """Test that verification handles empty lines in sums file."""
    # Add empty lines to the sums file
    sums_content = (core_pack_with_sums / "sha256sums.txt").read_text()
    sums_content = "\n".join(sums_content.strip().split("\n")[:2]) + "\n\n" + "\n".join(
        sums_content.strip().split("\n")[2:]
    ) + "\n"
    (core_pack_with_sums / "sha256sums.txt").write_text(sums_content)

    # Should not raise
    verify_asset_integrity(core_pack_with_sums)
