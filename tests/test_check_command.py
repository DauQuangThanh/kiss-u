"""Tests for the `kiss check` command — health check for projects.

Covers:
- `kiss check --skills` — validate skill files
- `kiss check --integrations` — check integration configs
- `kiss check --context` — validate context.yml schema
- `kiss check` (no subcommand) — run all three checks
"""

import json
import os
from pathlib import Path

import pytest
import yaml
from typer.testing import CliRunner

from kiss_cli import app

runner = CliRunner()


class TestCheckSkillsCommand:
    """Test `kiss check --skills` subcommand."""

    def test_check_skills_passes_on_valid_install(self, tmp_path):
        """Valid SKILL.md passes validation."""
        # Set up minimal project structure
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        # Create init-options.json with claude integration
        init_options = {
            "integrations": ["claude"],
        }
        (kiss_dir / "init-options.json").write_text(
            json.dumps(init_options), encoding="utf-8"
        )

        # Create context.yml
        context = {
            "schema_version": "1.0",
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            "current": {
                "feature": None,
                "spec": None,
                "plan": None,
                "tasks": None,
                "checklist": None,
                "branch": None,
            },
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": True,
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        # Create a valid SKILL.md in .claude/skills/
        skills_dir = tmp_path / ".claude" / "skills"
        skills_subdir = skills_dir / "kiss-test"
        skills_subdir.mkdir(parents=True)

        skill_content = """---
name: kiss-test
description: Test skill for validation
license: MIT
compatibility: "Designed for Claude Code and agentskills.io-compatible agents."
metadata:
  author: "test"
  version: "1.0"
---

## Inputs

- Test input

## Outputs

- Test output

## Context Update

- None
"""
        (skills_subdir / "SKILL.md").write_text(skill_content, encoding="utf-8")

        # Run check from tmp_path
        _old_cwd = os.getcwd()

        try:

            os.chdir(tmp_path)

            result = runner.invoke(app, ["check", "skills"])

        finally:

            os.chdir(_old_cwd)
        assert result.exit_code == 0, f"Output: {result.stdout}"
        assert "1/1 passed" in result.stdout

    def test_check_skills_fails_on_noncompliant_skill(self, tmp_path):
        """Invalid SKILL.md fails validation."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        init_options = {"integrations": ["claude"]}
        (kiss_dir / "init-options.json").write_text(
            json.dumps(init_options), encoding="utf-8"
        )

        context = {
            "schema_version": "1.0",
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            "current": {
                "feature": None,
                "spec": None,
                "plan": None,
                "tasks": None,
                "checklist": None,
                "branch": None,
            },
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": True,
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        # Create an invalid SKILL.md (missing description)
        skills_dir = tmp_path / ".claude" / "skills"
        skills_subdir = skills_dir / "kiss-bad"
        skills_subdir.mkdir(parents=True)

        bad_skill_content = """---
name: kiss-bad
license: MIT
metadata:
  author: "test"
  version: "1.0"
---

## Inputs
- Test
"""
        (skills_subdir / "SKILL.md").write_text(bad_skill_content, encoding="utf-8")

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check", "skills"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code != 0, f"Output: {result.stdout}"
        # Output may be in a Rich table; check for the skill name or the error
        import re
        out = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", result.stdout)
        assert "kiss-bad" in out or "Missing" in out or "description" in out

    def test_check_skills_no_init_options_warning(self, tmp_path):
        """Gracefully handles missing init-options.json."""
        _old_cwd = os.getcwd()

        try:

            os.chdir(tmp_path)

            result = runner.invoke(app, ["check", "skills"])

        finally:

            os.chdir(_old_cwd)
        # Should warn but not fail — no integrations found
        assert "No integrations configured" in result.stdout or "init-options.json" in result.stdout


class TestCheckIntegrationsCommand:
    """Test `kiss check --integrations` subcommand."""

    def test_check_integrations_ok_with_valid_config(self, tmp_path):
        """Valid integration dirs pass check."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        init_options = {"integrations": ["claude"]}
        (kiss_dir / "init-options.json").write_text(
            json.dumps(init_options), encoding="utf-8"
        )

        # Create integration dir
        (tmp_path / ".claude" / "skills").mkdir(parents=True)

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check", "integrations"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code == 0, f"Output: {result.stdout}"
        assert "OK" in result.stdout

    def test_check_integrations_reports_missing_dir(self, tmp_path):
        """Missing integration dir is reported."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        init_options = {"integrations": ["claude"]}
        (kiss_dir / "init-options.json").write_text(
            json.dumps(init_options), encoding="utf-8"
        )

        # Don't create the .claude/skills dir

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check", "integrations"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code != 0, f"Output: {result.stdout}"
        assert "MISSING" in result.stdout or ".claude" in result.stdout


class TestCheckContextCommand:
    """Test `kiss check --context` subcommand."""

    def test_default_generated_context_passes_validator(self, tmp_path):
        """The context.yml that kiss init generates must pass `kiss check context`.

        Regression guard: any drift between create_context_file (the template
        generator) and check_context (the validator) — adding a key to one
        side without the other — is caught here.
        """
        from kiss_cli.context import create_context_file

        create_context_file(tmp_path)

        # Create the directories the validator warns (not errors) about.
        for sub in ("docs", "specs", "plans", "tasks", "templates", "scripts"):
            (tmp_path / sub).mkdir(parents=True, exist_ok=True)

        _old_cwd = os.getcwd()
        try:
            os.chdir(tmp_path)
            result = runner.invoke(app, ["check", "context"])
        finally:
            os.chdir(_old_cwd)

        assert result.exit_code == 0, (
            "Default-generated context.yml failed validation — schema drift "
            f"between create_context_file and check_context. Output:\n{result.stdout}"
        )
        assert "OK" in result.stdout

    def test_check_context_valid_defaults(self, tmp_path):
        """Valid context.yml with defaults passes."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        context = {
            "schema_version": "1.0",
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            "current": {
                "feature": None,
                "spec": None,
                "plan": None,
                "tasks": None,
                "checklist": None,
                "branch": None,
            },
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": True,
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check", "context"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code == 0, f"Output: {result.stdout}"
        assert "OK" in result.stdout

    def test_check_context_invalid_schema_version(self, tmp_path):
        """Wrong schema_version is rejected."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        context = {
            "schema_version": "2.0",  # Wrong!
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            "current": {
                "feature": None,
                "spec": None,
                "plan": None,
                "tasks": None,
                "checklist": None,
                "branch": None,
            },
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": True,
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check", "context"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code != 0, f"Output: {result.stdout}"
        assert "schema_version" in result.stdout

    def test_check_context_invalid_key_type(self, tmp_path):
        """Wrong type for a key is rejected."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        context = {
            "schema_version": "1.0",
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            "current": {
                "feature": None,
                "spec": None,
                "plan": None,
                "tasks": None,
                "checklist": None,
                "branch": None,
            },
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": "yes",  # Should be bool!
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check", "context"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code != 0, f"Output: {result.stdout}"
        assert "confirm_before_write" in result.stdout
        assert "expected" in result.stdout.lower()

    def test_check_context_missing_top_level_key(self, tmp_path):
        """Missing top-level key is rejected."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        context = {
            "schema_version": "1.0",
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            # Missing 'current'!
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": True,
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check", "context"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code != 0, f"Output: {result.stdout}"
        assert "current" in result.stdout.lower()

    def test_check_context_no_file_warning(self, tmp_path):
        """Missing context.yml is handled gracefully."""
        _old_cwd = os.getcwd()

        try:

            os.chdir(tmp_path)

            result = runner.invoke(app, ["check", "context"])

        finally:

            os.chdir(_old_cwd)
        # Should warn but not fail
        assert "context.yml" in result.stdout


class TestCheckAllCommand:
    """Test `kiss check` (no subcommand) — runs all three checks."""

    def test_check_all_passes_on_valid_project(self, tmp_path):
        """All checks pass on a valid project."""
        # Set up full valid project
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        init_options = {"integrations": ["claude"]}
        (kiss_dir / "init-options.json").write_text(
            json.dumps(init_options), encoding="utf-8"
        )

        context = {
            "schema_version": "1.0",
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            "current": {
                "feature": None,
                "spec": None,
                "plan": None,
                "tasks": None,
                "checklist": None,
                "branch": None,
            },
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": True,
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        # Create integration dir
        (tmp_path / ".claude" / "skills").mkdir(parents=True)

        # Create a valid skill
        skills_subdir = tmp_path / ".claude" / "skills" / "kiss-test"
        skills_subdir.mkdir()
        skill_content = """---
name: kiss-test
description: Test skill
license: MIT
compatibility: "Designed for Claude Code and agentskills.io-compatible agents."
metadata:
  author: "test"
  version: "1.0"
---

## Inputs
- Test

## Outputs
- Test

## Context Update
- None
"""
        (skills_subdir / "SKILL.md").write_text(skill_content, encoding="utf-8")

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code == 0, f"Output: {result.stdout}"
        assert "ALL CHECKS PASSED" in result.stdout or "ALL" in result.stdout

    def test_check_all_exits_nonzero_on_any_failure(self, tmp_path):
        """Check exits non-zero if any subcheck fails."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        init_options = {"integrations": ["claude"]}
        (kiss_dir / "init-options.json").write_text(
            json.dumps(init_options), encoding="utf-8"
        )

        # Invalid context.yml (wrong schema version)
        context = {
            "schema_version": "2.0",  # Wrong!
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            "current": {
                "feature": None,
                "spec": None,
                "plan": None,
                "tasks": None,
                "checklist": None,
                "branch": None,
            },
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": True,
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        # Create integration dir (so that check passes)
        (tmp_path / ".claude" / "skills").mkdir(parents=True)

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check"])


        finally:


            os.chdir(_old_cwd)
        assert result.exit_code != 0, f"Output: {result.stdout}"
        assert "FAILURES DETECTED" in result.stdout or "schema_version" in result.stdout

    def test_check_all_runs_all_three_checks(self, tmp_path):
        """Check command runs skills, integrations, and context checks."""
        kiss_dir = tmp_path / ".kiss"
        kiss_dir.mkdir()

        init_options = {"integrations": ["claude"]}
        (kiss_dir / "init-options.json").write_text(
            json.dumps(init_options), encoding="utf-8"
        )

        context = {
            "schema_version": "1.0",
            "paths": {
                "docs": "docs",
                "specs": "specs",
                "plans": "plans",
                "tasks": "tasks",
                "templates": "templates",
                "scripts": "scripts",
            },
            "current": {
                "feature": None,
                "spec": None,
                "plan": None,
                "tasks": None,
                "checklist": None,
                "branch": None,
            },
            "preferences": {
                "output_format": "markdown",
                "task_numbering": "sequential",
                "confirm_before_write": True,
                "auto_update_context": True,
            },
            "language": {
                "output": "English",
                "interaction": "English",
            },
            "integrations": ["claude"],
        }
        (kiss_dir / "context.yml").write_text(
            yaml.dump(context), encoding="utf-8"
        )

        (tmp_path / ".claude" / "skills").mkdir(parents=True)

        _old_cwd = os.getcwd()


        try:


            os.chdir(tmp_path)


            result = runner.invoke(app, ["check"])


        finally:


            os.chdir(_old_cwd)
        # Should mention all three check types
        output = result.stdout
        assert "skill" in output.lower() or "Skills" in output
        assert "integration" in output.lower() or "Integrations" in output
        assert "context" in output.lower() or "Context" in output
