"""Tests for context.yml merge-on-upgrade (WP-6)."""

import yaml
from pathlib import Path

import pytest


@pytest.fixture()
def kiss_project(tmp_path: Path) -> Path:
    """Create a minimal .kiss/ directory."""
    (tmp_path / ".kiss").mkdir(parents=True)
    return tmp_path


def _write_context(project: Path, data: dict) -> None:
    """Write a context.yml for testing."""
    path = project / ".kiss" / "context.yml"
    path.write_text(
        yaml.dump(data, default_flow_style=False, allow_unicode=True),
        encoding="utf-8",
    )


def _read_context(project: Path) -> dict:
    """Read context.yml."""
    path = project / ".kiss" / "context.yml"
    return yaml.safe_load(path.read_text(encoding="utf-8"))


class TestMergeContextFile:
    """Tests for merge_context_file."""

    def test_preserves_language_output(self, kiss_project: Path) -> None:
        """T047: language.output: Vietnamese survives merge."""
        _write_context(kiss_project, {
            "schema_version": "1.0",
            "paths": {"docs": "docs"},
            "language": {"output": "Vietnamese", "interaction": "Vietnamese"},
            "integrations": ["claude"],
        })

        from kiss_cli.context import merge_context_file

        merge_context_file(kiss_project, new_integrations=["claude"])

        result = _read_context(kiss_project)
        assert result["language"]["output"] == "Vietnamese"
        assert result["language"]["interaction"] == "Vietnamese"

    def test_adds_new_schema_key(self, kiss_project: Path) -> None:
        """T048: New key from template is added with default value."""
        _write_context(kiss_project, {
            "schema_version": "1.0",
            "paths": {"docs": "docs"},
            "integrations": ["claude"],
            # Missing: preferences, language, current
        })

        from kiss_cli.context import merge_context_file

        merge_context_file(kiss_project, new_integrations=["claude"])

        result = _read_context(kiss_project)
        # New keys should be present with template defaults
        assert "preferences" in result
        assert result["preferences"]["confirm_before_write"] is True
        assert "language" in result
        assert result["language"]["output"] == "English"
        assert "current" in result

    def test_creates_fresh_when_missing(self, kiss_project: Path) -> None:
        """T049: No context.yml → created from template."""
        from kiss_cli.context import merge_context_file

        merge_context_file(kiss_project, new_integrations=["claude"])

        result = _read_context(kiss_project)
        assert result["schema_version"] == "1.0"
        assert "claude" in result.get("integrations", [])

    def test_union_merges_integrations(self, kiss_project: Path) -> None:
        """T050: Integrations list is union-merged, no duplicates."""
        _write_context(kiss_project, {
            "schema_version": "1.0",
            "paths": {"docs": "docs"},
            "integrations": ["claude"],
        })

        from kiss_cli.context import merge_context_file

        merge_context_file(kiss_project, new_integrations=["claude", "copilot"])

        result = _read_context(kiss_project)
        assert result["integrations"] == ["claude", "copilot"]

    def test_updates_schema_version(self, kiss_project: Path) -> None:
        """T051: schema_version always updated to template value."""
        _write_context(kiss_project, {
            "schema_version": "0.9",
            "paths": {"docs": "docs"},
            "integrations": ["claude"],
        })

        from kiss_cli.context import merge_context_file

        merge_context_file(kiss_project, new_integrations=["claude"])

        result = _read_context(kiss_project)
        assert result["schema_version"] == "1.0"

    def test_preserves_custom_paths(self, kiss_project: Path) -> None:
        """User-customized paths.docs is preserved."""
        _write_context(kiss_project, {
            "schema_version": "1.0",
            "paths": {"docs": "documentation", "specs": "documentation/specs"},
            "integrations": ["claude"],
        })

        from kiss_cli.context import merge_context_file

        merge_context_file(kiss_project, new_integrations=["claude"])

        result = _read_context(kiss_project)
        assert result["paths"]["docs"] == "documentation"
        assert result["paths"]["specs"] == "documentation/specs"
