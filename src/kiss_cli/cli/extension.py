"""Extension management commands (`kiss extension ...`, `kiss catalog ...`)."""

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
from kiss_cli import (
    AGENT_CONFIG,
    _resolve_installed_extension,
    _resolve_catalog_extension,
    _print_extension_info,
)

extension_app = typer.Typer(
    name="extension",
    help="Manage kiss extensions",
    add_completion=False,
)

app.add_typer(extension_app, name="extension")

catalog_app = typer.Typer(
    name="catalog",
    help="Manage extension catalogs",
    add_completion=False,
)

extension_app.add_typer(catalog_app, name="catalog")

@extension_app.command("list")
def extension_list(
    available: bool = typer.Option(False, "--available", help="Show available extensions from catalog"),
    all_extensions: bool = typer.Option(False, "--all", help="Show both installed and available"),
):
    """List installed extensions."""
    from kiss_cli.extensions import ExtensionManager

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    installed = manager.list_installed()

    if not installed and not (available or all_extensions):
        console.print("[yellow]No extensions installed.[/yellow]")
        console.print("\nInstall an extension with:")
        console.print("  kiss extension add <extension-name>")
        return

    if installed:
        console.print("\n[bold cyan]Installed Extensions:[/bold cyan]\n")

        for ext in installed:
            status_icon = "✓" if ext["enabled"] else "✗"
            status_color = "green" if ext["enabled"] else "red"

            console.print(f"  [{status_color}]{status_icon}[/{status_color}] [bold]{ext['name']}[/bold] (v{ext['version']})")
            console.print(f"     [dim]{ext['id']}[/dim]")
            console.print(f"     {ext['description']}")
            console.print(f"     Commands: {ext['command_count']} | Hooks: {ext['hook_count']} | Priority: {ext['priority']} | Status: {'Enabled' if ext['enabled'] else 'Disabled'}")
            console.print()

    if available or all_extensions:
        console.print("\nInstall an extension:")
        console.print("  [cyan]kiss extension add <name>[/cyan]")

@catalog_app.command("list")
def catalog_list():
    """List all active extension catalogs."""
    from kiss_cli.extensions import ExtensionCatalog, ValidationError

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    catalog = ExtensionCatalog(project_root)

    try:
        active_catalogs = catalog.get_active_catalogs()
    except ValidationError as e:
        console.print(f"[red]Error:[/red] {e}")
        raise typer.Exit(1)

    console.print("\n[bold cyan]Active Extension Catalogs:[/bold cyan]\n")
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

    config_path = project_root / ".kiss" / "extension-catalogs.yml"
    user_config_path = Path.home() / ".kiss" / "extension-catalogs.yml"
    if os.environ.get("KISS_CATALOG_URL"):
        console.print("[dim]Catalog configured via KISS_CATALOG_URL environment variable.[/dim]")
    else:
        try:
            proj_loaded = config_path.exists() and catalog._load_catalog_config(config_path) is not None
        except ValidationError:
            proj_loaded = False
        if proj_loaded:
            console.print(f"[dim]Config: {config_path.relative_to(project_root)}[/dim]")
        else:
            try:
                user_loaded = user_config_path.exists() and catalog._load_catalog_config(user_config_path) is not None
            except ValidationError:
                user_loaded = False
            if user_loaded:
                console.print("[dim]Config: ~/.kiss/extension-catalogs.yml[/dim]")
            else:
                console.print("[dim]Using built-in default catalog stack.[/dim]")
                console.print(
                    "[dim]Add .kiss/extension-catalogs.yml to customize.[/dim]"
                )

@catalog_app.command("add")
def catalog_add(
    url: str = typer.Argument(help="Catalog URL (must use HTTPS)"),
    name: str = typer.Option(..., "--name", help="Catalog name"),
    priority: int = typer.Option(10, "--priority", help="Priority (lower = higher priority)"),
    install_allowed: bool = typer.Option(
        False, "--install-allowed/--no-install-allowed",
        help="Allow extensions from this catalog to be installed",
    ),
    description: str = typer.Option("", "--description", help="Description of the catalog"),
):
    """Add a catalog to .kiss/extension-catalogs.yml."""
    from kiss_cli.extensions import ExtensionCatalog, ValidationError

    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    # Validate URL
    tmp_catalog = ExtensionCatalog(project_root)
    try:
        tmp_catalog._validate_catalog_url(url)
    except ValidationError as e:
        console.print(f"[red]Error:[/red] {e}")
        raise typer.Exit(1)

    config_path = kiss_dir / "extension-catalogs.yml"

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
            console.print("Use 'kiss extension catalog remove' first, or choose a different name.")
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

@catalog_app.command("remove")
def catalog_remove(
    name: str = typer.Argument(help="Catalog name to remove"),
):
    """Remove a catalog from .kiss/extension-catalogs.yml."""
    project_root = Path.cwd()

    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    config_path = kiss_dir / "extension-catalogs.yml"
    if not config_path.exists():
        console.print("[red]Error:[/red] No catalog config found. Nothing to remove.")
        raise typer.Exit(1)

    try:
        config = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    except Exception:
        console.print("[red]Error:[/red] Failed to read catalog config.")
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

@extension_app.command("add")
def extension_add(
    extension: str = typer.Argument(help="Extension name or path"),
    dev: bool = typer.Option(False, "--dev", help="Install from local directory"),
    priority: int = typer.Option(10, "--priority", help="Resolution priority (lower = higher precedence, default 10)"),
):
    """Install an extension."""
    from kiss_cli.extensions import ExtensionManager, ExtensionCatalog, ExtensionError, ValidationError, CompatibilityError, REINSTALL_COMMAND

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

    manager = ExtensionManager(project_root)
    kiss_version = get_kiss_version()

    try:
        with console.status(f"[cyan]Installing extension: {extension}[/cyan]"):
            if dev:
                # Install from local directory
                source_path = Path(extension).expanduser().resolve()
                if not source_path.exists():
                    console.print(f"[red]Error:[/red] Directory not found: {source_path}")
                    raise typer.Exit(1)

                if not (source_path / "extension.yml").exists():
                    console.print(f"[red]Error:[/red] No extension.yml found in {source_path}")
                    raise typer.Exit(1)

                manifest = manager.install_from_directory(source_path, kiss_version, priority=priority)

            else:
                # kiss is offline-only: only bundled extensions are installable.
                bundled_path = _locate_bundled_extension(extension)
                resolved_info = None
                if bundled_path is None:
                    # Try resolving display name → ID via the bundled catalog.
                    catalog = ExtensionCatalog(project_root)
                    resolved_info, _ = _resolve_catalog_extension(extension, catalog, "add")
                    if resolved_info is not None:
                        bundled_path = _locate_bundled_extension(resolved_info["id"])
                if bundled_path is None:
                    if resolved_info is not None and resolved_info.get("bundled"):
                        console.print(
                            f"[red]Error:[/red] Extension '{resolved_info['id']}' is bundled with kiss "
                            f"but could not be found in the installed package."
                        )
                        console.print(
                            "This usually means the kiss installation is incomplete or corrupted."
                        )
                        console.print("Try reinstalling kiss:")
                        console.print(f"  [cyan]{REINSTALL_COMMAND}[/cyan]")
                    else:
                        console.print(
                            f"[red]Error:[/red] Extension '{extension}' is not bundled with kiss."
                        )
                        console.print(
                            "kiss is offline-only; only bundled extensions can be installed. "
                            "If this extension should be bundled, try reinstalling kiss:"
                        )
                        console.print(f"  [cyan]{REINSTALL_COMMAND}[/cyan]")
                    raise typer.Exit(1)
                manifest = manager.install_from_directory(bundled_path, kiss_version, priority=priority)

        console.print("\n[green]✓[/green] Extension installed successfully!")
        console.print(f"\n[bold]{manifest.name}[/bold] (v{manifest.version})")
        console.print(f"  {manifest.description}")

        for warning in manifest.warnings:
            console.print(f"\n[yellow]⚠  Compatibility warning:[/yellow] {warning}")

        console.print("\n[bold cyan]Provided commands:[/bold cyan]")
        for cmd in manifest.commands:
            console.print(f"  • {cmd['name']} - {cmd.get('description', '')}")

        # Report agent skills registration
        reg_meta = manager.registry.get(manifest.id)
        reg_skills = reg_meta.get("registered_skills", []) if reg_meta else []
        # Normalize to guard against corrupted registry entries
        if not isinstance(reg_skills, list):
            reg_skills = []
        if reg_skills:
            console.print(f"\n[green]✓[/green] {len(reg_skills)} agent skill(s) auto-registered")

        console.print("\n[yellow]⚠[/yellow]  Configuration may be required")
        console.print(f"   Check: .kiss/extensions/{manifest.id}/")

    except ValidationError as e:
        console.print(f"\n[red]Validation Error:[/red] {e}")
        raise typer.Exit(1)
    except CompatibilityError as e:
        console.print(f"\n[red]Compatibility Error:[/red] {e}")
        raise typer.Exit(1)
    except ExtensionError as e:
        console.print(f"\n[red]Error:[/red] {e}")
        raise typer.Exit(1)

@extension_app.command("remove")
def extension_remove(
    extension: str = typer.Argument(help="Extension ID or name to remove"),
    keep_config: bool = typer.Option(False, "--keep-config", help="Don't remove config files"),
    force: bool = typer.Option(False, "--force", help="Skip confirmation"),
):
    """Uninstall an extension."""
    from kiss_cli.extensions import ExtensionManager

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)

    # Resolve extension ID from argument (handles ambiguous names)
    installed = manager.list_installed()
    extension_id, display_name = _resolve_installed_extension(extension, installed, "remove")

    # Get extension info for command and skill counts
    ext_manifest = manager.get_extension(extension_id)
    reg_meta = manager.registry.get(extension_id)
    # Derive cmd_count from the registry's registered_commands (includes aliases)
    # rather than from the manifest (primary commands only). Use max() across
    # agents to get the per-agent count; sum() would double-count since users
    # think in logical commands, not per-agent file counts.
    # Use get() without a default so we can distinguish "key missing" (fall back
    # to manifest) from "key present but empty dict" (zero commands registered).
    registered_commands = reg_meta.get("registered_commands") if isinstance(reg_meta, dict) else None
    if isinstance(registered_commands, dict):
        cmd_count = max(
            (len(v) for v in registered_commands.values() if isinstance(v, list)),
            default=0,
        )
    else:
        cmd_count = len(ext_manifest.commands) if ext_manifest else 0
    raw_skills = reg_meta.get("registered_skills") if reg_meta else None
    skill_count = len(raw_skills) if isinstance(raw_skills, list) else 0

    # Confirm removal
    if not force:
        console.print("\n[yellow]⚠  This will remove:[/yellow]")
        console.print(f"   • {cmd_count} command{'s' if cmd_count != 1 else ''} per agent")
        if skill_count:
            console.print(f"   • {skill_count} agent skill(s)")
        console.print(f"   • Extension directory: .kiss/extensions/{extension_id}/")
        if not keep_config:
            console.print("   • Config files (will be backed up)")
        console.print()

        confirm = typer.confirm("Continue?")
        if not confirm:
            console.print("Cancelled")
            raise typer.Exit(0)

    # Remove extension
    success = manager.remove(extension_id, keep_config=keep_config)

    if success:
        console.print(f"\n[green]✓[/green] Extension '{display_name}' removed successfully")
        if keep_config:
            console.print(f"\nConfig files preserved in .kiss/extensions/{extension_id}/")
        else:
            console.print(f"\nConfig files backed up to .kiss/extensions/.backup/{extension_id}/")
        console.print(f"\nTo reinstall: kiss extension add {extension_id}")
    else:
        console.print("[red]Error:[/red] Failed to remove extension")
        raise typer.Exit(1)

@extension_app.command("search")
def extension_search(
    query: str = typer.Argument(None, help="Search query (optional)"),
    tag: Optional[str] = typer.Option(None, "--tag", help="Filter by tag"),
    author: Optional[str] = typer.Option(None, "--author", help="Filter by author"),
    verified: bool = typer.Option(False, "--verified", help="Show only verified extensions"),
):
    """Search for available extensions in catalog."""
    from kiss_cli.extensions import ExtensionCatalog, ExtensionError

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    catalog = ExtensionCatalog(project_root)

    try:
        console.print("🔍 Searching extension catalog...")
        results = catalog.search(query=query, tag=tag, author=author, verified_only=verified)

        if not results:
            console.print("\n[yellow]No extensions found matching criteria[/yellow]")
            if query or tag or author or verified:
                console.print("\nTry:")
                console.print("  • Broader search terms")
                console.print("  • Remove filters")
                console.print("  • kiss extension search (show all)")
            raise typer.Exit(0)

        console.print(f"\n[green]Found {len(results)} extension(s):[/green]\n")

        for ext in results:
            # Extension header
            verified_badge = " [green]✓ Verified[/green]" if ext.get("verified") else ""
            console.print(f"[bold]{ext['name']}[/bold] (v{ext['version']}){verified_badge}")
            console.print(f"  {ext['description']}")

            # Metadata
            console.print(f"\n  [dim]Author:[/dim] {ext.get('author', 'Unknown')}")
            if ext.get('tags'):
                tags_str = ", ".join(ext['tags'])
                console.print(f"  [dim]Tags:[/dim] {tags_str}")

            # Source catalog
            catalog_name = ext.get("_catalog_name", "")
            install_allowed = ext.get("_install_allowed", True)
            if catalog_name:
                if install_allowed:
                    console.print(f"  [dim]Catalog:[/dim] {catalog_name}")
                else:
                    console.print(f"  [dim]Catalog:[/dim] {catalog_name} [yellow](discovery only — not installable)[/yellow]")

            # Stats
            stats = []
            if ext.get('downloads') is not None:
                stats.append(f"Downloads: {ext['downloads']:,}")
            if ext.get('stars') is not None:
                stats.append(f"Stars: {ext['stars']}")
            if stats:
                console.print(f"  [dim]{' | '.join(stats)}[/dim]")

            # Links
            if ext.get('repository'):
                console.print(f"  [dim]Repository:[/dim] {ext['repository']}")

            # Install command (show warning if not installable)
            if install_allowed:
                console.print(f"\n  [cyan]Install:[/cyan] kiss extension add {ext['id']}")
            else:
                console.print(f"\n  [yellow]⚠[/yellow]  Not directly installable from '{catalog_name}'.")
                console.print(
                    f"  Add to an approved catalog with install_allowed: true, "
                    f"or install from a ZIP URL: kiss extension add {ext['id']} --from <zip-url>"
                )
            console.print()

    except ExtensionError as e:
        console.print(f"\n[red]Error:[/red] {e}")
        console.print("\nTip: The catalog may be temporarily unavailable. Try again later.")
        raise typer.Exit(1)

@extension_app.command("info")
def extension_info(
    extension: str = typer.Argument(help="Extension ID or name"),
):
    """Show detailed information about an extension."""
    from kiss_cli.extensions import ExtensionCatalog, ExtensionManager, normalize_priority

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    catalog = ExtensionCatalog(project_root)
    manager = ExtensionManager(project_root)
    installed = manager.list_installed()

    # Try to resolve from installed extensions first (by ID or name)
    # Use allow_not_found=True since the extension may be catalog-only
    resolved_installed_id, resolved_installed_name = _resolve_installed_extension(
        extension, installed, "info", allow_not_found=True
    )

    # Try catalog lookup (with error handling)
    # If we resolved an installed extension by display name, use its ID for catalog lookup
    # to ensure we get the correct catalog entry (not a different extension with same name)
    lookup_key = resolved_installed_id if resolved_installed_id else extension
    ext_info, catalog_error = _resolve_catalog_extension(lookup_key, catalog, "info")

    # Case 1: Found in catalog - show full catalog info
    if ext_info:
        _print_extension_info(ext_info, manager)
        return

    # Case 2: Installed locally but catalog lookup failed or not in catalog
    if resolved_installed_id:
        # Get local manifest info
        ext_manifest = manager.get_extension(resolved_installed_id)
        metadata = manager.registry.get(resolved_installed_id)
        metadata_is_dict = isinstance(metadata, dict)
        if not metadata_is_dict:
            console.print(
                "[yellow]Warning:[/yellow] Extension metadata appears to be corrupted; "
                "some information may be unavailable."
            )
        version = metadata.get("version", "unknown") if metadata_is_dict else "unknown"

        console.print(f"\n[bold]{resolved_installed_name}[/bold] (v{version})")
        console.print(f"ID: {resolved_installed_id}")
        console.print()

        if ext_manifest:
            console.print(f"{ext_manifest.description}")
            console.print()
            # Author is optional in extension.yml, safely retrieve it
            author = ext_manifest.data.get("extension", {}).get("author")
            if author:
                console.print(f"[dim]Author:[/dim] {author}")
                console.print()

            if ext_manifest.commands:
                console.print("[bold]Commands:[/bold]")
                for cmd in ext_manifest.commands:
                    console.print(f"  • {cmd['name']}: {cmd.get('description', '')}")
                console.print()

        # Show catalog status
        if catalog_error:
            console.print(f"[yellow]Catalog unavailable:[/yellow] {catalog_error}")
            console.print("[dim]Note: Using locally installed extension; catalog info could not be verified.[/dim]")
        else:
            console.print("[yellow]Note:[/yellow] Not found in catalog (custom/local extension)")

        console.print()
        console.print("[green]✓ Installed[/green]")
        priority = normalize_priority(metadata.get("priority") if metadata_is_dict else None)
        console.print(f"[dim]Priority:[/dim] {priority}")
        console.print(f"\nTo remove: kiss extension remove {resolved_installed_id}")
        return

    # Case 3: Not found anywhere
    if catalog_error:
        console.print(f"[red]Error:[/red] Could not query extension catalog: {catalog_error}")
        console.print("\nTry again when online, or use the extension ID directly.")
    else:
        console.print(f"[red]Error:[/red] Extension '{extension}' not found")
        console.print("\nTry: kiss extension search")
    raise typer.Exit(1)

@extension_app.command("update")
def extension_update(
    extension: str = typer.Argument(None, help="Extension ID or name to update (or all)"),
):
    """Update extension(s) to latest version."""
    from kiss_cli.extensions import (
        ExtensionManager,
        ExtensionCatalog,
        ExtensionError,
        ValidationError,
        CommandRegistrar,
        HookExecutor,
        normalize_priority,
    )
    from packaging import version as pkg_version

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    catalog = ExtensionCatalog(project_root)
    kiss_version = get_kiss_version()

    try:
        # Get list of extensions to update
        installed = manager.list_installed()
        if extension:
            # Update specific extension - resolve ID from argument (handles ambiguous names)
            extension_id, _ = _resolve_installed_extension(extension, installed, "update")
            extensions_to_update = [extension_id]
        else:
            # Update all extensions
            extensions_to_update = [ext["id"] for ext in installed]

        if not extensions_to_update:
            console.print("[yellow]No extensions installed[/yellow]")
            raise typer.Exit(0)

        console.print("🔄 Checking for updates...\n")

        updates_available = []

        for ext_id in extensions_to_update:
            # Get installed version
            metadata = manager.registry.get(ext_id)
            if metadata is None or not isinstance(metadata, dict) or "version" not in metadata:
                console.print(f"⚠  {ext_id}: Registry entry corrupted or missing (skipping)")
                continue
            try:
                installed_version = pkg_version.Version(metadata["version"])
            except pkg_version.InvalidVersion:
                console.print(
                    f"⚠  {ext_id}: Invalid installed version '{metadata.get('version')}' in registry (skipping)"
                )
                continue

            # Get catalog info
            ext_info = catalog.get_extension_info(ext_id)
            if not ext_info:
                console.print(f"⚠  {ext_id}: Not found in catalog (skipping)")
                continue

            # Check if installation is allowed from this catalog
            if not ext_info.get("_install_allowed", True):
                console.print(f"⚠  {ext_id}: Updates not allowed from '{ext_info.get('_catalog_name', 'catalog')}' (skipping)")
                continue

            try:
                catalog_version = pkg_version.Version(ext_info["version"])
            except pkg_version.InvalidVersion:
                console.print(
                    f"⚠  {ext_id}: Invalid catalog version '{ext_info.get('version')}' (skipping)"
                )
                continue

            if catalog_version > installed_version:
                updates_available.append(
                    {
                        "id": ext_id,
                        "name": ext_info.get("name", ext_id),  # Display name for status messages
                        "installed": str(installed_version),
                        "available": str(catalog_version),
                        "download_url": ext_info.get("download_url"),
                    }
                )
            else:
                console.print(f"✓ {ext_id}: Up to date (v{installed_version})")

        if not updates_available:
            console.print("\n[green]All extensions are up to date![/green]")
            raise typer.Exit(0)

        # Show available updates
        console.print("\n[bold]Updates available:[/bold]\n")
        for update in updates_available:
            console.print(
                f"  • {update['id']}: {update['installed']} → {update['available']}"
            )

        console.print()
        confirm = typer.confirm("Update these extensions?")
        if not confirm:
            console.print("Cancelled")
            raise typer.Exit(0)

        # Perform updates with atomic backup/restore
        console.print()
        updated_extensions = []
        failed_updates = []
        registrar = CommandRegistrar()
        hook_executor = HookExecutor(project_root)

        for update in updates_available:
            extension_id = update["id"]
            ext_name = update["name"]  # Use display name for user-facing messages
            console.print(f"📦 Updating {ext_name}...")

            # Backup paths
            backup_base = manager.extensions_dir / ".backup" / f"{extension_id}-update"
            backup_ext_dir = backup_base / "extension"
            backup_commands_dir = backup_base / "commands"
            backup_config_dir = backup_base / "config"

            # Store backup state
            backup_registry_entry = None
            backup_hooks = None  # None means no hooks key in config; {} means hooks key existed
            backed_up_command_files = {}

            try:
                # 1. Backup registry entry (always, even if extension dir doesn't exist)
                backup_registry_entry = manager.registry.get(extension_id)

                # 2. Backup extension directory
                extension_dir = manager.extensions_dir / extension_id
                if extension_dir.exists():
                    backup_base.mkdir(parents=True, exist_ok=True)
                    if backup_ext_dir.exists():
                        shutil.rmtree(backup_ext_dir)
                    shutil.copytree(extension_dir, backup_ext_dir)

                    # Backup config files separately so they can be restored
                    # after a successful install (install_from_directory clears dest dir).
                    config_files = list(extension_dir.glob("*-config.yml")) + list(
                        extension_dir.glob("*-config.local.yml")
                    )
                    for cfg_file in config_files:
                        backup_config_dir.mkdir(parents=True, exist_ok=True)
                        shutil.copy2(cfg_file, backup_config_dir / cfg_file.name)

                # 3. Backup command files for all agents
                from ..agents import CommandRegistrar as _AgentReg
                registered_commands = backup_registry_entry.get("registered_commands", {})
                for agent_name, cmd_names in registered_commands.items():
                    if agent_name not in registrar.AGENT_CONFIGS:
                        continue
                    agent_config = registrar.AGENT_CONFIGS[agent_name]
                    commands_dir = project_root / agent_config["dir"]

                    for cmd_name in cmd_names:
                        output_name = _AgentReg._compute_output_name(agent_name, cmd_name, agent_config)
                        cmd_file = commands_dir / f"{output_name}{agent_config['extension']}"
                        if cmd_file.exists():
                            backup_cmd_path = backup_commands_dir / agent_name / cmd_file.name
                            backup_cmd_path.parent.mkdir(parents=True, exist_ok=True)
                            shutil.copy2(cmd_file, backup_cmd_path)
                            backed_up_command_files[str(cmd_file)] = str(backup_cmd_path)

                # 4. Backup hooks from extensions.yml
                # Use backup_hooks=None to indicate config had no "hooks" key (don't create on restore)
                # Use backup_hooks={} to indicate config had "hooks" key with no hooks for this extension
                config = hook_executor.get_project_config()
                if "hooks" in config:
                    backup_hooks = {}  # Config has hooks key - preserve this fact
                    for hook_name, hook_list in config["hooks"].items():
                        ext_hooks = [h for h in hook_list if h.get("extension") == extension_id]
                        if ext_hooks:
                            backup_hooks[hook_name] = ext_hooks

                # 5. Download new version
                zip_path = catalog.download_extension(extension_id)
                try:
                    # 6. Validate extension ID from ZIP BEFORE modifying installation
                    # Handle both root-level and nested extension.yml (GitHub auto-generated ZIPs)
                    with zipfile.ZipFile(zip_path, "r") as zf:
                        import yaml
                        manifest_data = None
                        namelist = zf.namelist()

                        # First try root-level extension.yml
                        if "extension.yml" in namelist:
                            with zf.open("extension.yml") as f:
                                manifest_data = yaml.safe_load(f) or {}
                        else:
                            # Look for extension.yml in a single top-level subdirectory
                            # (e.g., "repo-name-branch/extension.yml")
                            manifest_paths = [n for n in namelist if n.endswith("/extension.yml") and n.count("/") == 1]
                            if len(manifest_paths) == 1:
                                with zf.open(manifest_paths[0]) as f:
                                    manifest_data = yaml.safe_load(f) or {}

                        if manifest_data is None:
                            raise ValueError("Downloaded extension archive is missing 'extension.yml'")

                    zip_extension_id = manifest_data.get("extension", {}).get("id")
                    if zip_extension_id != extension_id:
                        raise ValueError(
                            f"Extension ID mismatch: expected '{extension_id}', got '{zip_extension_id}'"
                        )

                    # 7. Remove old extension (handles command file cleanup and registry removal)
                    manager.remove(extension_id, keep_config=True)

                    # 8. Install new version
                    _ = manager.install_from_zip(zip_path, kiss_version)

                    # Restore user config files from backup after successful install.
                    new_extension_dir = manager.extensions_dir / extension_id
                    if backup_config_dir.exists() and new_extension_dir.exists():
                        for cfg_file in backup_config_dir.iterdir():
                            if cfg_file.is_file():
                                shutil.copy2(cfg_file, new_extension_dir / cfg_file.name)

                    # 9. Restore metadata from backup (installed_at, enabled state)
                    if backup_registry_entry and isinstance(backup_registry_entry, dict):
                        # Copy current registry entry to avoid mutating internal
                        # registry state before explicit restore().
                        current_metadata = manager.registry.get(extension_id)
                        if current_metadata is None or not isinstance(current_metadata, dict):
                            raise RuntimeError(
                                f"Registry entry for '{extension_id}' missing or corrupted after install — update incomplete"
                            )
                        new_metadata = dict(current_metadata)

                        # Preserve the original installation timestamp
                        if "installed_at" in backup_registry_entry:
                            new_metadata["installed_at"] = backup_registry_entry["installed_at"]

                        # Preserve the original priority (normalized to handle corruption)
                        if "priority" in backup_registry_entry:
                            new_metadata["priority"] = normalize_priority(backup_registry_entry["priority"])

                        # If extension was disabled before update, disable it again
                        if not backup_registry_entry.get("enabled", True):
                            new_metadata["enabled"] = False

                        # Use restore() instead of update() because update() always
                        # preserves the existing installed_at, ignoring our override
                        manager.registry.restore(extension_id, new_metadata)

                        # Also disable hooks in extensions.yml if extension was disabled
                        if not backup_registry_entry.get("enabled", True):
                            config = hook_executor.get_project_config()
                            if "hooks" in config:
                                for hook_name in config["hooks"]:
                                    for hook in config["hooks"][hook_name]:
                                        if hook.get("extension") == extension_id:
                                            hook["enabled"] = False
                                hook_executor.save_project_config(config)
                finally:
                    # Clean up downloaded ZIP
                    if zip_path.exists():
                        zip_path.unlink()

                # 10. Clean up backup on success
                if backup_base.exists():
                    shutil.rmtree(backup_base)

                console.print(f"   [green]✓[/green] Updated to v{update['available']}")
                updated_extensions.append(ext_name)

            except KeyboardInterrupt:
                raise
            except Exception as e:
                console.print(f"   [red]✗[/red] Failed: {e}")
                failed_updates.append((ext_name, str(e)))

                # Rollback on failure
                console.print(f"   [yellow]↩[/yellow] Rolling back {ext_name}...")

                try:
                    # Restore extension directory
                    # Only perform destructive rollback if backup exists (meaning we
                    # actually modified the extension). This avoids deleting a valid
                    # installation when failure happened before changes were made.
                    extension_dir = manager.extensions_dir / extension_id
                    if backup_ext_dir.exists():
                        if extension_dir.exists():
                            shutil.rmtree(extension_dir)
                        shutil.copytree(backup_ext_dir, extension_dir)

                    # Remove any NEW command files created by failed install
                    # (files that weren't in the original backup)
                    try:
                        new_registry_entry = manager.registry.get(extension_id)
                        if new_registry_entry is None or not isinstance(new_registry_entry, dict):
                            new_registered_commands = {}
                        else:
                            new_registered_commands = new_registry_entry.get("registered_commands", {})
                        for agent_name, cmd_names in new_registered_commands.items():
                            if agent_name not in registrar.AGENT_CONFIGS:
                                continue
                            agent_config = registrar.AGENT_CONFIGS[agent_name]
                            commands_dir = project_root / agent_config["dir"]

                            for cmd_name in cmd_names:
                                output_name = _AgentReg._compute_output_name(agent_name, cmd_name, agent_config)
                                cmd_file = commands_dir / f"{output_name}{agent_config['extension']}"
                                # Delete if it exists and wasn't in our backup
                                if cmd_file.exists() and str(cmd_file) not in backed_up_command_files:
                                    cmd_file.unlink()
                    except KeyError:
                        pass  # No new registry entry exists, nothing to clean up

                    # Restore backed up command files
                    for original_path, backup_path in backed_up_command_files.items():
                        backup_file = Path(backup_path)
                        if backup_file.exists():
                            original_file = Path(original_path)
                            original_file.parent.mkdir(parents=True, exist_ok=True)
                            shutil.copy2(backup_file, original_file)

                    # Restore hooks in extensions.yml
                    # - backup_hooks=None means original config had no "hooks" key
                    # - backup_hooks={} or {...} means config had hooks key
                    config = hook_executor.get_project_config()
                    if "hooks" in config:
                        modified = False

                        if backup_hooks is None:
                            # Original config had no "hooks" key; remove it entirely
                            del config["hooks"]
                            modified = True
                        else:
                            # Remove any hooks for this extension added by failed install
                            for hook_name, hooks_list in config["hooks"].items():
                                original_len = len(hooks_list)
                                config["hooks"][hook_name] = [
                                    h for h in hooks_list
                                    if h.get("extension") != extension_id
                                ]
                                if len(config["hooks"][hook_name]) != original_len:
                                    modified = True

                            # Add back the backed up hooks if any
                            if backup_hooks:
                                for hook_name, hooks in backup_hooks.items():
                                    if hook_name not in config["hooks"]:
                                        config["hooks"][hook_name] = []
                                    config["hooks"][hook_name].extend(hooks)
                                    modified = True

                        if modified:
                            hook_executor.save_project_config(config)

                    # Restore registry entry (use restore() since entry was removed)
                    if backup_registry_entry:
                        manager.registry.restore(extension_id, backup_registry_entry)

                    console.print("   [green]✓[/green] Rollback successful")
                    # Clean up backup directory only on successful rollback
                    if backup_base.exists():
                        shutil.rmtree(backup_base)
                except Exception as rollback_error:
                    console.print(f"   [red]✗[/red] Rollback failed: {rollback_error}")
                    console.print(f"   [dim]Backup preserved at: {backup_base}[/dim]")

        # Summary
        console.print()
        if updated_extensions:
            console.print(f"[green]✓[/green] Successfully updated {len(updated_extensions)} extension(s)")
        if failed_updates:
            console.print(f"[red]✗[/red] Failed to update {len(failed_updates)} extension(s):")
            for ext_name, error in failed_updates:
                console.print(f"   • {ext_name}: {error}")
            raise typer.Exit(1)

    except ValidationError as e:
        console.print(f"\n[red]Validation Error:[/red] {e}")
        raise typer.Exit(1)
    except ExtensionError as e:
        console.print(f"\n[red]Error:[/red] {e}")
        raise typer.Exit(1)

@extension_app.command("enable")
def extension_enable(
    extension: str = typer.Argument(help="Extension ID or name to enable"),
):
    """Enable a disabled extension."""
    from kiss_cli.extensions import ExtensionManager, HookExecutor

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    hook_executor = HookExecutor(project_root)

    # Resolve extension ID from argument (handles ambiguous names)
    installed = manager.list_installed()
    extension_id, display_name = _resolve_installed_extension(extension, installed, "enable")

    # Update registry
    metadata = manager.registry.get(extension_id)
    if metadata is None or not isinstance(metadata, dict):
        console.print(f"[red]Error:[/red] Extension '{extension_id}' not found in registry (corrupted state)")
        raise typer.Exit(1)

    if metadata.get("enabled", True):
        console.print(f"[yellow]Extension '{display_name}' is already enabled[/yellow]")
        raise typer.Exit(0)

    manager.registry.update(extension_id, {"enabled": True})

    # Enable hooks in extensions.yml
    config = hook_executor.get_project_config()
    if "hooks" in config:
        for hook_name in config["hooks"]:
            for hook in config["hooks"][hook_name]:
                if hook.get("extension") == extension_id:
                    hook["enabled"] = True
        hook_executor.save_project_config(config)

    console.print(f"[green]✓[/green] Extension '{display_name}' enabled")

@extension_app.command("disable")
def extension_disable(
    extension: str = typer.Argument(help="Extension ID or name to disable"),
):
    """Disable an extension without removing it."""
    from kiss_cli.extensions import ExtensionManager, HookExecutor

    project_root = Path.cwd()

    # Check if we're in a kiss project
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        console.print("Run this command from a kiss project root")
        raise typer.Exit(1)

    manager = ExtensionManager(project_root)
    hook_executor = HookExecutor(project_root)

    # Resolve extension ID from argument (handles ambiguous names)
    installed = manager.list_installed()
    extension_id, display_name = _resolve_installed_extension(extension, installed, "disable")

    # Update registry
    metadata = manager.registry.get(extension_id)
    if metadata is None or not isinstance(metadata, dict):
        console.print(f"[red]Error:[/red] Extension '{extension_id}' not found in registry (corrupted state)")
        raise typer.Exit(1)

    if not metadata.get("enabled", True):
        console.print(f"[yellow]Extension '{display_name}' is already disabled[/yellow]")
        raise typer.Exit(0)

    manager.registry.update(extension_id, {"enabled": False})

    # Disable hooks in extensions.yml
    config = hook_executor.get_project_config()
    if "hooks" in config:
        for hook_name in config["hooks"]:
            for hook in config["hooks"][hook_name]:
                if hook.get("extension") == extension_id:
                    hook["enabled"] = False
        hook_executor.save_project_config(config)

    console.print(f"[green]✓[/green] Extension '{display_name}' disabled")
    console.print("\nCommands will no longer be available. Hooks will not execute.")
    console.print(f"To re-enable: kiss extension enable {extension_id}")

@extension_app.command("set-priority")
def extension_set_priority(
    extension: str = typer.Argument(help="Extension ID or name"),
    priority: int = typer.Argument(help="New priority (lower = higher precedence)"),
):
    """Set the resolution priority of an installed extension."""
    from kiss_cli.extensions import ExtensionManager

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

    manager = ExtensionManager(project_root)

    # Resolve extension ID from argument (handles ambiguous names)
    installed = manager.list_installed()
    extension_id, display_name = _resolve_installed_extension(extension, installed, "set-priority")

    # Get current metadata
    metadata = manager.registry.get(extension_id)
    if metadata is None or not isinstance(metadata, dict):
        console.print(f"[red]Error:[/red] Extension '{extension_id}' not found in registry (corrupted state)")
        raise typer.Exit(1)

    from kiss_cli.extensions import normalize_priority
    raw_priority = metadata.get("priority")
    # Only skip if the stored value is already a valid int equal to requested priority
    # This ensures corrupted values (e.g., "high") get repaired even when setting to default (10)
    if isinstance(raw_priority, int) and raw_priority == priority:
        console.print(f"[yellow]Extension '{display_name}' already has priority {priority}[/yellow]")
        raise typer.Exit(0)

    old_priority = normalize_priority(raw_priority)

    # Update priority
    manager.registry.update(extension_id, {"priority": priority})

    console.print(f"[green]✓[/green] Extension '{display_name}' priority changed: {old_priority} → {priority}")
    console.print("\n[dim]Lower priority = higher precedence in template resolution[/dim]")
