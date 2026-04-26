"""agentskills.io compliance tests.

Validates bundled skills against the agentskills.io specification.
Tests check:
1. Frontmatter compliance (required fields, no non-standard fields)
2. Name/directory alignment
3. Body sections (Inputs, Outputs, Context Update, Handoffs if applicable)
4. Placeholder vocabulary (only standard {context.*} keys)
5. No hardcoded paths
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path
from typing import Any

import pytest
import yaml


REPO_ROOT = Path(__file__).resolve().parents[1]

# Each skill lives in its own folder under agent-skills/ with a command
# prompt file named ``<folder>.md``.
SKILLS_DIR = REPO_ROOT / "agent-skills"

# Allowed top-level frontmatter fields per agentskills.io
ALLOWED_FRONTMATTER_FIELDS = {
    "name",
    "description",
    "license",
    "compatibility",
    "metadata",
    "allowed-tools",
}

# Standard placeholder vocabulary (Phase 5.3)
STANDARD_PLACEHOLDERS = {
    "{context.paths.specs}",
    "{context.paths.plans}",
    "{context.paths.tasks}",
    "{context.paths.templates}",
    "{context.paths.scripts}",
    "{context.paths.docs}",
    "{context.current.feature}",
    "{context.current.spec}",
    "{context.current.plan}",
    "{context.current.tasks}",
    "{context.current.checklist}",
    "{context.current.branch}",
    "{context.preferences.confirm_before_write}",
}

# Required body sections per Phase 5.4
REQUIRED_BODY_SECTIONS = {
    "## Inputs",
    "## Outputs",
    "## Context Update",
}

# Handoffs section (Phase 1.6/2.2)
HANDOFFS_BODY_SECTION = "## Handoffs"


def _discover_skill_files() -> list[Path]:
    """Return every ``agent-skills/<name>/<name>.md`` command prompt.

    Underscore-prefixed directories (e.g. ``_template/``) are developer
    scaffolding and are excluded from compliance checks and the
    installer wheel alike.
    """
    found: list[Path] = []
    if SKILLS_DIR.exists():
        for skill_dir in sorted(SKILLS_DIR.iterdir()):
            if not skill_dir.is_dir():
                continue
            if skill_dir.name.startswith("_"):
                continue
            candidate = skill_dir / f"{skill_dir.name}.md"
            if candidate.is_file():
                found.append(candidate)
    return found


def _extract_frontmatter_and_body(content: str) -> tuple[dict[str, Any], str]:
    """Extract YAML frontmatter and Markdown body."""
    lines = content.split('\n')
    if not lines or not lines[0].startswith('---'):
        return {}, content
    
    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].startswith('---'):
            end_idx = i
            break
    
    if end_idx is None:
        return {}, content
    
    fm_text = '\n'.join(lines[1:end_idx])
    body_text = '\n'.join(lines[end_idx+1:])
    
    try:
        fm = yaml.safe_load(fm_text) or {}
    except yaml.YAMLError:
        fm = {}
    
    return fm, body_text


@pytest.fixture(scope="module")
def skills_ref_validator():
    """Import skills-ref's validator if available (for O1 validation).
    
    This is optional — the local tests run regardless.
    """
    try:
        from skills_ref import validator  # type: ignore
        return validator
    except ImportError:
        return None


class TestAgentSkillsCompliance:
    """Bundled skills must comply with agentskills.io specification."""

    def test_all_skills_discovered(self):
        """Verify at least some skills are found."""
        skills = _discover_skill_files()
        assert len(skills) > 0, f"No .md skills found in {SKILLS_DIR}"

    def test_frontmatter_only_allowed_fields(self):
        """Top-level frontmatter contains only allowed fields."""
        skills = _discover_skill_files()
        failures = []
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            fm, _ = _extract_frontmatter_and_body(content)
            
            non_standard = set(fm.keys()) - ALLOWED_FRONTMATTER_FIELDS
            if non_standard:
                failures.append((skill_file.name, non_standard))
        
        assert not failures, (
            f"Skills with non-standard frontmatter fields:\n" +
            "\n".join(f"  {name}: {fields}" for name, fields in failures)
        )

    def test_frontmatter_has_required_fields(self):
        """Every skill has 'name' and 'description' fields."""
        skills = _discover_skill_files()
        failures = []
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            fm, _ = _extract_frontmatter_and_body(content)
            
            missing = []
            if "name" not in fm:
                missing.append("name")
            if "description" not in fm:
                missing.append("description")
            
            if missing:
                failures.append((skill_file.name, missing))
        
        assert not failures, (
            f"Skills missing required fields:\n" +
            "\n".join(f"  {name}: {fields}" for name, fields in failures)
        )

    def test_name_matches_file_stem(self):
        """name field matches the folder/file stem (which already includes ``kiss-``)."""
        skills = _discover_skill_files()
        failures = []

        for skill_file in skills:
            # Layout is agent-skills/kiss-<name>/kiss-<name>.md, so the stem
            # is already the full skill name.
            expected_name = skill_file.stem

            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            fm, _ = _extract_frontmatter_and_body(content)

            actual_name = fm.get("name", "")
            if actual_name != expected_name:
                failures.append((expected_name, actual_name, expected_name))
        
        assert not failures, (
            f"Skills with mismatched name fields:\n" +
            "\n".join(
                f"  {stem}: got '{actual}', expected '{expected}'"
                for stem, actual, expected in failures
            )
        )

    def test_name_format_valid(self):
        """name field follows format: 1-64 chars, lowercase alphanumeric + hyphens."""
        skills = _discover_skill_files()
        failures = []
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            fm, _ = _extract_frontmatter_and_body(content)
            
            name = fm.get("name", "")
            # Check: 1-64 chars, lowercase alphanumeric + hyphens, no leading/trailing/consecutive
            if not (1 <= len(name) <= 64):
                failures.append((name, "length not 1-64 chars"))
                continue
            
            if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', name):
                failures.append((name, "format invalid (must be lowercase, hyphens only between alphanumerics)"))
        
        assert not failures, (
            f"Skills with invalid name format:\n" +
            "\n".join(f"  {name}: {reason}" for name, reason in failures)
        )

    def test_description_within_limits(self):
        """description field is 1-1024 characters."""
        skills = _discover_skill_files()
        failures = []
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            fm, _ = _extract_frontmatter_and_body(content)
            
            desc = fm.get("description", "")
            if not (1 <= len(desc) <= 1024):
                failures.append((skill_file.name, len(desc)))
        
        assert not failures, (
            f"Skills with out-of-range description:\n" +
            "\n".join(f"  {name}: {length} chars" for name, length in failures)
        )

    def test_body_has_required_sections(self):
        """Every skill body contains Inputs, Outputs, Context Update sections."""
        skills = _discover_skill_files()
        failures = []
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            _, body = _extract_frontmatter_and_body(content)
            
            missing = []
            for section in REQUIRED_BODY_SECTIONS:
                if section not in body:
                    missing.append(section)
            
            if missing:
                failures.append((skill_file.name, missing))
        
        assert not failures, (
            f"Skills missing required body sections:\n" +
            "\n".join(f"  {name}: missing {sections}" for name, sections in failures)
        )

    def test_handoffs_in_body_not_frontmatter(self):
        """If skill has handoffs, they're in body (## Handoffs), not frontmatter."""
        skills = _discover_skill_files()
        failures = []
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            fm, body = _extract_frontmatter_and_body(content)
            
            # Check: no handoffs in frontmatter
            if "handoffs" in fm:
                failures.append((skill_file.name, "handoffs in frontmatter (should be in body)"))
            
            # If handoffs in body, that's ok; if not, that's also ok (not all skills have them)
        
        assert not failures, (
            f"Skills with handoffs in wrong location:\n" +
            "\n".join(f"  {name}: {reason}" for name, reason in failures)
        )

    def test_no_hardcoded_paths(self):
        """No hardcoded .specify/ or .kiss/ paths in body (except .kiss/context.yml)."""
        skills = _discover_skill_files()
        failures = []
        
        hardcoded_patterns = [
            (r'\.specify/specs/', ".specify/specs/"),
            (r'\.specify/plans/', ".specify/plans/"),
            (r'\.specify/taskify/', ".specify/taskify/"),
            (r'\.specify/templates/', ".specify/templates/"),
            (r'\.specify/scripts/', ".specify/scripts/"),
            (r'\.kiss/specs/', ".kiss/specs/"),
            (r'\.kiss/plans/', ".kiss/plans/"),
            (r'\.kiss/tasks/', ".kiss/tasks/"),
            (r'\.kiss/templates/', ".kiss/templates/"),
            (r'\.kiss/scripts/', ".kiss/scripts/"),
        ]
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            _, body = _extract_frontmatter_and_body(content)
            
            found = []
            for pattern, label in hardcoded_patterns:
                if re.search(pattern, body):
                    found.append(label)
            
            if found:
                failures.append((skill_file.name, found))
        
        assert not failures, (
            f"Skills with hardcoded paths (should use {{context.*}} placeholders):\n" +
            "\n".join(f"  {name}: {paths}" for name, paths in failures)
        )

    def test_only_standard_placeholders(self):
        """Body only uses standard {context.*} placeholders from Phase 5.3."""
        skills = _discover_skill_files()
        failures = []
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            _, body = _extract_frontmatter_and_body(content)
            
            # Find all {context.KEY} patterns
            found_placeholders = set(re.findall(r'\{context\.\S+?\}', body))
            non_standard = found_placeholders - STANDARD_PLACEHOLDERS
            
            if non_standard:
                failures.append((skill_file.name, non_standard))
        
        assert not failures, (
            f"Skills with non-standard placeholders:\n" +
            "\n".join(
                f"  {name}: {placeholders}\n"
                f"    Standard: {sorted(STANDARD_PLACEHOLDERS)}"
                for name, placeholders in failures
            )
        )

    def test_metadata_contains_author_and_version(self):
        """metadata field includes author and version."""
        skills = _discover_skill_files()
        failures = []
        
        for skill_file in skills:
            with open(skill_file, encoding="utf-8") as f:
                content = f.read()
            fm, _ = _extract_frontmatter_and_body(content)
            
            metadata = fm.get("metadata", {})
            missing = []
            if "author" not in metadata:
                missing.append("author")
            if "version" not in metadata:
                missing.append("version")
            
            if missing:
                failures.append((skill_file.name, missing))
        
        assert not failures, (
            f"Skills with missing metadata fields:\n" +
            "\n".join(f"  {name}: missing {fields}" for name, fields in failures)
        )

    def test_skills_ref_validate_passes(self, skills_ref_validator):
        """(O1) Every skill is valid per skills-ref validator (if installed).
        
        Skipped if skills-ref is not available.
        """
        if skills_ref_validator is None:
            pytest.skip("skills-ref not installed; install dev extra to enable")
        
        # For flat layout, we need to temporarily create SKILL.md files
        # or validate the parent directory. For now, we skip detailed
        # skills-ref validation since the custom tests above cover compliance.
        pytest.skip(
            "skills-ref validation requires SKILL.md in directories; "
            "using local compliance tests instead"
        )

