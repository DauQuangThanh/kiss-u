"""Tests for multi-integration support in integration.json helpers.

Covers WP-1 (schema migration), WP-2 (install), WP-3 (uninstall),
WP-4 (upgrade), and WP-8 (switch) lifecycle.
"""

import json
from pathlib import Path

import pytest


# ---------------------------------------------------------------------------
# Fixtures (T001-T003)
# ---------------------------------------------------------------------------

@pytest.fixture()
def kiss_project(tmp_path: Path) -> Path:
    """Create a minimal .kiss/ directory structure."""
    (tmp_path / ".kiss" / "integrations").mkdir(parents=True)
    return tmp_path


def write_old_format_json(project: Path, key: str, version: str = "0.1.0") -> None:
    """Write integration.json in the legacy single-key format."""
    dest = project / ".kiss" / "integration.json"
    dest.write_text(
        json.dumps({"integration": key, "version": version}, indent=2) + "\n",
        encoding="utf-8",
    )


def write_new_format_json(
    project: Path, keys: list[str], version: str = "0.1.0"
) -> None:
    """Write integration.json in the new multi-integration format."""
    dest = project / ".kiss" / "integration.json"
    dest.write_text(
        json.dumps({"integrations": keys, "version": version}, indent=2) + "\n",
        encoding="utf-8",
    )


def write_context_yml(project: Path, overrides: dict | None = None) -> None:
    """Write a customized .kiss/context.yml for merge tests."""
    import yaml

    defaults = {
        "schema_version": "1.0",
        "paths": {"docs": "docs", "specs": "docs/specs"},
        "current": {"feature": None},
        "preferences": {"confirm_before_write": True},
        "language": {"output": "English", "interaction": "English"},
        "integrations": ["claude"],
    }
    if overrides:
        for key, val in overrides.items():
            if isinstance(val, dict) and key in defaults and isinstance(defaults[key], dict):
                defaults[key].update(val)
            else:
                defaults[key] = val

    dest = project / ".kiss" / "context.yml"
    dest.write_text(yaml.dump(defaults, default_flow_style=False), encoding="utf-8")


# ---------------------------------------------------------------------------
# WP-1: _read_integration_json tests (T004-T006)
# ---------------------------------------------------------------------------

class TestReadIntegrationJson:
    """Tests for _read_integration_json with old/new format support."""

    def test_reads_old_format_as_list(self, kiss_project: Path) -> None:
        """T004: Old format {"integration": "claude"} returns {"integrations": ["claude"]}."""
        write_old_format_json(kiss_project, "claude")

        from kiss_cli.installer import _read_integration_json

        result = _read_integration_json(kiss_project)
        assert result["integrations"] == ["claude"]

    def test_reads_new_format_as_is(self, kiss_project: Path) -> None:
        """T005: New format {"integrations": [...]} returns as-is."""
        write_new_format_json(kiss_project, ["claude", "copilot"])

        from kiss_cli.installer import _read_integration_json

        result = _read_integration_json(kiss_project)
        assert result["integrations"] == ["claude", "copilot"]

    def test_returns_empty_list_for_missing_file(self, kiss_project: Path) -> None:
        """T006: Missing file returns {"integrations": []}."""
        from kiss_cli.installer import _read_integration_json

        result = _read_integration_json(kiss_project)
        assert result.get("integrations", []) == []


# ---------------------------------------------------------------------------
# WP-1: _write_integration_json tests (T007)
# ---------------------------------------------------------------------------

class TestWriteIntegrationJson:
    """Tests for _write_integration_json with new list format."""

    def test_writes_new_format(self, kiss_project: Path) -> None:
        """T007: Writes {"integrations": [...], "version": "..."}."""
        from kiss_cli.installer import _write_integration_json

        _write_integration_json(kiss_project, ["claude", "copilot"])

        path = kiss_project / ".kiss" / "integration.json"
        data = json.loads(path.read_text(encoding="utf-8"))
        assert "integrations" in data
        assert data["integrations"] == ["claude", "copilot"]
        assert "version" in data
        # Must NOT have the old singular field
        assert "integration" not in data


# ---------------------------------------------------------------------------
# WP-1: _add_integration_to_json tests (T008)
# ---------------------------------------------------------------------------

class TestAddIntegrationToJson:
    """Tests for _add_integration_to_json helper."""

    def test_appends_key_to_empty_list(self, kiss_project: Path) -> None:
        """T008a: Add to empty list → list has one entry."""
        write_new_format_json(kiss_project, [])

        from kiss_cli.installer import _add_integration_to_json

        _add_integration_to_json(kiss_project, "claude")

        data = json.loads(
            (kiss_project / ".kiss" / "integration.json").read_text(encoding="utf-8")
        )
        assert data["integrations"] == ["claude"]

    def test_skips_duplicate_key(self, kiss_project: Path) -> None:
        """T008b: Add duplicate key → no change."""
        write_new_format_json(kiss_project, ["claude"])

        from kiss_cli.installer import _add_integration_to_json

        _add_integration_to_json(kiss_project, "claude")

        data = json.loads(
            (kiss_project / ".kiss" / "integration.json").read_text(encoding="utf-8")
        )
        assert data["integrations"] == ["claude"]

    def test_appends_second_key(self, kiss_project: Path) -> None:
        """T008c: Add different key → list grows."""
        write_new_format_json(kiss_project, ["claude"])

        from kiss_cli.installer import _add_integration_to_json

        _add_integration_to_json(kiss_project, "copilot")

        data = json.loads(
            (kiss_project / ".kiss" / "integration.json").read_text(encoding="utf-8")
        )
        assert data["integrations"] == ["claude", "copilot"]


# ---------------------------------------------------------------------------
# WP-1: _remove_integration_from_json tests (T009-T010)
# ---------------------------------------------------------------------------

class TestRemoveIntegrationFromJson:
    """Tests for _remove_integration_from_json helper."""

    def test_removes_key_preserves_others(self, kiss_project: Path) -> None:
        """T009: Remove one key → others preserved."""
        write_new_format_json(kiss_project, ["claude", "copilot"])

        from kiss_cli.installer import _remove_integration_from_json

        _remove_integration_from_json(kiss_project, "claude")

        data = json.loads(
            (kiss_project / ".kiss" / "integration.json").read_text(encoding="utf-8")
        )
        assert data["integrations"] == ["copilot"]

    def test_last_key_leaves_empty_list(self, kiss_project: Path) -> None:
        """T010: Remove last key → empty list, file persists."""
        write_new_format_json(kiss_project, ["claude"])

        from kiss_cli.installer import _remove_integration_from_json

        _remove_integration_from_json(kiss_project, "claude")

        path = kiss_project / ".kiss" / "integration.json"
        assert path.exists(), "File should persist even when list is empty"
        data = json.loads(path.read_text(encoding="utf-8"))
        assert data["integrations"] == []
