"""Integration management commands (`kiss integration ...`)."""

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
    select_with_arrows,
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
    _add_integration_to_json,
    _remove_integration_from_json,
    _normalize_script_type,
    _resolve_script_type,
)
from kiss_cli.context import create_context_file, load_context_file, save_context_file
from kiss_cli.config import save_init_options, load_init_options
from kiss_cli.version import get_kiss_version

# Constants that commands use
from kiss_cli.installer import SCRIPT_TYPE_CHOICES, CLAUDE_LOCAL_PATH, CLAUDE_NPM_LOCAL_PATH

# The main Typer app created in kiss_cli.cli.__init__
from . import app

console = Console(highlight=False)

# Package-level symbols used by commands
from kiss_cli import (
    AGENT_CONFIG,
    _parse_integration_options,
    _update_init_options_for_integration,
)

integration_app = typer.Typer(
    name="integration",
    help="Manage AI agent integrations",
    add_completion=False,
)

app.add_typer(integration_app, name="integration")

@integration_app.command("list")
def integration_list(
    catalog: bool = typer.Option(False, "--catalog", help="Browse full catalog (built-in + community)"),
):
    """List available integrations and installed status."""
    from ..integrations import INTEGRATION_REGISTRY

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    current = _read_integration_json(project_root)
    installed_key = current.get("integration")

    if catalog:
        from ..integrations.catalog import IntegrationCatalog, IntegrationCatalogError

        ic = IntegrationCatalog(project_root)
        try:
            entries = ic.search()
        except IntegrationCatalogError as exc:
            console.print(f"[red]Error:[/red] {exc}")
            raise typer.Exit(1)

        if not entries:
            console.print("[yellow]No integrations found in catalog.[/yellow]")
            return

        table = Table(title="Integration Catalog")
        table.add_column("ID", style="cyan")
        table.add_column("Name")
        table.add_column("Version")
        table.add_column("Source")
        table.add_column("Status")

        for entry in sorted(entries, key=lambda e: e["id"]):
            eid = entry["id"]
            cat_name = entry.get("_catalog_name", "")
            install_allowed = entry.get("_install_allowed", True)
            if eid == installed_key:
                status = "[green]installed[/green]"
            elif eid in INTEGRATION_REGISTRY:
                status = "built-in"
            elif install_allowed is False:
                status = "discovery-only"
            else:
                status = ""
            table.add_row(
                eid,
                entry.get("name", eid),
                entry.get("version", ""),
                cat_name,
                status,
            )

        console.print(table)
        return

    table = Table(title="AI Agent Integrations")
    table.add_column("Key", style="cyan")
    table.add_column("Name")
    table.add_column("Status")
    table.add_column("CLI Required")

    for key in sorted(INTEGRATION_REGISTRY.keys()):
        integration = INTEGRATION_REGISTRY[key]
        cfg = integration.config or {}
        name = cfg.get("name", key)
        requires_cli = cfg.get("requires_cli", False)

        if key == installed_key:
            status = "[green]installed[/green]"
        else:
            status = ""

        cli_req = "yes" if requires_cli else "no (IDE)"
        table.add_row(key, name, status, cli_req)

    console.print(table)

    if installed_key:
        console.print(f"\n[dim]Current integration:[/dim] [cyan]{installed_key}[/cyan]")
    else:
        console.print("\n[yellow]No integration currently installed.[/yellow]")
        console.print("Install one with: [cyan]kiss integration install <key>[/cyan]")

@integration_app.command("install")
def integration_install(
    key: str = typer.Argument(help="Integration key to install (e.g. claude, copilot)"),
    script: str | None = typer.Option(None, "--script", help="Script type: sh or ps (default: from init-options.json or platform default)"),
    integration_options: str | None = typer.Option(None, "--integration-options", help='Options for the integration (e.g. --integration-options="--commands-dir .myagent/cmds")'),
):
    """Install an integration into an existing project."""
    from ..integrations import INTEGRATION_REGISTRY, get_integration
    from ..integrations.manifest import IntegrationManifest

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    integration = get_integration(key)
    if integration is None:
        console.print(f"[red]Error:[/red] Unknown integration '{key}'")
        available = ", ".join(sorted(INTEGRATION_REGISTRY.keys()))
        console.print(f"Available integrations: {available}")
        raise typer.Exit(1)

    current = _read_integration_json(project_root)
    installed_keys = current.get("integrations", [])

    if key in installed_keys:
        console.print(f"[yellow]Integration '{key}' is already installed.[/yellow]")
        raise typer.Exit(0)

    selected_script = _resolve_script_type(project_root, script)

    # Ensure shared infrastructure is present (safe to run unconditionally;
    # _install_shared_infra merges missing files without overwriting).
    _install_shared_infra(project_root)
    if os.name != "nt":
        ensure_executable_scripts(project_root)

    manifest = IntegrationManifest(
        integration.key, project_root, version=get_kiss_version()
    )

    # Build parsed options from --integration-options
    parsed_options: dict[str, Any] | None = None
    if integration_options:
        parsed_options = _parse_integration_options(integration, integration_options)

    try:
        integration.setup(
            project_root, manifest,
            parsed_options=parsed_options,
            script_type=selected_script,
            raw_options=integration_options,
        )
        manifest.save()
        _add_integration_to_json(project_root, integration.key)
        _update_init_options_for_integration(project_root, integration)

    except Exception as e:
        # Attempt rollback of any files written by setup
        try:
            integration.teardown(project_root, manifest, force=True)
        except Exception as rollback_err:
            # Suppress so the original setup error remains the primary failure
            console.print(f"[yellow]Warning:[/yellow] Failed to roll back integration changes: {rollback_err}")
        _remove_integration_json(project_root)
        console.print(f"[red]Error:[/red] Failed to install integration: {e}")
        raise typer.Exit(1)

    name = (integration.config or {}).get("name", key)
    console.print(f"\n[green]✓[/green] Integration '{name}' installed successfully")

@integration_app.command("uninstall")
def integration_uninstall(
    key: str = typer.Argument(None, help="Integration key to uninstall (default: current integration)"),
    force: bool = typer.Option(False, "--force", help="Remove files even if modified"),
    all_integrations: bool = typer.Option(False, "--all", help="Uninstall all installed integrations"),
):
    """Uninstall an integration, safely preserving modified files."""
    from ..integrations import get_integration
    from ..integrations.manifest import IntegrationManifest

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    current = _read_integration_json(project_root)
    installed_keys = current.get("integrations", [])
    # Compat: fall back to singular field for pre-migration files.
    if not installed_keys and current.get("integration"):
        installed_keys = [current["integration"]]

    # --all: uninstall every installed integration in sequence
    if all_integrations:
        if not installed_keys:
            console.print("[yellow]No integrations are currently installed.[/yellow]")
            raise typer.Exit(0)
        for k in list(installed_keys):
            console.print(f"\n[bold]Uninstalling {k}…[/bold]")
            integration_uninstall(key=k, force=force, all_integrations=False)
        return

    if key is None:
        if not installed_keys:
            console.print("[yellow]No integration is currently installed.[/yellow]")
            raise typer.Exit(0)
        if len(installed_keys) == 1:
            key = installed_keys[0]
        else:
            console.print("[red]Error:[/red] Multiple integrations installed. Specify which one to uninstall:")
            for k in installed_keys:
                console.print(f"  - {k}")
            console.print("Or use [cyan]kiss integration uninstall --all[/cyan]")
            raise typer.Exit(1)

    if key not in installed_keys:
        console.print(f"[red]Error:[/red] Integration '{key}' is not installed.")
        if installed_keys:
            console.print(f"Installed integrations: {', '.join(installed_keys)}")
        raise typer.Exit(1)

    integration = get_integration(key)

    manifest_path = project_root / ".kiss" / "integrations" / f"{key}.manifest.json"
    if not manifest_path.exists():
        console.print(f"[yellow]No manifest found for integration '{key}'. Nothing to uninstall.[/yellow]")
        _remove_integration_json(project_root)
        # Clear integration-related keys from init-options.json
        opts = load_init_options(project_root)
        if opts.get("integration") == key:
            opts.pop("integration", None)
            opts.pop("ai_skills", None)
            opts.pop("context_file", None)
            save_init_options(project_root, opts)
        raise typer.Exit(0)

    try:
        manifest = IntegrationManifest.load(key, project_root)
    except (ValueError, FileNotFoundError) as exc:
        console.print(f"[red]Error:[/red] Integration manifest for '{key}' is unreadable.")
        console.print(f"Manifest: {manifest_path}")
        console.print(
            f"To recover, delete the unreadable manifest, run "
            f"[cyan]kiss integration uninstall {key}[/cyan] to clear stale metadata, "
            f"then run [cyan]kiss integration install {key}[/cyan] to regenerate."
        )
        console.print(f"[dim]Details:[/dim] {exc}")
        raise typer.Exit(1)

    removed, skipped = manifest.uninstall(project_root, force=force)

    # Remove managed context section from the agent context file
    if integration:
        integration.remove_context_section(project_root)

    _remove_integration_from_json(project_root, key)

    # Update init-options.json to remove the integration
    opts = load_init_options(project_root)
    integrations_list = opts.get("integrations", [])
    if key in integrations_list:
        integrations_list.remove(key)
        opts["integrations"] = integrations_list
    # Compat: clear old singular field
    if opts.get("integration") == key:
        opts.pop("integration", None)
    opts.pop("ai_skills", None)
    opts.pop("context_file", None)
    save_init_options(project_root, opts)

    name = (integration.config or {}).get("name", key) if integration else key
    console.print(f"\n[green]✓[/green] Integration '{name}' uninstalled")
    if removed:
        console.print(f"  Removed {len(removed)} file(s)")
    if skipped:
        console.print(f"\n[yellow]⚠[/yellow]  {len(skipped)} modified file(s) were preserved:")
        for path in skipped:
            rel = path.relative_to(project_root) if path.is_absolute() else path
            console.print(f"    {rel}")

@integration_app.command("switch")
def integration_switch(
    target: str = typer.Argument(help="Integration key to switch to (or <from> <to> when multiple installed)"),
    source: str | None = typer.Argument(None, help="Integration key to replace (required when multiple installed)"),
    script: str | None = typer.Option(None, "--script", help="Script type: sh or ps (default: from init-options.json or platform default)"),
    force: bool = typer.Option(False, "--force", help="Force removal of modified files during uninstall"),
    integration_options: str | None = typer.Option(None, "--integration-options", help='Options for the target integration'),
):
    """Switch from one integration to another.

    With one integration installed: ``kiss integration switch <to>``
    With multiple installed: ``kiss integration switch <from> <to>``
    """
    from ..integrations import INTEGRATION_REGISTRY, get_integration
    from ..integrations.manifest import IntegrationManifest

    # When two positional args: first=source, second=target
    if source is not None:
        # Two args: switch <from> <to>
        actual_source = target
        actual_target = source
        target = actual_target
        source = actual_source

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    target_integration = get_integration(target)
    if target_integration is None:
        console.print(f"[red]Error:[/red] Unknown integration '{target}'")
        available = ", ".join(sorted(INTEGRATION_REGISTRY.keys()))
        console.print(f"Available integrations: {available}")
        raise typer.Exit(1)

    current = _read_integration_json(project_root)
    installed_keys = current.get("integrations", [])
    if not installed_keys and current.get("integration"):
        installed_keys = [current["integration"]]

    if target in installed_keys:
        console.print(f"[yellow]Integration '{target}' is already installed. Nothing to switch.[/yellow]")
        raise typer.Exit(0)

    # Determine which integration to replace
    installed_key = source
    if installed_key is None:
        if len(installed_keys) == 1:
            installed_key = installed_keys[0]
        elif len(installed_keys) > 1:
            console.print("[red]Error:[/red] Multiple integrations installed. Specify which to replace:")
            console.print(f"  kiss integration switch <from> {target}")
            for k in installed_keys:
                console.print(f"  - {k}")
            raise typer.Exit(1)

    if installed_key and installed_key not in installed_keys:
        console.print(f"[red]Error:[/red] Integration '{installed_key}' is not installed.")
        raise typer.Exit(1)

    selected_script = _resolve_script_type(project_root, script)

    # Phase 1: Uninstall current integration (if any)
    if installed_key:
        current_integration = get_integration(installed_key)
        manifest_path = project_root / ".kiss" / "integrations" / f"{installed_key}.manifest.json"

        if current_integration and manifest_path.exists():
            console.print(f"Uninstalling current integration: [cyan]{installed_key}[/cyan]")
            try:
                old_manifest = IntegrationManifest.load(installed_key, project_root)
            except (ValueError, FileNotFoundError) as exc:
                console.print(f"[red]Error:[/red] Could not read integration manifest for '{installed_key}': {manifest_path}")
                console.print(f"[dim]{exc}[/dim]")
                console.print(
                    f"To recover, delete the unreadable manifest at {manifest_path}, "
                    f"run [cyan]kiss integration uninstall {installed_key}[/cyan], then retry."
                )
                raise typer.Exit(1)
            removed, skipped = old_manifest.uninstall(project_root, force=force)
            current_integration.remove_context_section(project_root)
            if removed:
                console.print(f"  Removed {len(removed)} file(s)")
            if skipped:
                console.print(f"  [yellow]⚠[/yellow]  {len(skipped)} modified file(s) preserved")
        elif not current_integration and manifest_path.exists():
            # Integration removed from registry but manifest exists — use manifest-only uninstall
            console.print(f"Uninstalling unknown integration '{installed_key}' via manifest")
            try:
                old_manifest = IntegrationManifest.load(installed_key, project_root)
                removed, skipped = old_manifest.uninstall(project_root, force=force)
                if removed:
                    console.print(f"  Removed {len(removed)} file(s)")
                if skipped:
                    console.print(f"  [yellow]⚠[/yellow]  {len(skipped)} modified file(s) preserved")
            except (ValueError, FileNotFoundError) as exc:
                console.print(f"[yellow]Warning:[/yellow] Could not read manifest for '{installed_key}': {exc}")
        else:
            console.print(f"[red]Error:[/red] Integration '{installed_key}' is installed but has no manifest.")
            console.print(
                f"Run [cyan]kiss integration uninstall {installed_key}[/cyan] to clear metadata, "
                f"then retry [cyan]kiss integration switch {target}[/cyan]."
            )
            raise typer.Exit(1)

        # Clear the source integration from metadata
        _remove_integration_from_json(project_root, installed_key)
        opts = load_init_options(project_root)
        integrations_list = opts.get("integrations", [])
        if installed_key in integrations_list:
            integrations_list.remove(installed_key)
            opts["integrations"] = integrations_list
        opts.pop("integration", None)
        opts.pop("ai_skills", None)
        opts.pop("context_file", None)
        save_init_options(project_root, opts)

    # Ensure shared infrastructure is present (safe to run unconditionally;
    # _install_shared_infra merges missing files without overwriting).
    _install_shared_infra(project_root)
    if os.name != "nt":
        ensure_executable_scripts(project_root)

    # Phase 2: Install target integration
    console.print(f"Installing integration: [cyan]{target}[/cyan]")
    manifest = IntegrationManifest(
        target_integration.key, project_root, version=get_kiss_version()
    )

    parsed_options: dict[str, Any] | None = None
    if integration_options:
        parsed_options = _parse_integration_options(target_integration, integration_options)

    try:
        target_integration.setup(
            project_root, manifest,
            parsed_options=parsed_options,
            script_type=selected_script,
            raw_options=integration_options,
        )
        manifest.save()
        _add_integration_to_json(project_root, target_integration.key)
        _update_init_options_for_integration(project_root, target_integration)

    except Exception as e:
        # Attempt rollback of any files written by setup
        try:
            target_integration.teardown(project_root, manifest, force=True)
        except Exception as rollback_err:
            console.print(f"[yellow]Warning:[/yellow] Failed to roll back integration '{target}': {rollback_err}")
        _remove_integration_from_json(project_root, target_integration.key)
        console.print(f"[red]Error:[/red] Failed to install integration '{target}': {e}")
        raise typer.Exit(1)

    name = (target_integration.config or {}).get("name", target)
    console.print(f"\n[green]✓[/green] Switched to integration '{name}'")

@integration_app.command("upgrade")
def integration_upgrade(
    key: str | None = typer.Argument(None, help="Integration key to upgrade (default: current integration)"),
    force: bool = typer.Option(False, "--force", help="Force upgrade even if files are modified"),
    all_integrations: bool = typer.Option(False, "--all", help="Upgrade all installed integrations"),
    script: str | None = typer.Option(None, "--script", help="Script type: sh or ps (default: from init-options.json or platform default)"),
    integration_options: str | None = typer.Option(None, "--integration-options", help="Options for the integration"),
):
    """Upgrade an integration by reinstalling with diff-aware file handling.

    Compares manifest hashes to detect locally modified files and
    blocks the upgrade unless --force is used.
    """
    from ..integrations import get_integration
    from ..integrations.manifest import IntegrationManifest

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    current = _read_integration_json(project_root)
    installed_keys = current.get("integrations", [])
    if not installed_keys and current.get("integration"):
        installed_keys = [current["integration"]]

    # --all: upgrade every installed integration in sequence, stop at first failure
    if all_integrations:
        if not installed_keys:
            console.print("[yellow]No integrations are currently installed.[/yellow]")
            raise typer.Exit(0)
        for k in list(installed_keys):
            console.print(f"\n[bold]Upgrading {k}…[/bold]")
            integration_upgrade(
                key=k, force=force, all_integrations=False,
                script=script, integration_options=integration_options,
            )
        return

    if key is None:
        if not installed_keys:
            console.print("[yellow]No integration is currently installed.[/yellow]")
            raise typer.Exit(0)
        if len(installed_keys) == 1:
            key = installed_keys[0]
        else:
            console.print("[red]Error:[/red] Multiple integrations installed. Specify which one to upgrade:")
            for k in installed_keys:
                console.print(f"  - {k}")
            console.print("Or use [cyan]kiss integration upgrade --all[/cyan]")
            raise typer.Exit(1)

    if key not in installed_keys:
        console.print(f"[red]Error:[/red] Integration '{key}' is not installed.")
        console.print(f"Use [cyan]kiss integration install {key}[/cyan] to install it.")
        raise typer.Exit(1)

    integration = get_integration(key)
    if integration is None:
        console.print(f"[red]Error:[/red] Unknown integration '{key}'")
        raise typer.Exit(1)

    manifest_path = project_root / ".kiss" / "integrations" / f"{key}.manifest.json"
    if not manifest_path.exists():
        console.print(f"[yellow]No manifest found for integration '{key}'. Nothing to upgrade.[/yellow]")
        console.print(f"Run [cyan]kiss integration install {key}[/cyan] to perform a fresh install.")
        raise typer.Exit(0)

    try:
        old_manifest = IntegrationManifest.load(key, project_root)
    except (ValueError, FileNotFoundError) as exc:
        console.print(f"[red]Error:[/red] Integration manifest for '{key}' is unreadable: {exc}")
        raise typer.Exit(1)

    # Detect modified files via manifest hashes
    modified = old_manifest.check_modified()
    if modified and not force:
        console.print(f"[yellow]⚠[/yellow]  {len(modified)} file(s) have been modified since installation:")
        for rel in modified:
            console.print(f"    {rel}")
        console.print("\nUse [cyan]--force[/cyan] to overwrite modified files, or resolve manually.")
        raise typer.Exit(1)

    selected_script = _resolve_script_type(project_root, script)

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

    # Ensure shared infrastructure is up to date; --force overwrites existing files.
    _install_shared_infra(project_root, force=force)
    if os.name != "nt":
        ensure_executable_scripts(project_root)

    # Phase 1: Install new files (overwrites existing; old-only files remain)
    console.print(f"Upgrading integration: [cyan]{key}[/cyan]")
    new_manifest = IntegrationManifest(key, project_root, version=get_kiss_version())

    parsed_options: dict[str, Any] | None = None
    if integration_options:
        parsed_options = _parse_integration_options(integration, integration_options)

    try:
        integration.setup(
            project_root,
            new_manifest,
            parsed_options=parsed_options,
            script_type=selected_script,
            raw_options=integration_options,
        )
        new_manifest.save()
        _write_integration_json(project_root, key)
        _update_init_options_for_integration(project_root, integration)
    except Exception as exc:
        # Don't teardown — setup overwrites in-place, so teardown would
        # delete files that were working before the upgrade.  Just report.
        console.print(f"[red]Error:[/red] Failed to upgrade integration: {exc}")
        console.print("[yellow]The previous integration files may still be in place.[/yellow]")
        raise typer.Exit(1)

    # Phase 2: Remove stale files from old manifest that are not in the new one
    old_files = old_manifest.files
    new_files = new_manifest.files
    stale_keys = set(old_files) - set(new_files)
    if stale_keys:
        stale_manifest = IntegrationManifest(key, project_root, version="stale-cleanup")
        stale_manifest._files = {k: old_files[k] for k in stale_keys}
        stale_removed, _ = stale_manifest.uninstall(project_root, force=True)
        if stale_removed:
            console.print(f"  Removed {len(stale_removed)} stale file(s) from previous install")

    name = (integration.config or {}).get("name", key)
    console.print(f"\n[green]✓[/green] Integration '{name}' upgraded successfully")
