"""The `kiss init` project-bootstrap command."""

# ruff: noqa: E402, F401  — Typer command modules
# This module is auto-migrated from the former monolithic kiss_cli/__init__.py.
# All @app.command() / @<group>_app.command() decorators fire at import time,
# which is why cli/__init__.py imports this module explicitly.

import json
import os
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path
from typing import Any, Optional

import json5
import typer
import yaml
from rich.align import Align
from rich.console import Console
from rich.live import Live
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from rich.tree import Tree

import readchar

# Shared helpers (extracted in earlier Phase 6 work)
from kiss_cli.ui import (
    BannerGroup,
    get_key,
    multi_select_integrations,
    show_banner,
    _version_callback,
)
from kiss_cli.tracker import StepTracker
from kiss_cli.installer import (
    _build_agent_config,
    run_command,
    check_tool,
    is_git_repo,
    init_git_repo,
    handle_vscode_settings,
    merge_json_files,
    _locate_core_pack,
    _locate_bundled_extension,
    _locate_bundled_workflow,
    _locate_bundled_preset,
    _install_shared_infra,
    ensure_executable_scripts,
    _get_skills_dir,
    _read_integration_json,
    _write_integration_json,
    _remove_integration_json,
)
from kiss_cli.context import create_context_file, load_context_file, save_context_file
from kiss_cli.config import save_init_options, load_init_options
from kiss_cli.version import get_kiss_version

# Constants that commands use
from kiss_cli.installer import CLAUDE_LOCAL_PATH, CLAUDE_NPM_LOCAL_PATH

# The main Typer app created in kiss_cli.cli.__init__
from . import app

console = Console(highlight=False)

# Package-level symbols used by commands
from kiss_cli import AGENT_CONFIG

@app.command()
def init(
    project_name: str = typer.Argument(None, help="Name for your new project directory (optional if using --here, or use '.' for current directory)"),
    ignore_agent_tools: bool = typer.Option(False, "--ignore-agent-tools", help="Skip checks for AI agent tools like Claude Code"),
    no_git: bool = typer.Option(False, "--no-git", help="Skip git repository initialization"),
    here: bool = typer.Option(False, "--here", help="Initialize project in the current directory instead of creating a new one"),
    force: bool = typer.Option(False, "--force", help="Force merge/overwrite when using --here (skip confirmation)"),
    preset: str = typer.Option(None, "--preset", help="Install a preset during initialization (by preset ID)"),
    branch_numbering: str = typer.Option(None, "--branch-numbering", help="Branch numbering strategy: 'sequential' (001, 002, …, 1000, … — expands past 999 automatically) or 'timestamp' (YYYYMMDD-HHMMSS)"),
    integration: str = typer.Option(None, "--integration", help="Install a single integration non-interactively (e.g. --integration claude). Omit to use the interactive multi-select picker."),
    integration_options: str = typer.Option(None, "--integration-options", help='Options for the integration (e.g. --integration-options="--commands-dir .myagent/cmds")'),
):
    """
    Initialize a new kiss project.

    Scaffolds the project entirely from assets bundled inside the `kiss`
    package — no network access is required or performed.

    This command will:
    1. Check that required tools are installed (git is optional)
    2. Let you choose one or more AI providers (multi-select)
    3. Copy bundled templates, scripts, and context file into the project
    4. Initialize a fresh git repository (unless `--no-git`)
    5. Set up each selected AI provider's skills / commands

    Examples:
        kiss init my-project                       # interactive multi-select
        kiss init my-project --integration claude  # single-integration, non-interactive
        kiss init .                                # initialize in current directory
        kiss init --here --force                   # merge into non-empty current dir
        kiss init my-project --preset healthcare-compliance
        kiss init my-project --integration generic --integration-options="--commands-dir .myagent/commands/"
    """

    show_banner()

    # Resolve --integration non-interactively if provided
    from ..integrations import INTEGRATION_REGISTRY, get_integration
    ai_assistant: str | None = None
    resolved_integration = None
    if integration:
        resolved_integration = get_integration(integration)
        if not resolved_integration:
            console.print(f"[red]Error:[/red] Unknown integration: '{integration}'")
            available = ", ".join(sorted(INTEGRATION_REGISTRY))
            console.print(f"[yellow]Available integrations:[/yellow] {available}")
            raise typer.Exit(1)
        ai_assistant = integration

    if project_name == ".":
        here = True
        project_name = None  # Clear project_name to use existing validation logic

    if here and project_name:
        console.print("[red]Error:[/red] Cannot specify both project name and --here flag")
        raise typer.Exit(1)

    if not here and not project_name:
        console.print("[red]Error:[/red] Must specify either a project name, use '.' for current directory, or use --here flag")
        raise typer.Exit(1)

    BRANCH_NUMBERING_CHOICES = {"sequential", "timestamp"}
    if branch_numbering and branch_numbering not in BRANCH_NUMBERING_CHOICES:
        console.print(f"[red]Error:[/red] Invalid --branch-numbering value '{branch_numbering}'. Choose from: {', '.join(sorted(BRANCH_NUMBERING_CHOICES))}")
        raise typer.Exit(1)

    dir_existed_before = False
    if here:
        project_name = Path.cwd().name
        project_path = Path.cwd()
        dir_existed_before = True

        existing_items = list(project_path.iterdir())
        if existing_items:
            console.print(f"[yellow]Warning:[/yellow] Current directory is not empty ({len(existing_items)} items)")
            console.print("[yellow]Template files will be merged with existing content and may overwrite existing files[/yellow]")
            if force:
                console.print("[cyan]--force supplied: skipping confirmation and proceeding with merge[/cyan]")
            else:
                response = typer.confirm("Do you want to continue?")
                if not response:
                    console.print("[yellow]Operation cancelled[/yellow]")
                    raise typer.Exit(0)
    else:
        project_path = Path(project_name).resolve()
        dir_existed_before = project_path.exists()
        if project_path.exists():
            if not project_path.is_dir():
                console.print(f"[red]Error:[/red] '{project_name}' exists but is not a directory.")
                raise typer.Exit(1)
            existing_items = list(project_path.iterdir())
            if force:
                if existing_items:
                    console.print(f"[yellow]Warning:[/yellow] Directory '{project_name}' is not empty ({len(existing_items)} items)")
                    console.print("[yellow]Template files will be merged with existing content and may overwrite existing files[/yellow]")
                console.print(f"[cyan]--force supplied: merging into existing directory '[cyan]{project_name}[/cyan]'[/cyan]")
            else:
                error_panel = Panel(
                    f"Directory already exists: '[cyan]{project_name}[/cyan]'\n"
                    "Please choose a different project name or remove the existing directory.\n"
                    "Use [bold]--force[/bold] to merge into the existing directory.",
                    title="[red]Directory Conflict[/red]",
                    border_style="red",
                    padding=(1, 2)
                )
                console.print()
                console.print(error_panel)
                raise typer.Exit(1)

    if ai_assistant:
        if ai_assistant not in AGENT_CONFIG:
            console.print(f"[red]Error:[/red] Invalid AI assistant '{ai_assistant}'. Choose from: {', '.join(AGENT_CONFIG.keys())}")
            raise typer.Exit(1)
        selected_ais = [ai_assistant]
    else:
        # Create options dict for multi-selection (agent_key: display_name)
        ai_choices = {key: config["name"] for key, config in AGENT_CONFIG.items()}
        selected_ais = multi_select_integrations(
            ai_choices,
            "Select AI providers (Space to toggle, Enter to confirm)",
            {"claude"}  # Default to Claude
        )

    # Validate all selected agents resolve to integrations
    resolved_integrations: dict[str, Any] = {}
    for selected_ai in selected_ais:
        resolved = get_integration(selected_ai)
        if not resolved:
            console.print(f"[red]Error:[/red] Unknown agent '{selected_ai}'")
            raise typer.Exit(1)
        resolved_integrations[selected_ai] = resolved

    # Generic integration requires a commands directory; it must come via
    # --integration-options="--commands-dir <dir>".
    if len(selected_ais) == 1 and selected_ais[0] == "generic" and not integration_options:
        console.print("[red]Error:[/red] --integration-options is required when using --integration generic")
        console.print('[dim]Example: kiss init my-project --integration generic --integration-options="--commands-dir .myagent/commands/"[/dim]')
        raise typer.Exit(1)

    current_dir = Path.cwd()

    setup_lines = [
        "[cyan]kiss Project Setup[/cyan]",
        "",
        f"{'Project':<15} [green]{project_path.name}[/green]",
        f"{'Working Path':<15} [dim]{current_dir}[/dim]",
    ]

    if not here:
        setup_lines.append(f"{'Target Path':<15} [dim]{project_path}[/dim]")

    console.print(Panel("\n".join(setup_lines), border_style="cyan", padding=(1, 2)))

    should_init_git = False
    if not no_git:
        should_init_git = check_tool("git")
        if not should_init_git:
            console.print("[yellow]Git not found - will skip repository initialization[/yellow]")

    if not ignore_agent_tools:
        # Check first selected AI (primary agent)
        primary_ai = selected_ais[0]
        agent_config = AGENT_CONFIG.get(primary_ai)
        if agent_config and agent_config["requires_cli"]:
            install_url = agent_config["install_url"]
            if not check_tool(primary_ai):
                error_panel = Panel(
                    f"[cyan]{primary_ai}[/cyan] not found\n"
                    f"Install from: [cyan]{install_url}[/cyan]\n"
                    f"{agent_config['name']} is required to continue with this project type.\n\n"
                    "Tip: Use [cyan]--ignore-agent-tools[/cyan] to skip this check",
                    title="[red]Agent Detection Error[/red]",
                    border_style="red",
                    padding=(1, 2)
                )
                console.print()
                console.print(error_panel)
                raise typer.Exit(1)

    # Script variant is selected at runtime from the current platform. Both
    # bash/ and powershell/ are always bundled into each skill folder, so
    # downstream tools can pick whichever they need.
    runtime_script_type = "ps" if os.name == "nt" else "sh"

    console.print(f"[cyan]Selected AI providers:[/cyan] {', '.join(selected_ais)}")

    tracker = StepTracker("Initialize kiss Project")

    sys._kiss_tracker_active = True

    tracker.add("precheck", "Check required tools")
    tracker.complete("precheck", "ok")
    tracker.add("ai-select", "Select AI providers")
    tracker.complete("ai-select", f"{len(selected_ais)} provider(s)")

    tracker.add("integrations", "Install integrations")
    tracker.add("shared-infra", "Initialise .kiss/ state directory")

    for key, label in [
        ("chmod", "Ensure scripts executable"),
        ("git", "Install git extension"),
        ("workflow", "Install bundled workflow"),
        ("final", "Finalize"),
    ]:
        tracker.add(key, label)

    with Live(tracker.render(), console=console, refresh_per_second=8, transient=True) as live:
        tracker.attach_refresh(lambda: live.update(tracker.render()))
        try:
            # Multi-integration scaffolding loop
            from ..integrations.manifest import IntegrationManifest
            tracker.start("integrations")

            install_conflicts: list[tuple[str, Path]] = []  # (integration_key, destination_path)
            written_paths: dict[Path, str] = {}              # dest -> integration key that wrote it
            installed_keys: list[str] = []

            for integration_key in selected_ais:
                resolved_integration = resolved_integrations[integration_key]
                manifest = IntegrationManifest(
                    resolved_integration.key, project_path, version=get_kiss_version()
                )

                resolved_integration.setup(
                    project_path, manifest,
                    parsed_options=None,
                    script_type=runtime_script_type,
                    raw_options=integration_options,
                )
                manifest.save()
                installed_keys.append(integration_key)

                # Track written paths for conflict detection
                for rel_path in manifest.files.keys():
                    dest_path = project_path / rel_path
                    if dest_path in written_paths:
                        install_conflicts.append((integration_key, dest_path))
                    else:
                        written_paths[dest_path] = integration_key

            # Write .kiss/integration.json. ``integration`` (singular) keeps
            # parity with ``kiss integration install/uninstall`` which operate
            # on a single key; ``integrations`` (plural) tracks the full
            # multi-select list for ``kiss upgrade`` and similar tooling.
            integration_json = project_path / ".kiss" / "integration.json"
            integration_json.parent.mkdir(parents=True, exist_ok=True)
            integration_json.write_text(json.dumps({
                "integration": installed_keys[0] if installed_keys else None,
                "integrations": installed_keys,
                "version": get_kiss_version(),
            }, indent=2) + "\n", encoding="utf-8")

            tracker.complete("integrations", f"{len(installed_keys)} installed")

            # Verify asset integrity before reading the bundle
            from kiss_cli._integrity import verify_asset_integrity, AssetCorruptionError
            core_pack = _locate_core_pack()
            if core_pack:
                try:
                    verify_asset_integrity(core_pack)
                except AssetCorruptionError as e:
                    console.print(f"[red]Error:[/red] Bundled asset integrity check failed: {e}")
                    console.print("The kiss installation may be corrupted. Reinstall with: uv tool install kiss --force")
                    raise typer.Exit(1)

            # Install shared infrastructure (scripts, templates)
            tracker.start("shared-infra")
            _install_shared_infra(project_path, tracker=tracker, force=force)
            tracker.complete("shared-infra", ".kiss/ created")

            # Deploy bundled custom agents into each installed integration's
            # subagents folder (e.g. .claude/agents/ for Claude, etc.).
            from kiss_cli.installer import install_custom_agents
            custom_agents_results = install_custom_agents(
                project_path, installed_keys, force=force,
            )
            total_custom_agents = sum(custom_agents_results.values())
            if total_custom_agents:
                console.print(
                    f"[cyan]Installed {total_custom_agents} custom agent file(s) "
                    f"across {len(custom_agents_results)} integration(s).[/cyan]"
                )

            # Create or merge context.yml (Phase 5.6)
            from kiss_cli.context import merge_context_file
            context_path = project_path / ".kiss" / "context.yml"
            if context_path.exists() and here:
                merge_context_file(project_path, new_integrations=installed_keys)
            else:
                create_context_file(project_path, integrations=installed_keys)

            if not no_git:
                tracker.start("git")
                git_messages = []
                git_has_error = False
                # Step 1: Initialize git repo if needed
                if is_git_repo(project_path):
                    git_messages.append("existing repo detected")
                elif should_init_git:
                    success, error_msg = init_git_repo(project_path, quiet=True)
                    if success:
                        git_messages.append("initialized")
                    else:
                        git_has_error = True
                        # Sanitize multi-line error_msg to single line for tracker
                        if error_msg:
                            sanitized = error_msg.replace('\n', ' ').strip()
                            git_messages.append(f"init failed: {sanitized[:120]}")
                        else:
                            git_messages.append("init failed")
                else:
                    git_messages.append("git not available")
                # Step 2: Install bundled git extension
                try:
                    from kiss_cli.extensions import ExtensionManager
                    bundled_path = _locate_bundled_extension("git")
                    if bundled_path:
                        manager = ExtensionManager(project_path)
                        if manager.registry.is_installed("git"):
                            git_messages.append("extension already installed")
                        else:
                            manager.install_from_directory(
                                bundled_path, get_kiss_version()
                            )
                            git_messages.append("extension installed")
                    else:
                        git_has_error = True
                        git_messages.append("bundled extension not found")
                except Exception as ext_err:
                    git_has_error = True
                    sanitized_ext = str(ext_err).replace('\n', ' ').strip()
                    git_messages.append(
                        f"extension install failed: {sanitized_ext[:120]}"
                    )
                summary = "; ".join(git_messages)
                if git_has_error:
                    tracker.error("git", summary)
                else:
                    tracker.complete("git", summary)
            else:
                tracker.skip("git", "--no-git flag")

            # Install bundled kiss workflow
            try:
                bundled_wf = _locate_bundled_workflow("kiss")
                if bundled_wf:
                    from ..workflows.catalog import WorkflowRegistry
                    from ..workflows.engine import WorkflowDefinition
                    wf_registry = WorkflowRegistry(project_path)
                    if wf_registry.is_installed("kiss"):
                        tracker.complete("workflow", "already installed")
                    else:
                        import shutil as _shutil
                        dest_wf = project_path / ".kiss" / "workflows" / "kiss"
                        dest_wf.mkdir(parents=True, exist_ok=True)
                        _shutil.copy2(
                            bundled_wf / "workflow.yml",
                            dest_wf / "workflow.yml",
                        )
                        definition = WorkflowDefinition.from_yaml(dest_wf / "workflow.yml")
                        wf_registry.add("kiss", {
                            "name": definition.name,
                            "version": definition.version,
                            "description": definition.description,
                            "source": "bundled",
                        })
                        tracker.complete("workflow", "kiss installed")
                else:
                    tracker.skip("workflow", "bundled workflow not found")
            except Exception as wf_err:
                sanitized_wf = str(wf_err).replace('\n', ' ').strip()
                tracker.error("workflow", f"install failed: {sanitized_wf[:120]}")

            # Fix permissions after all installs (scripts + extensions)
            ensure_executable_scripts(project_path, tracker=tracker)

            # Persist the CLI options so later operations (e.g. preset add)
            # can adapt their behaviour without re-scanning the filesystem.
            # Must be saved BEFORE preset install so _get_skills_dir() works.
            # Pick the first selected integration as the primary for display-only decisions
            # (next-steps panel, agent tool checks).
            primary_integration = resolved_integrations[selected_ais[0]]
            init_opts = {
                "integration": primary_integration.key,
                "integrations": installed_keys,  # Phase 3: track all selected integrations
                "branch_numbering": branch_numbering or "sequential",
                "context_file": primary_integration.context_file,
                "here": here,
                "kiss_version": get_kiss_version(),
            }
            # Ensure ai_skills is set for SkillsIntegration so downstream
            # tools (extensions, presets) emit SKILL.md overrides correctly.
            from ..integrations.base import SkillsIntegration as _SkillsPersist
            if isinstance(primary_integration, _SkillsPersist):
                init_opts["ai_skills"] = True
            save_init_options(project_path, init_opts)

            # Report installation conflicts if any
            if install_conflicts:
                console.print()
                conflict_lines = ["[yellow]Installation Conflicts:[/yellow]"]
                for integration_key, dest_path in install_conflicts:
                    conflict_lines.append(f"  ○ [yellow]{dest_path.relative_to(project_path)}[/yellow] — skipped (already written by {written_paths.get(dest_path, 'unknown')})")
                console.print("\n".join(conflict_lines))
                console.print()

            # Install preset if specified
            if preset:
                try:
                    from kiss_cli.presets import PresetManager, PresetCatalog, PresetError
                    preset_manager = PresetManager(project_path)
                    kiss_ver = get_kiss_version()

                    # Try local directory first, then bundled, then catalog
                    local_path = Path(preset).resolve()
                    if local_path.is_dir() and (local_path / "preset.yml").exists():
                        preset_manager.install_from_directory(local_path, kiss_ver)
                    else:
                        bundled_path = _locate_bundled_preset(preset)
                        if bundled_path:
                            preset_manager.install_from_directory(bundled_path, kiss_ver)
                        else:
                            from kiss_cli.extensions import REINSTALL_COMMAND
                            console.print(
                                f"[yellow]Warning:[/yellow] Preset '{preset}' is not bundled with kiss "
                                f"and kiss is offline-only; skipping. "
                                f"If this preset should be bundled, try reinstalling: {REINSTALL_COMMAND}"
                            )
                except Exception as preset_err:
                    console.print(f"[yellow]Warning:[/yellow] Failed to install preset: {preset_err}")

            tracker.complete("final", "project ready")
        except (typer.Exit, SystemExit):
            raise
        except Exception as e:
            tracker.error("final", str(e))
            console.print(Panel(f"Initialization failed: {e}", title="Failure", border_style="red"))
            if os.environ.get("KISS_DEBUG"):
                _env_pairs = [
                    ("Python", sys.version.split()[0]),
                    ("Platform", sys.platform),
                    ("CWD", str(Path.cwd())),
                ]
                _label_width = max(len(k) for k, _ in _env_pairs)
                env_lines = [f"{k.ljust(_label_width)} → [bright_black]{v}[/bright_black]" for k, v in _env_pairs]
                console.print(Panel("\n".join(env_lines), title="Debug Environment", border_style="magenta"))
            if not here and project_path.exists() and not dir_existed_before:
                shutil.rmtree(project_path)
            raise typer.Exit(1)
        finally:
            pass

    console.print(tracker.render())
    console.print("\n[bold green]Project ready.[/bold green]")

    # Agent folder security notice (for primary agent)
    primary_ai = selected_ais[0]
    agent_config = AGENT_CONFIG.get(primary_ai)
    if agent_config:
        agent_folder = agent_config["folder"]
        if agent_folder:
            security_notice = Panel(
                f"Some agents may store credentials, auth tokens, or other identifying and private artifacts in the agent folder within your project.\n"
                f"Consider adding [cyan]{agent_folder}[/cyan] (or parts of it) to [cyan].gitignore[/cyan] to prevent accidental credential leakage.",
                title="[yellow]Agent Folder Security[/yellow]",
                border_style="yellow",
                padding=(1, 2)
            )
            console.print()
            console.print(security_notice)

    steps_lines = []
    if not here:
        steps_lines.append(f"1. Go to the project folder: [cyan]cd {project_name}[/cyan]")
        step_num = 2
    else:
        steps_lines.append("1. You're already in the project directory!")
        step_num = 2

    # Determine skill display mode for the next-steps panel (based on primary agent).
    # Skills integrations (codex, cursor-agent, etc.) should show skill invocation syntax.
    from ..integrations.base import SkillsIntegration as _SkillsInt
    primary_ai = selected_ais[0]
    primary_integration = resolved_integrations[primary_ai]
    _is_skills_integration = isinstance(primary_integration, _SkillsInt)

    codex_skill_mode = primary_ai == "codex" and _is_skills_integration
    claude_skill_mode = primary_ai == "claude" and _is_skills_integration
    cursor_agent_skill_mode = primary_ai == "cursor-agent" and _is_skills_integration
    native_skill_mode = codex_skill_mode or claude_skill_mode or cursor_agent_skill_mode

    if codex_skill_mode:
        steps_lines.append(f"{step_num}. Start Codex in this project directory; kiss skills were installed to [cyan].agents/skills[/cyan]")
        step_num += 1
    if claude_skill_mode:
        steps_lines.append(f"{step_num}. Start Claude in this project directory; kiss skills were installed to [cyan].claude/skills[/cyan]")
        step_num += 1
    if cursor_agent_skill_mode:
        steps_lines.append(f"{step_num}. Start Cursor Agent in this project directory; kiss skills were installed to [cyan].cursor/skills[/cyan]")
        step_num += 1
    usage_label = "skills" if native_skill_mode else "slash commands"

    def _display_cmd(name: str) -> str:
        if codex_skill_mode:
            return f"$kiss-{name}"
        if claude_skill_mode:
            return f"/kiss-{name}"
        if cursor_agent_skill_mode:
            return f"/kiss-{name}"
        return f"/kiss.{name}"

    steps_lines.append(f"{step_num}. Start using {usage_label} with your AI agent:")

    steps_lines.append(f"   {step_num}.1 [cyan]{_display_cmd('standardize')}[/] - Establish project principles")
    steps_lines.append(f"   {step_num}.2 [cyan]{_display_cmd('specify')}[/] - Create baseline specification")
    steps_lines.append(f"   {step_num}.3 [cyan]{_display_cmd('plan')}[/] - Create implementation plan")
    steps_lines.append(f"   {step_num}.4 [cyan]{_display_cmd('taskify')}[/] - Generate actionable tasks")
    steps_lines.append(f"   {step_num}.5 [cyan]{_display_cmd('implement')}[/] - Execute implementation")

    steps_panel = Panel("\n".join(steps_lines), title="Next Steps", border_style="cyan", padding=(1,2))
    console.print()
    console.print(steps_panel)

    enhancement_intro = (
        "Optional skills that you can use for your specs [bright_black](improve quality & confidence)[/bright_black]"
        if native_skill_mode
        else "Optional commands that you can use for your specs [bright_black](improve quality & confidence)[/bright_black]"
    )
    enhancement_lines = [
        enhancement_intro,
        "",
        f"○ [cyan]{_display_cmd('clarify-specs')}[/] [bright_black](optional)[/bright_black] - Ask structured questions to de-risk ambiguous areas before planning (run before [cyan]{_display_cmd('plan')}[/] if used)",
        f"○ [cyan]{_display_cmd('verify-tasks')}[/] [bright_black](optional)[/bright_black] - Cross-artifact consistency & alignment report (after [cyan]{_display_cmd('taskify')}[/], before [cyan]{_display_cmd('implement')}[/])",
        f"○ [cyan]{_display_cmd('checklist')}[/] [bright_black](optional)[/bright_black] - Generate quality checklists to validate requirements completeness, clarity, and consistency (after [cyan]{_display_cmd('plan')}[/])"
    ]
    enhancements_title = "Enhancement Skills" if native_skill_mode else "Enhancement Commands"
    enhancements_panel = Panel("\n".join(enhancement_lines), title=enhancements_title, border_style="cyan", padding=(1,2))
    console.print()
    console.print(enhancements_panel)
