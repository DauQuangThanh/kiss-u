"""Preset management commands (`kiss preset ...`, `kiss preset-catalog ...`)."""

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
from kiss_cli import AGENT_CONFIG

preset_app = typer.Typer(
    name="preset",
    help="Manage kiss presets",
    add_completion=False,
)

app.add_typer(preset_app, name="preset")

preset_catalog_app = typer.Typer(
    name="catalog",
    help="Manage preset catalogs",
    add_completion=False,
)

preset_app.add_typer(preset_catalog_app, name="catalog")

@preset_app.command("list")
def preset_list():
    """List installed presets."""
    from kiss_cli.presets import PresetManager

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = PresetManager(project_root)
    installed = manager.list_installed()

    if not installed:
        console.print("[yellow]No presets installed.[/yellow]")
        console.print("\nInstall a preset with:")
        console.print("  [cyan]kiss preset add <pack-name>[/cyan]")
        return

    console.print("\n[bold cyan]Installed Presets:[/bold cyan]\n")
    for pack in installed:
        status = "[green]enabled[/green]" if pack.get("enabled", True) else "[red]disabled[/red]"
        pri = pack.get('priority', 10)
        console.print(f"  [bold]{pack['name']}[/bold] ({pack['id']}) v{pack['version']} — {status} — priority {pri}")
        console.print(f"    {pack['description']}")
        if pack.get("tags"):
            tags_str = ", ".join(pack["tags"])
            console.print(f"    [dim]Tags: {tags_str}[/dim]")
        console.print(f"    [dim]Templates: {pack['template_count']}[/dim]")
        console.print()

@preset_app.command("add")
def preset_add(
    preset_id: str = typer.Argument(None, help="Preset ID to install from catalog"),
    dev: str = typer.Option(None, "--dev", help="Install from local directory (development mode)"),
    priority: int = typer.Option(10, "--priority", help="Resolution priority (lower = higher precedence, default 10)"),
):
    """Install a preset."""
    from kiss_cli.presets import (
        PresetManager,
        PresetCatalog,
        PresetError,
        PresetValidationError,
        PresetCompatibilityError,
    )

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    # Validate priority
    if priority < 1:
        console.print("[red]Error:[/red] Priority must be a positive integer (1 or higher)")
        raise typer.Exit(1)

    manager = PresetManager(project_root)
    kiss_version = get_kiss_version()

    try:
        if dev:
            dev_path = Path(dev).resolve()
            if not dev_path.exists():
                console.print(f"[red]Error:[/red] Directory not found: {dev}")
                raise typer.Exit(1)

            console.print(f"Installing preset from [cyan]{dev_path}[/cyan]...")
            manifest = manager.install_from_directory(dev_path, kiss_version, priority)
            console.print(f"[green]✓[/green] Preset '{manifest.name}' v{manifest.version} installed (priority {priority})")

        elif preset_id:
            # kiss is offline-only: only bundled presets are installable.
            bundled_path = _locate_bundled_preset(preset_id)
            if bundled_path is None:
                from kiss_cli.extensions import REINSTALL_COMMAND
                console.print(
                    f"[red]Error:[/red] Preset '{preset_id}' is not bundled with kiss."
                )
                console.print(
                    "kiss is offline-only; only bundled presets can be installed."
                )
                console.print(
                    "If this preset should be bundled, your installation may be corrupted. "
                    f"Try reinstalling kiss: [cyan]{REINSTALL_COMMAND}[/cyan]"
                )
                raise typer.Exit(1)
            console.print(f"Installing bundled preset [cyan]{preset_id}[/cyan]...")
            manifest = manager.install_from_directory(bundled_path, kiss_version, priority)
            console.print(f"[green]✓[/green] Preset '{manifest.name}' v{manifest.version} installed (priority {priority})")
        else:
            console.print("[red]Error:[/red] Specify a preset ID or --dev path")
            raise typer.Exit(1)

    except PresetCompatibilityError as e:
        console.print(f"[red]Compatibility Error:[/red] {e}")
        raise typer.Exit(1)
    except PresetValidationError as e:
        console.print(f"[red]Validation Error:[/red] {e}")
        raise typer.Exit(1)
    except PresetError as e:
        console.print(f"[red]Error:[/red] {e}")
        raise typer.Exit(1)

@preset_app.command("remove")
def preset_remove(
    preset_id: str = typer.Argument(..., help="Preset ID to remove"),
):
    """Remove an installed preset."""
    from kiss_cli.presets import PresetManager

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = PresetManager(project_root)

    if not manager.registry.is_installed(preset_id):
        console.print(f"[red]Error:[/red] Preset '{preset_id}' is not installed")
        raise typer.Exit(1)

    if manager.remove(preset_id):
        console.print(f"[green]✓[/green] Preset '{preset_id}' removed successfully")
    else:
        console.print(f"[red]Error:[/red] Failed to remove preset '{preset_id}'")
        raise typer.Exit(1)

@preset_app.command("search")
def preset_search(
    query: str = typer.Argument(None, help="Search query"),
    tag: str = typer.Option(None, "--tag", help="Filter by tag"),
    author: str = typer.Option(None, "--author", help="Filter by author"),
):
    """Search for presets in the catalog."""
    from kiss_cli.presets import PresetCatalog, PresetError

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    catalog = PresetCatalog(project_root)

    try:
        results = catalog.search(query=query, tag=tag, author=author)
    except PresetError as e:
        console.print(f"[red]Error:[/red] {e}")
        raise typer.Exit(1)

    if not results:
        console.print("[yellow]No presets found matching your criteria.[/yellow]")
        return

    console.print(f"\n[bold cyan]Presets ({len(results)} found):[/bold cyan]\n")
    for pack in results:
        console.print(f"  [bold]{pack.get('name', pack['id'])}[/bold] ({pack['id']}) v{pack.get('version', '?')}")
        console.print(f"    {pack.get('description', '')}")
        if pack.get("tags"):
            tags_str = ", ".join(pack["tags"])
            console.print(f"    [dim]Tags: {tags_str}[/dim]")
        console.print()

@preset_app.command("resolve")
def preset_resolve(
    template_name: str = typer.Argument(..., help="Template name to resolve (e.g., spec-template)"),
):
    """Show which template will be resolved for a given name."""
    from kiss_cli.presets import PresetResolver

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    resolver = PresetResolver(project_root)
    result = resolver.resolve_with_source(template_name)

    if result:
        console.print(f"  [bold]{template_name}[/bold]: {result['path']}")
        console.print(f"    [dim](from: {result['source']})[/dim]")
    else:
        console.print(f"  [yellow]{template_name}[/yellow]: not found")
        console.print("    [dim]No template with this name exists in the resolution stack[/dim]")

@preset_app.command("info")
def preset_info(
    preset_id: str = typer.Argument(..., help="Preset ID to get info about"),
):
    """Show detailed information about a preset."""
    from kiss_cli.extensions import normalize_priority
    from kiss_cli.presets import PresetCatalog, PresetManager, PresetError

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    # Check if installed locally first
    manager = PresetManager(project_root)
    local_pack = manager.get_pack(preset_id)

    if local_pack:
        console.print(f"\n[bold cyan]Preset: {local_pack.name}[/bold cyan]\n")
        console.print(f"  ID:          {local_pack.id}")
        console.print(f"  Version:     {local_pack.version}")
        console.print(f"  Description: {local_pack.description}")
        if local_pack.author:
            console.print(f"  Author:      {local_pack.author}")
        if local_pack.tags:
            console.print(f"  Tags:        {', '.join(local_pack.tags)}")
        console.print(f"  Templates:   {len(local_pack.templates)}")
        for tmpl in local_pack.templates:
            console.print(f"    - {tmpl['name']} ({tmpl['type']}): {tmpl.get('description', '')}")
        repo = local_pack.data.get("preset", {}).get("repository")
        if repo:
            console.print(f"  Repository:  {repo}")
        license_val = local_pack.data.get("preset", {}).get("license")
        if license_val:
            console.print(f"  License:     {license_val}")
        console.print("\n  [green]Status: installed[/green]")
        # Get priority from registry
        pack_metadata = manager.registry.get(preset_id)
        priority = normalize_priority(pack_metadata.get("priority") if isinstance(pack_metadata, dict) else None)
        console.print(f"  [dim]Priority:[/dim] {priority}")
        console.print()
        return

    # Fall back to catalog
    catalog = PresetCatalog(project_root)
    try:
        pack_info = catalog.get_pack_info(preset_id)
    except PresetError:
        pack_info = None

    if not pack_info:
        console.print(f"[red]Error:[/red] Preset '{preset_id}' not found (not installed and not in catalog)")
        raise typer.Exit(1)

    console.print(f"\n[bold cyan]Preset: {pack_info.get('name', preset_id)}[/bold cyan]\n")
    console.print(f"  ID:          {pack_info['id']}")
    console.print(f"  Version:     {pack_info.get('version', '?')}")
    console.print(f"  Description: {pack_info.get('description', '')}")
    if pack_info.get("author"):
        console.print(f"  Author:      {pack_info['author']}")
    if pack_info.get("tags"):
        console.print(f"  Tags:        {', '.join(pack_info['tags'])}")
    if pack_info.get("repository"):
        console.print(f"  Repository:  {pack_info['repository']}")
    if pack_info.get("license"):
        console.print(f"  License:     {pack_info['license']}")
    console.print("\n  [yellow]Status: not installed[/yellow]")
    console.print(f"  Install with: [cyan]kiss preset add {preset_id}[/cyan]")
    console.print()

@preset_app.command("set-priority")
def preset_set_priority(
    preset_id: str = typer.Argument(help="Preset ID"),
    priority: int = typer.Argument(help="New priority (lower = higher precedence)"),
):
    """Set the resolution priority of an installed preset."""
    from kiss_cli.presets import PresetManager

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    # Validate priority
    if priority < 1:
        console.print("[red]Error:[/red] Priority must be a positive integer (1 or higher)")
        raise typer.Exit(1)

    manager = PresetManager(project_root)

    # Check if preset is installed
    if not manager.registry.is_installed(preset_id):
        console.print(f"[red]Error:[/red] Preset '{preset_id}' is not installed")
        raise typer.Exit(1)

    # Get current metadata
    metadata = manager.registry.get(preset_id)
    if metadata is None or not isinstance(metadata, dict):
        console.print(f"[red]Error:[/red] Preset '{preset_id}' not found in registry (corrupted state)")
        raise typer.Exit(1)

    from kiss_cli.extensions import normalize_priority
    raw_priority = metadata.get("priority")
    # Only skip if the stored value is already a valid int equal to requested priority
    # This ensures corrupted values (e.g., "high") get repaired even when setting to default (10)
    if isinstance(raw_priority, int) and raw_priority == priority:
        console.print(f"[yellow]Preset '{preset_id}' already has priority {priority}[/yellow]")
        raise typer.Exit(0)

    old_priority = normalize_priority(raw_priority)

    # Update priority
    manager.registry.update(preset_id, {"priority": priority})

    console.print(f"[green]✓[/green] Preset '{preset_id}' priority changed: {old_priority} → {priority}")
    console.print("\n[dim]Lower priority = higher precedence in template resolution[/dim]")

@preset_app.command("enable")
def preset_enable(
    preset_id: str = typer.Argument(help="Preset ID to enable"),
):
    """Enable a disabled preset."""
    from kiss_cli.presets import PresetManager

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = PresetManager(project_root)

    # Check if preset is installed
    if not manager.registry.is_installed(preset_id):
        console.print(f"[red]Error:[/red] Preset '{preset_id}' is not installed")
        raise typer.Exit(1)

    # Get current metadata
    metadata = manager.registry.get(preset_id)
    if metadata is None or not isinstance(metadata, dict):
        console.print(f"[red]Error:[/red] Preset '{preset_id}' not found in registry (corrupted state)")
        raise typer.Exit(1)

    if metadata.get("enabled", True):
        console.print(f"[yellow]Preset '{preset_id}' is already enabled[/yellow]")
        raise typer.Exit(0)

    # Enable the preset
    manager.registry.update(preset_id, {"enabled": True})

    console.print(f"[green]✓[/green] Preset '{preset_id}' enabled")
    console.print("\nTemplates from this preset will now be included in resolution.")
    console.print("[dim]Note: Previously registered commands/skills remain active.[/dim]")

@preset_app.command("disable")
def preset_disable(
    preset_id: str = typer.Argument(help="Preset ID to disable"),
):
    """Disable a preset without removing it."""
    from kiss_cli.presets import PresetManager

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = PresetManager(project_root)

    # Check if preset is installed
    if not manager.registry.is_installed(preset_id):
        console.print(f"[red]Error:[/red] Preset '{preset_id}' is not installed")
        raise typer.Exit(1)

    # Get current metadata
    metadata = manager.registry.get(preset_id)
    if metadata is None or not isinstance(metadata, dict):
        console.print(f"[red]Error:[/red] Preset '{preset_id}' not found in registry (corrupted state)")
        raise typer.Exit(1)

    if not metadata.get("enabled", True):
        console.print(f"[yellow]Preset '{preset_id}' is already disabled[/yellow]")
        raise typer.Exit(0)

    # Disable the preset
    manager.registry.update(preset_id, {"enabled": False})

    console.print(f"[green]✓[/green] Preset '{preset_id}' disabled")
    console.print("\nTemplates from this preset will be skipped during resolution.")
    console.print("[dim]Note: Previously registered commands/skills remain active until preset removal.[/dim]")
    console.print(f"To re-enable: kiss preset enable {preset_id}")

@preset_catalog_app.command("list")
def preset_catalog_list():
    """List all active preset catalogs."""
    from kiss_cli.presets import PresetCatalog, PresetValidationError

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    catalog = PresetCatalog(project_root)

    try:
        active_catalogs = catalog.get_active_catalogs()
    except PresetValidationError as e:
        console.print(f"[red]Error:[/red] {e}")
        raise typer.Exit(1)

    console.print("\n[bold cyan]Active Preset Catalogs:[/bold cyan]\n")
    for entry in active_catalogs:
        install_str = (
            "[green]install allowed[/green]"
            if entry.install_allowed
            else "[yellow]discovery only[/yellow]"
        )
        console.print(f"  [bold]{entry.name}[/bold] (priority {entry.priority})")
        if entry.description:
            console.print(f"     {entry.description}")
        console.print(f"     URL: {entry.url}")
        console.print(f"     Install: {install_str}")
        console.print()

    config_path = project_root / ".kiss" / "preset-catalogs.yml"
    user_config_path = Path.home() / ".kiss" / "preset-catalogs.yml"
    if os.environ.get("KISS_PRESET_CATALOG_URL"):
        console.print("[dim]Catalog configured via KISS_PRESET_CATALOG_URL environment variable.[/dim]")
    else:
        try:
            proj_loaded = config_path.exists() and catalog._load_catalog_config(config_path) is not None
        except PresetValidationError:
            proj_loaded = False
        if proj_loaded:
            console.print(f"[dim]Config: {config_path.relative_to(project_root)}[/dim]")
        else:
            try:
                user_loaded = user_config_path.exists() and catalog._load_catalog_config(user_config_path) is not None
            except PresetValidationError:
                user_loaded = False
            if user_loaded:
                console.print("[dim]Config: ~/.kiss/preset-catalogs.yml[/dim]")
            else:
                console.print("[dim]Using built-in default catalog stack.[/dim]")
                console.print(
                    "[dim]Add .kiss/preset-catalogs.yml to customize.[/dim]"
                )

@preset_catalog_app.command("add")
def preset_catalog_add(
    url: str = typer.Argument(help="Catalog URL (must use HTTPS)"),
    name: str = typer.Option(..., "--name", help="Catalog name"),
    priority: int = typer.Option(10, "--priority", help="Priority (lower = higher priority)"),
    install_allowed: bool = typer.Option(
        False, "--install-allowed/--no-install-allowed",
        help="Allow presets from this catalog to be installed",
    ),
    description: str = typer.Option("", "--description", help="Description of the catalog"),
):
    """Add a catalog to .kiss/preset-catalogs.yml."""
    from kiss_cli.presets import PresetCatalog, PresetValidationError

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    # Validate URL
    tmp_catalog = PresetCatalog(project_root)
    try:
        tmp_catalog._validate_catalog_url(url)
    except PresetValidationError as e:
        console.print(f"[red]Error:[/red] {e}")
        raise typer.Exit(1)

    config_path = kiss_dir / "preset-catalogs.yml"

    # Load existing config
    if config_path.exists():
        try:
            config = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
        except Exception as e:
            console.print(f"[red]Error:[/red] Failed to read {config_path}: {e}")
            raise typer.Exit(1)
    else:
        config = {}

    catalogs = config.get("catalogs", [])
    if not isinstance(catalogs, list):
        console.print("[red]Error:[/red] Invalid catalog config: 'catalogs' must be a list.")
        raise typer.Exit(1)

    # Check for duplicate name
    for existing in catalogs:
        if isinstance(existing, dict) and existing.get("name") == name:
            console.print(f"[yellow]Warning:[/yellow] A catalog named '{name}' already exists.")
            console.print("Use 'kiss preset catalog remove' first, or choose a different name.")
            raise typer.Exit(1)

    catalogs.append({
        "name": name,
        "url": url,
        "priority": priority,
        "install_allowed": install_allowed,
        "description": description,
    })

    config["catalogs"] = catalogs
    config_path.write_text(yaml.dump(config, default_flow_style=False, sort_keys=False, allow_unicode=True), encoding="utf-8")

    install_label = "install allowed" if install_allowed else "discovery only"
    console.print(f"\n[green]✓[/green] Added catalog '[bold]{name}[/bold]' ({install_label})")
    console.print(f"  URL: {url}")
    console.print(f"  Priority: {priority}")
    console.print(f"\nConfig saved to {config_path.relative_to(project_root)}")

@preset_catalog_app.command("remove")
def preset_catalog_remove(
    name: str = typer.Argument(help="Catalog name to remove"),
):
    """Remove a catalog from .kiss/preset-catalogs.yml."""
    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    config_path = kiss_dir / "preset-catalogs.yml"
    if not config_path.exists():
        console.print("[red]Error:[/red] No preset catalog config found. Nothing to remove.")
        raise typer.Exit(1)

    try:
        config = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    except Exception:
        console.print("[red]Error:[/red] Failed to read preset catalog config.")
        raise typer.Exit(1)

    catalogs = config.get("catalogs", [])
    if not isinstance(catalogs, list):
        console.print("[red]Error:[/red] Invalid catalog config: 'catalogs' must be a list.")
        raise typer.Exit(1)
    original_count = len(catalogs)
    catalogs = [c for c in catalogs if isinstance(c, dict) and c.get("name") != name]

    if len(catalogs) == original_count:
        console.print(f"[red]Error:[/red] Catalog '{name}' not found.")
        raise typer.Exit(1)

    config["catalogs"] = catalogs
    config_path.write_text(yaml.dump(config, default_flow_style=False, sort_keys=False, allow_unicode=True), encoding="utf-8")

    console.print(f"[green]✓[/green] Removed catalog '{name}'")
    if not catalogs:
        console.print("\n[dim]No catalogs remain in config. Built-in defaults will be used.[/dim]")
