"""Tests for CodexIntegration."""

from .test_integration_base_skills import SkillsIntegrationTests


class TestCodexIntegration(SkillsIntegrationTests):
    KEY = "codex"
    FOLDER = ".codex/"
    COMMANDS_SUBDIR = "skills"
    REGISTRAR_DIR = ".codex/skills"
    CONTEXT_FILE = "AGENTS.md"


class TestCodexIntegrationInstall:
    """--integration codex installs the codex integration."""

    def test_integration_codex_installs_successfully(self, tmp_path):
        """--integration codex should install the codex integration and exit 0."""
        from typer.testing import CliRunner
        from kiss_cli import app

        runner = CliRunner()
        target = tmp_path / "test-proj"
        result = runner.invoke(app, ["init", str(target), "--integration", "codex", "--no-git", "--ignore-agent-tools", ])

        assert result.exit_code == 0, f"init --integration codex failed: {result.output}"
        assert (target / ".codex" / "skills" / "kiss-plan" / "SKILL.md").exists()
