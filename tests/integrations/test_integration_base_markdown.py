"""Reusable test mixin for standard MarkdownIntegration subclasses.

Each per-agent test file sets ``KEY``, ``FOLDER``, ``COMMANDS_SUBDIR``,
``REGISTRAR_DIR``, and ``CONTEXT_FILE``, then inherits all verification
logic from ``MarkdownIntegrationTests``.
"""

import os
from pathlib import Path

from kiss_cli.integrations import INTEGRATION_REGISTRY, get_integration
from kiss_cli.integrations.base import MarkdownIntegration
from kiss_cli.integrations.manifest import IntegrationManifest


class MarkdownIntegrationTests:
    """Mixin — set class-level constants and inherit these tests.

    Required class attrs on subclass::

        KEY: str              — integration registry key
        FOLDER: str           — e.g. ".claude/"
        COMMANDS_SUBDIR: str  — e.g. "commands"
        REGISTRAR_DIR: str    — e.g. ".claude/commands"
        CONTEXT_FILE: str     — e.g. "CLAUDE.md"
    """

    KEY: str
    FOLDER: str
    COMMANDS_SUBDIR: str
    REGISTRAR_DIR: str
    CONTEXT_FILE: str

    # -- Registration -----------------------------------------------------

    def test_registered(self):
        assert self.KEY in INTEGRATION_REGISTRY
        assert get_integration(self.KEY) is not None

    def test_is_markdown_integration(self):
        assert isinstance(get_integration(self.KEY), MarkdownIntegration)

    # -- Config -----------------------------------------------------------

    def test_config_folder(self):
        i = get_integration(self.KEY)
        assert i.config["folder"] == self.FOLDER

    def test_config_commands_subdir(self):
        i = get_integration(self.KEY)
        assert i.config["skills_subdir"] == self.COMMANDS_SUBDIR

    def test_registrar_config(self):
        i = get_integration(self.KEY)
        assert i.registrar_config["dir"] == self.REGISTRAR_DIR
        assert i.registrar_config["format"] == "markdown"
        assert i.registrar_config["args"] == "$ARGUMENTS"
        assert i.registrar_config["extension"] == ".md"

    def test_context_file(self):
        i = get_integration(self.KEY)
        assert i.context_file == self.CONTEXT_FILE

    # -- Setup / teardown -------------------------------------------------

    @staticmethod
    def _command_files(created, commands_dest):
        """Filter ``created`` paths down to just the installed command files.

        Each command lives at ``<commands_dest>/kiss.<stem>/kiss.<stem>.md``.
        Bundled scripts and templates are siblings under the same per-skill
        folder and are excluded.
        """
        commands_dest = commands_dest.resolve()
        return [
            f for f in created
            if f.suffix == ".md"
            and f.name.startswith("kiss.")
            and f.parent.parent.resolve() == commands_dest
        ]

    def test_setup_creates_files(self, tmp_path):
        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        created = i.setup(tmp_path, m)
        assert len(created) > 0
        cmd_files = self._command_files(created, i.commands_dest(tmp_path))
        assert len(cmd_files) > 0, "No command files were created"
        for f in cmd_files:
            assert f.exists()
            assert f.name.startswith("kiss.")
            assert f.name.endswith(".md")

    def test_setup_writes_to_correct_directory(self, tmp_path):
        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        created = i.setup(tmp_path, m)
        expected_dir = i.commands_dest(tmp_path)
        assert expected_dir.exists(), f"Expected directory {expected_dir} was not created"
        cmd_files = self._command_files(created, expected_dir)
        assert len(cmd_files) > 0, "No command files were created"
        for f in cmd_files:
            # Each command is nested one level deep in its per-skill folder.
            assert f.resolve().parent.parent == expected_dir.resolve(), (
                f"{f} is not directly under {expected_dir}/<per-skill>/"
            )

    def test_templates_are_processed(self, tmp_path):
        """Command files must have placeholders replaced, not raw templates."""
        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        created = i.setup(tmp_path, m)
        cmd_files = self._command_files(created, i.commands_dest(tmp_path))
        assert len(cmd_files) > 0
        for f in cmd_files:
            content = f.read_text(encoding="utf-8")
            assert "{SCRIPT}" not in content, f"{f.name} has unprocessed {{SCRIPT}}"
            assert "__AGENT__" not in content, f"{f.name} has unprocessed __AGENT__"
            assert "{ARGS}" not in content, f"{f.name} has unprocessed {{ARGS}}"
            assert "\nscripts:\n" not in content, f"{f.name} has unstripped scripts: block"

    def test_plan_references_correct_context_file(self, tmp_path):
        """The generated plan command must reference this integration's context file."""
        i = get_integration(self.KEY)
        if not i.context_file:
            return
        m = IntegrationManifest(self.KEY, tmp_path)
        i.setup(tmp_path, m)
        plan_filename = i.command_filename("plan")
        # Per-skill folder layout: <commands_dest>/kiss.plan/kiss.plan.md
        plan_file = i.commands_dest(tmp_path) / Path(plan_filename).stem / plan_filename
        if not plan_file.exists():
            # Skills integrations use a different file layout.
            plan_file = i.commands_dest(tmp_path) / plan_filename
        assert plan_file.exists(), f"Plan file {plan_file} not created"
        content = plan_file.read_text(encoding="utf-8")
        assert i.context_file in content, (
            f"Plan command should reference {i.context_file!r} but it was not found in {plan_file.name}"
        )
        assert "__CONTEXT_FILE__" not in content, (
            f"Plan command has unprocessed __CONTEXT_FILE__ placeholder in {plan_file.name}"
        )

    def test_all_files_tracked_in_manifest(self, tmp_path):
        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        created = i.setup(tmp_path, m)
        for f in created:
            rel = f.resolve().relative_to(tmp_path.resolve()).as_posix()
            assert rel in m.files, f"{rel} not tracked in manifest"

    def test_install_uninstall_roundtrip(self, tmp_path):
        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        created = i.install(tmp_path, m)
        assert len(created) > 0
        m.save()
        for f in created:
            assert f.exists()
        removed, skipped = i.uninstall(tmp_path, m)
        assert len(removed) == len(created)
        assert skipped == []

    def test_modified_file_survives_uninstall(self, tmp_path):
        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        created = i.install(tmp_path, m)
        m.save()
        modified_file = created[0]
        modified_file.write_text("user modified this", encoding="utf-8")
        removed, skipped = i.uninstall(tmp_path, m)
        assert modified_file.exists()
        assert modified_file in skipped

    # -- Context section ---------------------------------------------------

    def test_setup_upserts_context_section(self, tmp_path):
        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        i.setup(tmp_path, m)
        if i.context_file:
            ctx_path = tmp_path / i.context_file
            assert ctx_path.exists(), f"Context file {i.context_file} not created for {self.KEY}"
            content = ctx_path.read_text(encoding="utf-8")
            assert "<!-- KISS START -->" in content
            assert "<!-- KISS END -->" in content
            assert "read the current plan" in content

    def test_teardown_removes_context_section(self, tmp_path):
        i = get_integration(self.KEY)
        m = IntegrationManifest(self.KEY, tmp_path)
        i.setup(tmp_path, m)
        m.save()
        if i.context_file:
            ctx_path = tmp_path / i.context_file
            # Add user content around the section
            content = ctx_path.read_text(encoding="utf-8")
            ctx_path.write_text("# My Rules\n\n" + content + "\n# Footer\n", encoding="utf-8")
            i.teardown(tmp_path, m)
            remaining = ctx_path.read_text(encoding="utf-8")
            assert "<!-- KISS START -->" not in remaining
            assert "<!-- KISS END -->" not in remaining
            assert "# My Rules" in remaining

    # -- CLI auto-promote -------------------------------------------------

    def test_ai_flag_auto_promotes(self, tmp_path):
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / f"promote-{self.KEY}"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(app, [
                "init", "--here", "--integration", self.KEY, "--no-git",
                "--ignore-agent-tools",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, f"init --integration {self.KEY} failed: {result.output}"
        i = get_integration(self.KEY)
        cmd_dir = i.commands_dest(project)
        assert cmd_dir.is_dir(), f"--integration {self.KEY} did not create commands directory"

    def test_integration_flag_creates_files(self, tmp_path):
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / f"int-{self.KEY}"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            runner = CliRunner()
            result = runner.invoke(app, [
                "init", "--here", "--integration", self.KEY, "--no-git",
                "--ignore-agent-tools",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, f"init --integration {self.KEY} failed: {result.output}"
        i = get_integration(self.KEY)
        cmd_dir = i.commands_dest(project)
        assert cmd_dir.is_dir(), f"Commands directory {cmd_dir} not created"
        commands = sorted(cmd_dir.glob("kiss.*"))
        assert len(commands) > 0, f"No command files in {cmd_dir}"

    def test_init_options_includes_context_file(self, tmp_path):
        """init-options.json must include context_file for the active integration."""
        import json
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / f"opts-{self.KEY}"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = CliRunner().invoke(app, [
                "init", "--here", "--integration", self.KEY, "--no-git", "--ignore-agent-tools",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0
        opts = json.loads((project / ".kiss" / "init-options.json").read_text())
        i = get_integration(self.KEY)
        assert opts.get("context_file") == i.context_file, (
            f"Expected context_file={i.context_file!r}, got {opts.get('context_file')!r}"
        )

    # -- Complete file inventory ------------------------------------------

    def _expected_files(self) -> list[str]:
        """Build the expected file list dynamically from source assets.

        The installer always installs both bash and PowerShell scripts
        and bundles per-command scripts/templates alongside each command
        file (rather than using shared .kiss/scripts/ or .kiss/templates/).
        """
        from kiss_cli.skill_assets import list_skill_dirs
        from pathlib import Path

        i = get_integration(self.KEY)
        cmd_dir = i.registrar_config["dir"]
        ext = i.registrar_config.get("extension", ".md")

        files: list[str] = []

        # Per-command bundles: <cmd_name><extension> + scripts/**/* (excl. __pycache__) + templates/**/*
        for skill_dir in list_skill_dirs():
            stem = skill_dir.name.removeprefix("kiss-")
            cmd_name = f"kiss.{stem}"
            files.append(f"{cmd_dir}/{cmd_name}/{cmd_name}{ext}")
            for sub in ("scripts", "templates"):
                sub_dir = skill_dir / sub
                if sub_dir.is_dir():
                    for f in sub_dir.rglob("*"):
                        if f.is_file() and "__pycache__" not in f.parts:
                            rel = f.relative_to(skill_dir).as_posix()
                            files.append(f"{cmd_dir}/{cmd_name}/{rel}")

        # Custom agents — installed under <folder>/<agents_subdir>/
        custom_agents_dest = i.custom_agents_dest(Path("."))
        if custom_agents_dest is not None:
            agents_prefix = custom_agents_dest.relative_to(".").as_posix()
            repo_root = Path(__file__).resolve().parent.parent.parent
            for md in sorted((repo_root / "subagents").glob("*.md")):
                files.append(f"{agents_prefix}/{md.name}")

        # Common .kiss state files
        files += [
            ".kiss/context.yml",
            ".kiss/init-options.json",
            ".kiss/integration.json",
            f".kiss/integrations/{self.KEY}.manifest.json",
            ".kiss/workflows/kiss/workflow.yml",
            ".kiss/workflows/workflow-registry.json",
        ]

        # Agent context file (if set)
        if i.context_file:
            files.append(i.context_file)

        return sorted(files)

    def test_complete_file_inventory(self, tmp_path):
        """Every file produced by ``kiss init --integration <key>``.

        The installer always installs both bash and PowerShell scripts;
        there is no per-shell variant flag.
        """
        from typer.testing import CliRunner
        from kiss_cli import app

        project = tmp_path / f"inventory-{self.KEY}"
        project.mkdir()
        old_cwd = os.getcwd()
        try:
            os.chdir(project)
            result = CliRunner().invoke(app, [
                "init", "--here", "--integration", self.KEY, "--no-git", "--ignore-agent-tools",
            ], catch_exceptions=False)
        finally:
            os.chdir(old_cwd)
        assert result.exit_code == 0, f"init failed: {result.output}"
        actual = sorted(p.relative_to(project).as_posix()
                        for p in project.rglob("*") if p.is_file())
        expected = self._expected_files()
        assert actual == expected, (
            f"Missing: {sorted(set(expected) - set(actual))}\n"
            f"Extra: {sorted(set(actual) - set(expected))}"
        )
