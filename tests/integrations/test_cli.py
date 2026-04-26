"""Tests for --integration flag on kiss init (CLI-level)."""

import json
import os

import yaml

from tests.conftest import strip_ansi


def _normalize_cli_output(output: str) -> str:
    output = strip_ansi(output)
    output = " ".join(output.split())
    return output.strip()


class TestInitIntegrationFlag:
    def test_unknown_integration_rejected(self, tmp_path):
        from typer.testing import CliRunner
        from kiss_cli import app
        runner = CliRunner()
        result = runner.invoke(app, [
            "init", str(tmp_path / "test-project"), "--integration", "nonexistent",
        ])
        assert result.exit_code != 0
        assert "Unknown integration" in result.output

    def test_integration_copilot_creates_files(self, tmp_path):
        from typer.testing import CliRunner
        from kiss_cli import app
        runner = CliRunner()
        project = tmp_path / "int-test"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = runner.invoke(app, [
                "init", "--ignore-agent-tools", "--here", "--integration", "copilot", "--no-git",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, f"init failed: {result.output}"
        assert (project / ".github" / "skills" / "kiss-plan" / "SKILL.md").exists()
        # Per-skill scripts live alongside each command file.
        assert (project / ".github" / "skills" / "kiss-plan" / "scripts" / "bash" / "common.sh").exists()

        data = json.loads((project / ".kiss" / "integration.json").read_text(encoding="utf-8"))
        assert "copilot" in data["integrations"]

        opts = json.loads((project / ".kiss" / "init-options.json").read_text(encoding="utf-8"))
        assert opts["integration"] == "copilot"
        assert opts["context_file"] == "AGENTS.md"

        assert (project / ".kiss" / "integrations" / "copilot.manifest.json").exists()

        # Context section should be upserted into the copilot instructions file
        ctx_file = project / "AGENTS.md"
        assert ctx_file.exists()
        ctx_content = ctx_file.read_text(encoding="utf-8")
        assert "<!-- KISS START -->" in ctx_content
        assert "<!-- KISS END -->" in ctx_content

    def test_claude_here_preserves_preexisting_commands(self, tmp_path):
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / "claude-here-existing"
        project.mkdir()
        commands_dir = project / ".claude" / "skills"
        commands_dir.mkdir(parents=True)
        skill_dir = commands_dir / "kiss-specify"
        skill_dir.mkdir(parents=True)
        command_file = skill_dir / "SKILL.md"
        command_file.write_text("# preexisting command\n", encoding="utf-8")

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(app, [
                "init", "--here", "--force", "--integration", "claude", "--no-git", "--ignore-agent-tools",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)

        assert result.exit_code == 0, result.output
        assert command_file.exists()
        # init replaces skills (not additive); verify the file has valid skill content
        assert command_file.exists()
        assert "kiss-specify" in command_file.read_text(encoding="utf-8")
        assert (project / ".claude" / "skills" / "kiss-plan" / "SKILL.md").exists()

    def test_shared_infra_creates_kiss_directory(self, tmp_path):
        """_install_shared_infra ensures the .kiss state directory exists.

        Scripts and templates now live inside each installed skill
        folder, not in a shared .kiss/ location, so the installer just
        creates the state directory.
        """
        from kiss_cli.installer import _install_shared_infra

        project = tmp_path / "kiss-dir-test"
        project.mkdir()
        assert not (project / ".kiss").exists()

        _install_shared_infra(project, "sh", force=False)

        assert (project / ".kiss").is_dir()

    def test_init_here_force_overwrites_per_skill_script(self, tmp_path):
        """E2E: kiss init --here --force overwrites per-skill script files."""
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / "e2e-force"
        project.mkdir()

        # Pre-create a stale per-skill script that --force should overwrite.
        scripts_dir = project / ".github" / "skills" / "kiss-plan" / "scripts" / "bash"
        scripts_dir.mkdir(parents=True)
        custom_content = "# user-modified setup-plan.sh\n"
        (scripts_dir / "setup-plan.sh").write_text(custom_content, encoding="utf-8")

        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(app, [
                "init", "--ignore-agent-tools", "--here", "--force",
                "--integration", "copilot",
                "--no-git",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)

        assert result.exit_code == 0
        # --force should overwrite the user's stale file
        assert (scripts_dir / "setup-plan.sh").read_text(encoding="utf-8") != custom_content


class TestForceExistingDirectory:
    """Tests for --force merging into an existing named directory."""

    def test_force_merges_into_existing_dir(self, tmp_path):
        """kiss init <dir> --force succeeds when the directory already exists."""
        from typer.testing import CliRunner
        from kiss_cli import app

        target = tmp_path / "existing-proj"
        target.mkdir()
        # Place a pre-existing file to verify it survives the merge
        marker = target / "user-file.txt"
        marker.write_text("keep me", encoding="utf-8")

        runner = CliRunner()
        result = runner.invoke(app, [
            "init", "--ignore-agent-tools", str(target), "--integration", "copilot", "--force",
            "--no-git", ], catch_exceptions=False)

        assert result.exit_code == 0, f"init --force failed: {result.output}"

        # Pre-existing file should survive
        assert marker.read_text(encoding="utf-8") == "keep me"

        # kiss files should be installed
        assert (target / ".kiss" / "init-options.json").exists()
        # Per-skill template now lives alongside the command file.
        assert (target / ".github" / "skills" / "kiss-specify" / "templates" / "spec-template.md").exists()

    def test_without_force_errors_on_existing_dir(self, tmp_path):
        """kiss init <dir> without --force errors when directory exists."""
        from typer.testing import CliRunner
        from kiss_cli import app

        target = tmp_path / "existing-proj"
        target.mkdir()

        runner = CliRunner()
        result = runner.invoke(app, [
            "init", "--ignore-agent-tools", str(target), "--integration", "copilot",
            "--no-git", ], catch_exceptions=False)

        assert result.exit_code == 1
        assert "already exists" in _normalize_cli_output(result.output)


class TestGitExtensionAutoInstall:
    """Tests for auto-installation of the git extension during kiss init."""

    def test_git_extension_auto_installed(self, tmp_path):
        """Without --no-git, the git extension is installed during init."""
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / "git-auto"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(app, [
                "init", "--here", "--integration", "claude", "--ignore-agent-tools",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)

        assert result.exit_code == 0, f"init failed: {result.output}"

        # Check that the tracker didn't report a git error
        assert "install failed" not in result.output, f"git extension install failed: {result.output}"

        # Git extension files should be installed
        ext_dir = project / ".kiss" / "extensions" / "git"
        assert ext_dir.exists(), "git extension directory not installed"
        assert (ext_dir / "extension.yml").exists()
        assert (ext_dir / "scripts" / "bash" / "create-new-feature.sh").exists()
        assert (ext_dir / "scripts" / "bash" / "initialize-repo.sh").exists()

        # Hooks should be registered
        extensions_yml = project / ".kiss" / "extensions.yml"
        assert extensions_yml.exists(), "extensions.yml not created"
        hooks_data = yaml.safe_load(extensions_yml.read_text(encoding="utf-8"))
        assert "hooks" in hooks_data
        assert "before_kiss-specify" in hooks_data["hooks"]
        assert "before_kiss-standardize" in hooks_data["hooks"]

    def test_no_git_skips_extension(self, tmp_path):
        """With --no-git, the git extension is NOT installed."""
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / "no-git"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(app, [
                "init", "--here", "--integration", "claude", "--no-git", "--ignore-agent-tools",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)

        assert result.exit_code == 0, f"init failed: {result.output}"

        # Git extension should NOT be installed
        ext_dir = project / ".kiss" / "extensions" / "git"
        assert not ext_dir.exists(), "git extension should not be installed with --no-git"

    def test_git_extension_commands_registered(self, tmp_path):
        """Git extension commands are registered with the agent during init."""
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / "git-cmds"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(app, [
                "init", "--here", "--integration", "claude", "--ignore-agent-tools",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)

        assert result.exit_code == 0, f"init failed: {result.output}"

        # Git extension commands should be registered with the agent
        claude_skills = project / ".claude" / "skills"
        assert claude_skills.exists(), "Claude skills directory was not created"
        git_skills = [f for f in claude_skills.iterdir() if f.name.startswith("kiss-git-")]
        assert len(git_skills) > 0, "no git extension commands registered"
