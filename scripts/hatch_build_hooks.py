"""Hatch build hook that stages the whole kiss asset tree before packaging.

The hook runs before hatchling collects files, and performs two jobs:

1. **Sync** — mirror the authoritative asset directories at the repo root
   (``agent-skills/``, ``subagents/``, ``presets/``, ``extensions/``,
   ``workflows/``, ``integrations/catalog.json``) into ``build/core_pack/``
   so the wheel carries the whole project, not just a curated subset.
2. **Checksum** — regenerate ``sha256sums.txt`` for the freshly-staged
   tree so runtime integrity verification matches what shipped.

Only the sync+checksum pair lives here; actual packaging is handled by
hatchling, which maps ``build/core_pack/`` to ``kiss_cli/core_pack/``
inside the wheel via ``[tool.hatch.build.targets.wheel.force-include]``
in ``pyproject.toml``.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from hatchling.builders.hooks.plugin.interface import BuildHookInterface


# Mapping of <repo-root source> -> <core_pack destination>. Directories
# are mirrored recursively; individual files are copied verbatim. Keep
# this list in sync with the runtime loaders in
# ``src/kiss_cli/installer.py`` (``_locate_core_pack`` and friends).
ASSET_MAP: list[tuple[str, str]] = [
    # Per-skill bundles (command prompt + scripts + templates in a
    # single self-contained folder per skill).
    ("agent-skills", "agent-skills"),
    # User-facing custom agents (subagents) deployed to every installed
    # integration's subagents folder during `kiss init`.
    ("subagents", "subagents"),
    # Every preset plus its catalog
    ("presets", "presets"),
    # Every extension plus its catalog
    ("extensions", "extensions"),
    # Every workflow plus its catalog
    ("workflows", "workflows"),
    # Integrations catalog (the agent Python code already ships via
    # packages=["src/kiss_cli"], so only metadata belongs here).
    ("integrations/catalog.json", "integrations/catalog.json"),
]

# Files to skip while mirroring — build junk and developer-only docs.
EXCLUDE_NAMES = {
    ".DS_Store",
    "__pycache__",
    ".pytest_cache",
}
EXCLUDE_SUFFIXES = {".pyc", ".pyo"}

# Name prefixes to skip — underscore-prefixed directories are treated
# as developer-only scaffolding (e.g. agent-skills/_template/ is the
# canonical role-skill template, not a shipped skill).
EXCLUDE_PREFIXES = ("_",)


def _should_copy(path: Path) -> bool:
    if path.name in EXCLUDE_NAMES:
        return False
    if any(path.name.startswith(p) for p in EXCLUDE_PREFIXES):
        return False
    if path.suffix in EXCLUDE_SUFFIXES:
        return False
    return True


def _sync_tree(src: Path, dst: Path) -> int:
    """Copy ``src`` into ``dst`` recursively, returning the file count."""
    if src.is_file():
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        return 1

    count = 0
    for entry in sorted(src.rglob("*")):
        rel_parts = entry.relative_to(src).parts
        if any(part in EXCLUDE_NAMES for part in rel_parts):
            continue
        if any(
            part.startswith(prefix)
            for part in rel_parts
            for prefix in EXCLUDE_PREFIXES
        ):
            continue
        if not _should_copy(entry):
            continue
        target = dst / entry.relative_to(src)
        if entry.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(entry, target)
        count += 1
    return count


class CustomBuildHook(BuildHookInterface):
    """Stage repo-root assets into core_pack/ then compute checksums."""

    def initialize(self, version, build_data):
        repo_root = Path(self.root)
        core_pack_root = repo_root / "build" / "core_pack"

        # Start from a clean slate so removed assets do not linger in the
        # wheel. Re-create immediately afterwards.
        if core_pack_root.exists():
            shutil.rmtree(core_pack_root)
        core_pack_root.mkdir(parents=True)

        total = 0
        for source_rel, dest_rel in ASSET_MAP:
            source = repo_root / source_rel
            if not source.exists():
                print(
                    f"[hatch-build] skipping missing asset: {source_rel}",
                    file=sys.stdout,
                )
                continue
            total += _sync_tree(source, core_pack_root / dest_rel)
        print(f"[hatch-build] staged {total} asset files into core_pack/")

        generate_script = repo_root / "scripts" / "generate-checksums.py"
        try:
            result = subprocess.run(
                [sys.executable, str(generate_script)],
                cwd=str(repo_root),
                capture_output=True,
                text=True,
                check=True,
            )
            print(f"[hatch-build] {result.stdout.strip()}", file=sys.stdout)
        except subprocess.CalledProcessError as e:
            print(
                f"[hatch-build ERROR] Failed to generate checksums:\n{e.stderr}",
                file=sys.stderr,
            )
            raise RuntimeError("Asset checksum generation failed") from e
