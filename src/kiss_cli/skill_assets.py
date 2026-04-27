"""Per-skill asset bundling.

The source-of-truth layout for every kiss skill lives under
``agent-skills/<name>/``::

    agent-skills/
    └── specify/
        ├── specify.md                         # command prompt source
        ├── scripts/bash/{create-new-feature,common}.sh
        ├── scripts/powershell/{create-new-feature,common}.ps1
        └── templates/spec-template.md

Each folder is a self-contained install unit: the command file is
processed through the integration-specific pipeline (frontmatter
rewrite, placeholder replacement) and everything else (``scripts/`` and
``templates/``) is copied verbatim alongside it into the installed
skill folder.

This module resolves the ``agent-skills/`` root (either the bundled
``core_pack/agent-skills/`` in a wheel install or the checked-out
source tree) and copies each skill's assets next to its SKILL.md or
flat command file at install time.
"""

from __future__ import annotations

import inspect
import shutil
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .integrations.manifest import IntegrationManifest


def agent_skills_root() -> Path | None:
    """Locate the bundled ``agent-skills/`` directory.

    Checks the wheel's ``core_pack/agent-skills/`` first, then the
    top-level ``agent-skills/`` in the source checkout. Returns
    ``None`` if neither exists.
    """
    from .integrations.base import IntegrationBase

    pkg_dir = Path(inspect.getfile(IntegrationBase)).resolve().parent.parent
    for candidate in [
        pkg_dir / "core_pack" / "agent-skills",
        pkg_dir.parent.parent / "agent-skills",
    ]:
        if candidate.is_dir():
            return candidate
    return None


def list_skill_dirs() -> list[Path]:
    """Return the list of per-skill source folders under ``agent-skills/``.

    Sorted alphabetically so install order is deterministic. Folders
    whose name starts with ``_`` are developer scaffolding (e.g.
    ``_template``) and are excluded — matching the build hook that
    keeps them out of the installer wheel.
    """
    root = agent_skills_root()
    if root is None:
        return []
    return sorted(d for d in root.iterdir() if d.is_dir() and not d.name.startswith("_"))


def skill_command_file(skill_dir: Path) -> Path | None:
    """Return the command prompt file for a skill folder.

    Convention: ``agent-skills/<name>/<name>.md``. Returns ``None`` if
    it doesn't exist (e.g. a partially-authored skill).
    """
    candidate = skill_dir / f"{skill_dir.name}.md"
    return candidate if candidate.is_file() else None


def bundle_skill_assets(
    install_folder: Path,
    skill_name: str,
    project_root: Path,
    manifest: "IntegrationManifest",
) -> list[Path]:
    """Copy a skill's ``scripts/`` and ``templates/`` into its install folder.

    The source is ``agent-skills/<skill_name>/`` (everything except the
    top-level ``<skill_name>.md`` which is handled separately by the
    integration's setup code). Recursively mirrors both subfolders so
    each installed skill carries its own copies.

    Args:
        install_folder: Absolute directory the skill is being installed
            into (e.g. ``.claude/skills/kiss-specify/`` or
            ``.windsurf/workflows/kiss.specify/``).
        skill_name: Short skill name — the folder name under
            ``agent-skills/`` (e.g. ``specify``, ``plan``).
        project_root: Project root — used to record manifest-relative
            paths.
        manifest: Integration manifest to record written files in.

    Returns the list of files that were copied.
    """
    root = agent_skills_root()
    if root is None:
        return []
    src = root / skill_name
    if not src.is_dir():
        return []

    written: list[Path] = []
    for subdir in ("scripts", "templates"):
        sub_src = src / subdir
        if not sub_src.is_dir():
            continue
        for entry in sub_src.rglob("*"):
            if not entry.is_file():
                continue
            if "__pycache__" in entry.parts:
                continue
            rel = entry.relative_to(src)
            dst = install_folder / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(entry, dst)
            manifest.record_existing(dst.relative_to(project_root).as_posix())
            written.append(dst)

    return written
