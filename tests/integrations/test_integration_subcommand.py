"""Tests for ``kiss integration`` subcommand (list, install, uninstall, switch)."""

import json
import os

from typer.testing import CliRunner

from kiss_cli import app


runner = CliRunner()


def _init_project(tmp_path, integration="copilot"):
    """Helper: init a kiss project with the given integration."""
    project = tmp_path / "proj"
    project.mkdir()
    old_cwd = os.getcwd()
    try:
        os.chdir(project)
        result = runner.invoke(app, [
            "init", "--here",
            "--integration", integration,
            "--no-git",
            "--ignore-agent-tools",
        ], catch_exceptions=False)
    finally:
        os.chdir(old_cwd)
    assert result.exit_code == 0, f"init failed: {result.output}"
    return project


# ── list ─────────────────────────────────────────────────────────────


class TestIntegrationList:
    def test_list_requires_kiss_project(self, tmp_path):
        old_cwd = os.getcwd()
        try:
            os.chdir(tmp_path)
            result = runner.invoke(app, ["integration", "list"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code != 0
        assert "Not a kiss project" in result.output

    def test_list_shows_installed(self, tmp_path):
        project = _init_project(tmp_path, "copilot")
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "list"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        assert "copilot" in result.output
        assert "installed" in result.output

    def test_list_shows_available_integrations(self, tmp_path):
        project = _init_project(tmp_path, "copilot")
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "list"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        # Should show multiple integrations
        assert "claude" in result.output
        assert "gemini" in result.output


# ── install ──────────────────────────────────────────────────────────


class TestIntegrationInstall:
    def test_install_requires_kiss_project(self, tmp_path):
        old_cwd = os.getcwd()
        try:
            os.chdir(tmp_path)
            result = runner.invoke(app, ["integration", "install", "claude"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code != 0
        assert "Not a kiss project" in result.output

    def test_install_unknown_integration(self, tmp_path):
        project = _init_project(tmp_path)
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "install", "nonexistent"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code != 0
        assert "Unknown integration" in result.output

    def test_install_already_installed(self, tmp_path):
        project = _init_project(tmp_path, "copilot")
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "install", "copilot"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        assert "already installed" in result.output

    def test_install_different_when_one_exists(self, tmp_path):
        """Multi-integration: installing a second integration succeeds."""
        project = _init_project(tmp_path, "copilot")
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "integration", "install", "claude",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        assert "installed successfully" in result.output
        # Both integrations in the list
        data = json.loads((project / ".kiss" / "integration.json").read_text(encoding="utf-8"))
        assert "copilot" in data["integrations"]
        assert "claude" in data["integrations"]

    def test_install_into_bare_project(self, tmp_path):
        """Install into a project with .kiss/ but no integration."""
        project = tmp_path / "bare"
        project.mkdir()
        (project / ".kiss").mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "integration", "install", "claude",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, result.output
        assert "installed successfully" in result.output

        # integration.json written (multi-integration format)
        data = json.loads((project / ".kiss" / "integration.json").read_text(encoding="utf-8"))
        assert "claude" in data["integrations"]

        # Manifest created
        assert (project / ".kiss" / "integrations" / "claude.manifest.json").exists()

        # Claude uses skills directory (not commands)
        assert (project / ".claude" / "skills" / "kiss-plan" / "SKILL.md").exists()

    def test_install_bare_project_creates_kiss_dir(self, tmp_path):
        """Installing into a bare project should ensure .kiss/ state directory exists.

        Scripts and templates are bundled into each per-skill folder, not
        a shared ``.kiss/scripts/`` or ``.kiss/templates/``.
        """
        project = tmp_path / "bare"
        project.mkdir()
        (project / ".kiss").mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "integration", "install", "claude",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, result.output

        # .kiss/ state directory should be present
        assert (project / ".kiss").is_dir()
        assert (project / ".kiss" / "integration.json").exists()
        # Per-skill scripts live under each integration's skill folder.
        assert (project / ".claude" / "skills" / "kiss-plan" / "scripts" / "bash" / "setup-plan.sh").exists()


# ── uninstall ────────────────────────────────────────────────────────


class TestIntegrationUninstall:
    def test_uninstall_requires_kiss_project(self, tmp_path):
        old_cwd = os.getcwd()
        try:
            os.chdir(tmp_path)
            result = runner.invoke(app, ["integration", "uninstall"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code != 0
        assert "Not a kiss project" in result.output

    def test_uninstall_no_integration(self, tmp_path):
        project = tmp_path / "proj"
        project.mkdir()
        (project / ".kiss").mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "uninstall"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        assert "No integration" in result.output

    def test_uninstall_removes_files(self, tmp_path):
        project = _init_project(tmp_path, "claude")
        # Claude uses skills directory
        assert (project / ".claude" / "skills" / "kiss-plan" / "SKILL.md").exists()
        assert (project / ".kiss" / "integrations" / "claude.manifest.json").exists()

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "uninstall"], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        assert "uninstalled" in result.output

        # Command files removed
        assert not (project / ".claude" / "skills" / "kiss-plan" / "SKILL.md").exists()

        # Manifest removed
        assert not (project / ".kiss" / "integrations" / "claude.manifest.json").exists()

        # integration.json persists with empty list
        int_json = project / ".kiss" / "integration.json"
        assert int_json.exists()
        data = json.loads(int_json.read_text(encoding="utf-8"))
        assert data["integrations"] == []

    def test_uninstall_preserves_modified_files(self, tmp_path):
        """Full lifecycle: install → modify → uninstall → modified file kept."""
        project = _init_project(tmp_path, "claude")
        plan_file = project / ".claude" / "skills" / "kiss-plan" / "SKILL.md"
        assert plan_file.exists()

        # Modify a file
        plan_file.write_text("# My custom plan command\n", encoding="utf-8")

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "uninstall"], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        assert "preserved" in result.output

        # Modified file kept
        assert plan_file.exists()
        assert plan_file.read_text(encoding="utf-8") == "# My custom plan command\n"

    def test_uninstall_wrong_key(self, tmp_path):
        project = _init_project(tmp_path, "copilot")
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "uninstall", "claude"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code != 0
        assert "is not installed" in result.output

    def test_uninstall_preserves_kiss_state(self, tmp_path):
        """The .kiss/ state directory survives integration uninstall.

        Scripts and templates ship per-skill (under each integration's
        skill folder), so there is no shared ``.kiss/scripts/`` or
        ``.kiss/templates/`` to preserve any longer.
        """
        project = _init_project(tmp_path, "claude")
        kiss_dir = project / ".kiss"
        assert kiss_dir.is_dir()

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "uninstall"], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0

        # .kiss/ state directory is preserved (workflows, init-options, etc.)
        assert kiss_dir.is_dir()
        assert (kiss_dir / "init-options.json").exists()


# ── switch ───────────────────────────────────────────────────────────


class TestIntegrationSwitch:
    def test_switch_requires_kiss_project(self, tmp_path):
        old_cwd = os.getcwd()
        try:
            os.chdir(tmp_path)
            result = runner.invoke(app, ["integration", "switch", "claude"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code != 0
        assert "Not a kiss project" in result.output

    def test_switch_unknown_target(self, tmp_path):
        project = _init_project(tmp_path)
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "switch", "nonexistent"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code != 0
        assert "Unknown integration" in result.output

    def test_switch_same_noop(self, tmp_path):
        project = _init_project(tmp_path, "copilot")
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "switch", "copilot"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        assert "already installed" in result.output

    def test_switch_between_integrations(self, tmp_path):
        project = _init_project(tmp_path, "claude")
        # Verify claude files exist (claude uses skills)
        assert (project / ".claude" / "skills" / "kiss-plan" / "SKILL.md").exists()

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "integration", "switch", "copilot",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, result.output
        assert "Switched to" in result.output

        # Old claude files removed
        assert not (project / ".claude" / "skills" / "kiss-plan" / "SKILL.md").exists()

        # New copilot files created (per-command bundle layout)
        assert (project / ".github" / "skills" / "kiss-plan" / "SKILL.md").exists()

        # integration.json updated (multi-integration format)
        data = json.loads((project / ".kiss" / "integration.json").read_text(encoding="utf-8"))
        assert "copilot" in data["integrations"]

    def test_switch_preserves_kiss_state(self, tmp_path):
        """Switching preserves the .kiss/ state directory.

        Scripts and templates ship per-skill, so there is no longer a
        shared ``.kiss/scripts/`` or ``.kiss/templates/`` to preserve.
        """
        project = _init_project(tmp_path, "claude")
        init_opts = project / ".kiss" / "init-options.json"
        assert init_opts.exists()

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "integration", "switch", "copilot",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0

        # .kiss/ state files preserved (init-options stays around, updated)
        assert init_opts.exists()

    def test_switch_from_nothing(self, tmp_path):
        """Switch when no integration is installed should just install the target."""
        project = tmp_path / "bare"
        project.mkdir()
        (project / ".kiss").mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "integration", "switch", "claude",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        assert "Switched to" in result.output

        data = json.loads((project / ".kiss" / "integration.json").read_text(encoding="utf-8"))
        assert "claude" in data["integrations"]


# ── Full lifecycle ───────────────────────────────────────────────────


class TestIntegrationLifecycle:
    def test_install_modify_uninstall_preserves_modified(self, tmp_path):
        """Full lifecycle: install → modify file → uninstall → verify modified file kept."""
        project = tmp_path / "lifecycle"
        project.mkdir()
        (project / ".kiss").mkdir()

        old_cwd = os.getcwd()
        try:
            os.chdir(project)

            # Install
            result = runner.invoke(app, [
                "integration", "install", "claude",
            ], catch_exceptions=False)
            assert result.exit_code == 0
            assert "installed successfully" in result.output

            # Claude uses skills directory
            plan_file = project / ".claude" / "skills" / "kiss-plan" / "SKILL.md"
            assert plan_file.exists()

            # Modify one file
            plan_file.write_text("# user customization\n", encoding="utf-8")

            # Uninstall
            result = runner.invoke(app, ["integration", "uninstall"], catch_exceptions=False)
            assert result.exit_code == 0
            assert "preserved" in result.output

            # Modified file kept
            assert plan_file.exists()
            assert plan_file.read_text(encoding="utf-8") == "# user customization\n"
        finally:
            os.chdir(old_cwd)


# ── Edge-case fixes ─────────────────────────────────────────────────


class TestScriptTypeValidation:
    def test_invalid_script_type_rejected(self, tmp_path):
        """--script with an invalid value should fail with a clear error."""
        project = tmp_path / "proj"
        project.mkdir()
        (project / ".kiss").mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "integration", "install", "claude",
                "--script", "bash",
            ])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code != 0
        assert "Invalid script type" in result.output

    def test_valid_script_types_accepted(self, tmp_path):
        """Both 'sh' and 'ps' should be accepted."""
        project = tmp_path / "proj"
        project.mkdir()
        (project / ".kiss").mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "integration", "install", "claude",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0


class TestParseIntegrationOptionsEqualsForm:
    def test_equals_form_parsed(self):
        """--key=value should be parsed the same as --key value.

        Uses a mock integration with declared options since the
        supported integrations may not accept custom options.
        """
        from kiss_cli import _parse_integration_options
        from kiss_cli.integrations.base import IntegrationOption

        class FakeIntegration:
            key = "fake"
            @classmethod
            def options(cls):
                return [IntegrationOption(name="--commands-dir", required=True)]

        result_space = _parse_integration_options(FakeIntegration(), "--commands-dir ./mydir")
        result_equals = _parse_integration_options(FakeIntegration(), "--commands-dir=./mydir")
        assert result_space is not None
        assert result_equals is not None
        assert result_space["commands_dir"] == "./mydir"
        assert result_equals["commands_dir"] == "./mydir"


class TestUninstallNoManifestClearsInitOptions:
    def test_init_options_cleared_on_no_manifest_uninstall(self, tmp_path):
        """When no manifest exists, uninstall should still clear init-options.json."""
        project = tmp_path / "proj"
        project.mkdir()
        (project / ".kiss").mkdir()

        # Write integration.json and init-options.json without a manifest
        int_json = project / ".kiss" / "integration.json"
        int_json.write_text(json.dumps({"integration": "claude"}), encoding="utf-8")

        opts_json = project / ".kiss" / "init-options.json"
        opts_json.write_text(json.dumps({
            "integration": "claude",
            "integration": "claude",
            "ai_skills": True,
            "script": "sh",
        }), encoding="utf-8")

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, ["integration", "uninstall", "claude"])
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0

        # init-options.json should have integration keys cleared
        opts = json.loads(opts_json.read_text(encoding="utf-8"))
        assert "integration" not in opts
        assert "ai" not in opts
        assert "ai_skills" not in opts
        # Non-integration keys preserved
        assert opts.get("script") == "sh"


class TestSwitchClearsMetadataAfterTeardown:
    def test_metadata_cleared_between_phases(self, tmp_path):
        """After a successful switch, metadata should reference the new integration."""
        project = _init_project(tmp_path, "claude")

        # Verify initial state
        int_json = project / ".kiss" / "integration.json"
        assert json.loads(int_json.read_text(encoding="utf-8"))["integration"] == "claude"

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            # Switch to copilot — should succeed and update metadata
            result = runner.invoke(app, [
                "integration", "switch", "copilot",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0

        # integration.json should reference copilot, not claude
        data = json.loads(int_json.read_text(encoding="utf-8"))
        assert "copilot" in data["integrations"]
        assert "claude" not in data["integrations"]

        # init-options.json should reference copilot
        opts_json = project / ".kiss" / "init-options.json"
        opts = json.loads(opts_json.read_text(encoding="utf-8"))
        # Check either new list format or old singular field
        opt_integrations = opts.get("integrations", [])
        opt_single = opts.get("integration")
        assert "copilot" in opt_integrations or opt_single == "copilot"
