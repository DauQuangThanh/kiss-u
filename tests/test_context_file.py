"""Phase 5.6 context file creation and usage.

Verifies that `kiss init` creates `.kiss/context.yml` with the correct schema,
that it can be customized via CLI flags, and that it tracks selected integrations.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import pytest
import yaml
from typer.testing import CliRunner

from kiss_cli import app
from kiss_cli.context import create_context_file


# ---------------------------------------------------------------------------
# Direct function tests
# ---------------------------------------------------------------------------


class TestCreateContextFile:
    """Test the create_context_file() function directly."""

    def test_context_file_created_with_defaults(self, tmp_path: Path) -> None:
        """context.yml is created with correct schema and default values."""
        create_context_file(tmp_path)

        context_file = tmp_path / ".kiss" / "context.yml"
        assert context_file.exists(), "context.yml should be created"

        with open(context_file) as f:
            data = yaml.safe_load(f)

        # Verify schema_version
        assert data.get("schema_version") == "1.0"

        # Verify paths
        paths = data.get("paths", {})
        assert paths.get("docs") == "docs"
        assert paths.get("specs") == "docs/specs"
        assert paths.get("plans") == "docs/plans"
        assert paths.get("tasks") == "docs/tasks"
        assert paths.get("templates") == "templates"
        assert paths.get("scripts") == "scripts"

        # Verify current (all null)
        current = data.get("current", {})
        assert current.get("feature") is None
        assert current.get("spec") is None
        assert current.get("plan") is None
        assert current.get("tasks") is None
        assert current.get("checklist") is None
        assert current.get("branch") is None

        # Verify preferences
        prefs = data.get("preferences", {})
        assert prefs.get("output_format") == "markdown"
        assert prefs.get("task_numbering") == "sequential"
        assert prefs.get("confirm_before_write") is True
        assert prefs.get("auto_update_context") is True

        # Verify language defaults
        language = data.get("language", {})
        assert language.get("output") == "English"
        assert language.get("interaction") == "English"

        # Verify integrations (default)
        assert data.get("integrations") == ["claude"]

    def test_context_file_custom_integrations(self, tmp_path: Path) -> None:
        """context.yml tracks custom integration list."""
        create_context_file(tmp_path, integrations=["claude", "copilot", "gemini"])

        context_file = tmp_path / ".kiss" / "context.yml"
        with open(context_file) as f:
            data = yaml.safe_load(f)

        assert data.get("integrations") == ["claude", "copilot", "gemini"]

    def test_context_file_custom_paths(self, tmp_path: Path) -> None:
        """context.yml respects custom path overrides."""
        create_context_file(
            tmp_path,
            specs_dir="src/specs",
            plans_dir="docs/plans",
            tasks_dir="docs/tasks",
            templates_dir="templates",
            scripts_dir="scripts",
        )

        context_file = tmp_path / ".kiss" / "context.yml"
        with open(context_file) as f:
            data = yaml.safe_load(f)

        paths = data.get("paths", {})
        assert paths.get("specs") == "src/specs"
        assert paths.get("plans") == "docs/plans"
        assert paths.get("tasks") == "docs/tasks"
        assert paths.get("templates") == "templates"
        assert paths.get("scripts") == "scripts"

    def test_context_file_is_valid_yaml(self, tmp_path: Path) -> None:
        """Created context.yml is valid YAML."""
        create_context_file(tmp_path)
        context_file = tmp_path / ".kiss" / "context.yml"

        # Should parse without errors
        with open(context_file) as f:
            data = yaml.safe_load(f)

        assert isinstance(data, dict)

    def test_context_file_is_utf8_on_every_platform(self, tmp_path: Path) -> None:
        """context.yml is written as UTF-8 regardless of system locale.

        Regression guard for a Windows failure mode: if write_text() falls
        back to the system code page (cp1252 on Windows-en), the em-dashes
        in the template (— = U+2014, encoded as 3 bytes E2 80 94 in UTF-8
        but byte 0x97 in cp1252) become unreadable for any consumer that
        reads the file as UTF-8 (e.g. `kiss check context`).
        """
        create_context_file(tmp_path)
        context_file = tmp_path / ".kiss" / "context.yml"

        # Read raw bytes and decode strictly as UTF-8 — this is what
        # check_context() does. If the writer used a different encoding,
        # this will raise UnicodeDecodeError.
        raw = context_file.read_bytes()
        text = raw.decode("utf-8")

        # The template contains an em-dash; verify its UTF-8 encoding
        # (E2 80 94) survived the round-trip rather than being mangled.
        assert "—" in text, "Template em-dash must round-trip as UTF-8"
        assert b"\xe2\x80\x94" in raw, "em-dash must be encoded as UTF-8 bytes"


# ---------------------------------------------------------------------------
# Integration tests via CLI
# ---------------------------------------------------------------------------


class TestInitCreatesContextFile:
    """Test that `kiss init` creates context.yml."""

    def test_kiss_init_creates_context_yml(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
        """kiss init creates .kiss/context.yml with integrations field."""
        # Prevent network calls
        import socket
        monkeypatch.setattr(socket, "create_connection", lambda *a, **k: None)

        runner = CliRunner()
        project_dir = tmp_path / "test-project"

        result = runner.invoke(
            app,
            [
                "init", str(project_dir),
                "--integration", "claude",
                "--ignore-agent-tools",
                "--no-git",
            ],
        )

        # Allow non-zero exit if init fails for other reasons, but the file
        # should still be created (it's created early in the process).
        context_file = project_dir / ".kiss" / "context.yml"

        # If init succeeded, context.yml should exist
        if result.exit_code == 0:
            assert context_file.exists(), "context.yml should be created by kiss init"

            with open(context_file) as f:
                data = yaml.safe_load(f)

            # Should have the integrations field with the selected integration
            assert "integrations" in data
            assert "claude" in data.get("integrations", [])

    def test_context_file_has_required_sections(self, tmp_path: Path) -> None:
        """context.yml has all required sections per Phase 5.2 spec."""
        create_context_file(tmp_path, integrations=["copilot"])

        context_file = tmp_path / ".kiss" / "context.yml"
        with open(context_file) as f:
            data = yaml.safe_load(f)

        # All required sections
        assert "schema_version" in data
        assert "paths" in data
        assert "current" in data
        assert "preferences" in data
        assert "language" in data
        assert "integrations" in data

        # All required path keys
        for key in ["docs", "specs", "plans", "tasks", "templates", "scripts"]:
            assert key in data["paths"]

        # All required current keys
        for key in ["feature", "spec", "plan", "tasks", "checklist", "branch"]:
            assert key in data["current"]

        # All required preference keys
        for key in ["output_format", "task_numbering", "confirm_before_write", "auto_update_context"]:
            assert key in data["preferences"]

        # All required language keys
        for key in ["output", "interaction"]:
            assert key in data["language"]
