"""Structural tests for role-skill bundles and the scaffolding template.

Covers Phase 0 of the subagents / skills refactor: every
``agent-skills/kiss-*/`` bundle (and the developer-only
``agent-skills/_template/``) must carry:

- the command-prompt markdown file named after the folder
- ``scripts/bash/`` with ``common.sh`` and at least one action
- ``scripts/powershell/`` with ``common.ps1`` and at least one action
- one-to-one Bash/PowerShell action parity
- all action scripts must source the shared helpers

These are static structural checks — they don't execute any shell.
See ``test_skill_common_helpers.py`` for runtime behaviour.
"""

from __future__ import annotations

import re
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[1]
SKILLS_DIR = REPO_ROOT / "agent-skills"
TEMPLATE_DIR = SKILLS_DIR / "_template"


def _discover_all_skill_dirs() -> list[Path]:
    """Every ``agent-skills/*`` subdirectory that looks like a bundle.

    Includes ``_template/`` because the layout rules apply to it too
    (it's the canonical shape every new skill copies).
    """
    if not SKILLS_DIR.exists():
        return []
    return sorted(p for p in SKILLS_DIR.iterdir() if p.is_dir())


def _action_stem(path: Path) -> str:
    return path.stem


class TestTemplateExists:
    """The developer-only _template/ bundle must be present + complete."""

    def test_template_dir_exists(self):
        assert TEMPLATE_DIR.is_dir(), (
            f"Expected canonical template at {TEMPLATE_DIR}"
        )

    def test_template_has_prompt(self):
        assert (TEMPLATE_DIR / "_template.md").is_file()

    def test_template_has_all_four_subtrees(self):
        for name in ("templates", "references", "assets", "scripts"):
            assert (TEMPLATE_DIR / name).is_dir(), (
                f"_template/ is missing '{name}/' — every new skill bundle "
                f"copies this layout"
            )

    def test_template_ships_both_shell_flavours(self):
        assert (TEMPLATE_DIR / "scripts" / "bash" / "common.sh").is_file()
        assert (TEMPLATE_DIR / "scripts" / "powershell" / "common.ps1").is_file()

    def test_template_has_sample_action_parity(self):
        bash = TEMPLATE_DIR / "scripts" / "bash" / "example-action.sh"
        ps = TEMPLATE_DIR / "scripts" / "powershell" / "example-action.ps1"
        assert bash.is_file(), "example-action.sh is missing"
        assert ps.is_file(), "example-action.ps1 is missing"


class TestBundleLayout:
    """Every bundle under agent-skills/ must follow the canonical layout."""

    @pytest.fixture(scope="class")
    def bundles(self) -> list[Path]:
        return _discover_all_skill_dirs()

    def test_at_least_the_template_and_existing_skills(self, bundles):
        # Sanity: repo ships 9 existing kiss-* skills + our _template.
        assert len(bundles) >= 10, (
            f"Expected >=10 bundles under agent-skills/, found {len(bundles)}"
        )

    def test_each_bundle_has_a_prompt_file(self, bundles):
        missing = [b.name for b in bundles if not (b / f"{b.name}.md").is_file()]
        assert not missing, (
            f"Bundles missing <folder>/<folder>.md command prompt: {missing}"
        )

    def test_scripts_dir_when_present_has_both_shell_flavours(self, bundles):
        """If a bundle ships any scripts, both Bash and PowerShell
        directories must exist. Markdown-only skills (e.g. the legacy
        ``kiss-standardize``) are exempt.
        """
        missing = []
        for b in bundles:
            scripts_dir = b / "scripts"
            if not scripts_dir.is_dir():
                continue
            bash_dir = scripts_dir / "bash"
            ps_dir = scripts_dir / "powershell"
            if not bash_dir.is_dir():
                missing.append(f"{b.name} (scripts/bash/)")
            if not ps_dir.is_dir():
                missing.append(f"{b.name} (scripts/powershell/)")
        assert not missing, (
            f"Bundles with scripts/ must ship both Bash and PowerShell: "
            f"{missing}"
        )

    def test_bash_and_powershell_actions_are_paired(self, bundles):
        """For every .sh action there should be a matching .ps1 of the
        same stem, and vice versa. ``common.sh`` / ``common.ps1`` are
        exempted because they are helpers, not actions.
        """
        mismatches = {}
        for b in bundles:
            bash_dir = b / "scripts" / "bash"
            ps_dir = b / "scripts" / "powershell"
            if not bash_dir.is_dir() or not ps_dir.is_dir():
                continue
            bash_stems = {
                _action_stem(p) for p in bash_dir.iterdir()
                if p.suffix == ".sh" and p.stem != "common"
            }
            ps_stems = {
                _action_stem(p) for p in ps_dir.iterdir()
                if p.suffix == ".ps1" and p.stem != "common"
            }
            diff = bash_stems.symmetric_difference(ps_stems)
            if diff:
                mismatches[b.name] = sorted(diff)
        assert not mismatches, (
            f"Bash/PowerShell action parity mismatch: {mismatches}"
        )


class TestBundleCommonSourcing:
    """Action scripts must source the shared helper library."""

    @pytest.fixture(scope="class")
    def bundles(self) -> list[Path]:
        return _discover_all_skill_dirs()

    def test_every_bash_action_sources_common_sh(self, bundles):
        offenders = []
        for b in bundles:
            bash_dir = b / "scripts" / "bash"
            if not bash_dir.is_dir():
                continue
            for script in bash_dir.iterdir():
                if script.suffix != ".sh":
                    continue
                if script.stem == "common":
                    continue
                text = script.read_text()
                # Accept either "source common.sh" or "source <...>/common.sh".
                if not re.search(r"(^|\s)(\.|source)\s+.*common\.sh", text, re.M):
                    offenders.append(f"{b.name}/{script.name}")
        assert not offenders, (
            f"Bash action scripts that don't source common.sh: {offenders}"
        )

    def test_every_powershell_action_dot_sources_common_ps1(self, bundles):
        offenders = []
        for b in bundles:
            ps_dir = b / "scripts" / "powershell"
            if not ps_dir.is_dir():
                continue
            for script in ps_dir.iterdir():
                if script.suffix != ".ps1":
                    continue
                if script.stem == "common":
                    continue
                text = script.read_text()
                # Accept "common.ps1" via dot-source or Import-Module.
                if "common.ps1" not in text:
                    offenders.append(f"{b.name}/{script.name}")
        assert not offenders, (
            f"PowerShell action scripts that don't reference common.ps1: "
            f"{offenders}"
        )
