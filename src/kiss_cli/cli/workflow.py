"""Workflow management commands (`kiss workflow ...`, `kiss workflow-catalog ...`)."""

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

workflow_app = typer.Typer(
    name="workflow",
    help="Manage and run automation workflows",
    add_completion=False,
)

app.add_typer(workflow_app, name="workflow")

workflow_catalog_app = typer.Typer(
    name="catalog",
    help="Manage workflow catalogs",
    add_completion=False,
)

workflow_app.add_typer(workflow_catalog_app, name="catalog")

@workflow_app.command("run")
def workflow_run(
    source: str = typer.Argument(..., help="Workflow ID or YAML file path"),
    input_values: list[str] | None = typer.Option(
        None, "--input", "-i", help="Input values as key=value pairs"
    ),
):
    """Run a workflow from an installed ID or local YAML path."""
    from ..workflows.engine import WorkflowEngine

    project_root = Path.cwd()
    if not (project_root / ".kiss").exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)
    engine = WorkflowEngine(project_root)
    engine.on_step_start = lambda sid, label: console.print(f"  \u25b8 [{sid}] {label} \u2026")

    try:
        definition = engine.load_workflow(source)
    except FileNotFoundError:
        console.print(f"[red]Error:[/red] Workflow not found: {source}")
        raise typer.Exit(1)
    except ValueError as exc:
        console.print(f"[red]Error:[/red] Invalid workflow: {exc}")
        raise typer.Exit(1)

    # Validate
    errors = engine.validate(definition)
    if errors:
        console.print("[red]Workflow validation failed:[/red]")
        for err in errors:
            console.print(f"  • {err}")
        raise typer.Exit(1)

    # Parse inputs
    inputs: dict[str, Any] = {}
    if input_values:
        for kv in input_values:
            if "=" not in kv:
                console.print(f"[red]Error:[/red] Invalid input format: {kv!r} (expected key=value)")
                raise typer.Exit(1)
            key, _, value = kv.partition("=")
            inputs[key.strip()] = value.strip()

    console.print(f"\n[bold cyan]Running workflow:[/bold cyan] {definition.name} ({definition.id})")
    console.print(f"[dim]Version: {definition.version}[/dim]\n")

    try:
        state = engine.execute(definition, inputs)
    except ValueError as exc:
        console.print(f"[red]Error:[/red] {exc}")
        raise typer.Exit(1)
    except Exception as exc:
        console.print(f"[red]Workflow failed:[/red] {exc}")
        raise typer.Exit(1)

    status_colors = {
        "completed": "green",
        "paused": "yellow",
        "failed": "red",
        "aborted": "red",
    }
    color = status_colors.get(state.status.value, "white")
    console.print(f"\n[{color}]Status: {state.status.value}[/{color}]")
    console.print(f"[dim]Run ID: {state.run_id}[/dim]")

    if state.status.value == "paused":
        console.print(f"\nResume with: [cyan]kiss workflow resume {state.run_id}[/cyan]")

@workflow_app.command("resume")
def workflow_resume(
    run_id: str = typer.Argument(..., help="Run ID to resume"),
):
    """Resume a paused or failed workflow run."""
    from ..workflows.engine import WorkflowEngine

    project_root = Path.cwd()
    if not (project_root / ".kiss").exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)
    engine = WorkflowEngine(project_root)
    engine.on_step_start = lambda sid, label: console.print(f"  \u25b8 [{sid}] {label} \u2026")

    try:
        state = engine.resume(run_id)
    except FileNotFoundError:
        console.print(f"[red]Error:[/red] Run not found: {run_id}")
        raise typer.Exit(1)
    except ValueError as exc:
        console.print(f"[red]Error:[/red] {exc}")
        raise typer.Exit(1)
    except Exception as exc:
        console.print(f"[red]Resume failed:[/red] {exc}")
        raise typer.Exit(1)

    status_colors = {
        "completed": "green",
        "paused": "yellow",
        "failed": "red",
        "aborted": "red",
    }
    color = status_colors.get(state.status.value, "white")
    console.print(f"\n[{color}]Status: {state.status.value}[/{color}]")

@workflow_app.command("status")
def workflow_status(
    run_id: str | None = typer.Argument(None, help="Run ID to inspect (shows all if omitted)"),
):
    """Show workflow run status."""
    from ..workflows.engine import WorkflowEngine

    project_root = Path.cwd()
    if not (project_root / ".kiss").exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)
    engine = WorkflowEngine(project_root)

    if run_id:
        try:
            from ..workflows.engine import RunState
            state = RunState.load(run_id, project_root)
        except FileNotFoundError:
            console.print(f"[red]Error:[/red] Run not found: {run_id}")
            raise typer.Exit(1)

        status_colors = {
            "completed": "green",
            "paused": "yellow",
            "failed": "red",
            "aborted": "red",
            "running": "blue",
            "created": "dim",
        }
        color = status_colors.get(state.status.value, "white")

        console.print(f"\n[bold cyan]Workflow Run: {state.run_id}[/bold cyan]")
        console.print(f"  Workflow: {state.workflow_id}")
        console.print(f"  Status:   [{color}]{state.status.value}[/{color}]")
        console.print(f"  Created:  {state.created_at}")
        console.print(f"  Updated:  {state.updated_at}")

        if state.current_step_id:
            console.print(f"  Current:  {state.current_step_id}")

        if state.step_results:
            console.print(f"\n  [bold]Steps ({len(state.step_results)}):[/bold]")
            for step_id, step_data in state.step_results.items():
                s = step_data.get("status", "unknown")
                sc = {"completed": "green", "failed": "red", "paused": "yellow"}.get(s, "white")
                console.print(f"    [{sc}]●[/{sc}] {step_id}: {s}")
    else:
        runs = engine.list_runs()
        if not runs:
            console.print("[yellow]No workflow runs found.[/yellow]")
            return

        console.print("\n[bold cyan]Workflow Runs:[/bold cyan]\n")
        for run_data in runs:
            s = run_data.get("status", "unknown")
            sc = {"completed": "green", "failed": "red", "paused": "yellow", "running": "blue"}.get(s, "white")
            console.print(
                f"  [{sc}]●[/{sc}] {run_data['run_id']}  "
                f"{run_data.get('workflow_id', '?')}  "
                f"[{sc}]{s}[/{sc}]  "
                f"[dim]{run_data.get('updated_at', '?')}[/dim]"
            )

@workflow_app.command("list")
def workflow_list():
    """List installed workflows."""
    from ..workflows.catalog import WorkflowRegistry

    project_root = Path.cwd()
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)

    registry = WorkflowRegistry(project_root)
    installed = registry.list()

    if not installed:
        console.print("[yellow]No workflows installed.[/yellow]")
        console.print("\nInstall a workflow with:")
        console.print("  [cyan]kiss workflow add <workflow-id>[/cyan]")
        return

    console.print("\n[bold cyan]Installed Workflows:[/bold cyan]\n")
    for wf_id, wf_data in installed.items():
        console.print(f"  [bold]{wf_data.get('name', wf_id)}[/bold] ({wf_id}) v{wf_data.get('version', '?')}")
        desc = wf_data.get("description", "")
        if desc:
            console.print(f"    {desc}")
        console.print()

@workflow_app.command("add")
def workflow_add(
    source: str = typer.Argument(..., help="Workflow ID, URL, or local path"),
):
    """Install a workflow from catalog, URL, or local path."""
    from ..workflows.catalog import WorkflowCatalog, WorkflowRegistry, WorkflowCatalogError
    from ..workflows.engine import WorkflowDefinition

    project_root = Path.cwd()
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)

    registry = WorkflowRegistry(project_root)
    workflows_dir = project_root / ".kiss" / "workflows"

    def _validate_and_install_local(yaml_path: Path, source_label: str) -> None:
        """Validate and install a workflow from a local YAML file."""
        try:
            definition = WorkflowDefinition.from_yaml(yaml_path)
        except (ValueError, yaml.YAMLError) as exc:
            console.print(f"[red]Error:[/red] Invalid workflow YAML: {exc}")
            raise typer.Exit(1)
        if not definition.id or not definition.id.strip():
            console.print("[red]Error:[/red] Workflow definition has an empty or missing 'id'")
            raise typer.Exit(1)

        from ..workflows.engine import validate_workflow
        errors = validate_workflow(definition)
        if errors:
            console.print("[red]Error:[/red] Workflow validation failed:")
            for err in errors:
                console.print(f"  \u2022 {err}")
            raise typer.Exit(1)

        dest_dir = workflows_dir / definition.id
        dest_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(yaml_path, dest_dir / "workflow.yml")
        registry.add(definition.id, {
            "name": definition.name,
            "version": definition.version,
            "description": definition.description,
            "source": source_label,
        })
        console.print(f"[green]✓[/green] Workflow '{definition.name}' ({definition.id}) installed")

    # kiss is offline-only: reject URL sources up-front.
    if source.startswith("http://") or source.startswith("https://"):
        console.print(
            "[red]Error:[/red] kiss is offline-only; workflows can only be installed "
            "from a local path or the bundled catalog."
        )
        raise typer.Exit(1)

    # Try as a local file/directory
    source_path = Path(source)
    if source_path.exists():
        if source_path.is_file() and source_path.suffix in (".yml", ".yaml"):
            _validate_and_install_local(source_path, str(source_path))
            return
        elif source_path.is_dir():
            wf_file = source_path / "workflow.yml"
            if not wf_file.exists():
                console.print(f"[red]Error:[/red] No workflow.yml found in {source}")
                raise typer.Exit(1)
            _validate_and_install_local(wf_file, str(source_path))
            return

    # Look up in the bundled catalog and install from a bundled workflow
    # directory if one exists. kiss is offline-only, so there is no
    # fallback to downloading the workflow from a remote URL.
    catalog = WorkflowCatalog(project_root)
    try:
        info = catalog.get_workflow_info(source)
    except WorkflowCatalogError as exc:
        console.print(f"[red]Error:[/red] {exc}")
        raise typer.Exit(1)

    if not info:
        console.print(f"[red]Error:[/red] Workflow '{source}' not found in catalog")
        raise typer.Exit(1)

    bundled_workflow = _locate_bundled_workflow(source)
    if bundled_workflow is None:
        console.print(
            f"[red]Error:[/red] Workflow '{source}' is not bundled with kiss."
        )
        console.print(
            "kiss is offline-only; only bundled workflows can be installed from the catalog."
        )
        raise typer.Exit(1)

    bundled_yaml = bundled_workflow / "workflow.yml"
    if not bundled_yaml.exists():
        console.print(
            f"[red]Error:[/red] Bundled workflow '{source}' is missing workflow.yml"
        )
        raise typer.Exit(1)
    _validate_and_install_local(bundled_yaml, f"bundled:{source}")

@workflow_app.command("remove")
def workflow_remove(
    workflow_id: str = typer.Argument(..., help="Workflow ID to uninstall"),
):
    """Uninstall a workflow."""
    from ..workflows.catalog import WorkflowRegistry

    project_root = Path.cwd()
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)

    registry = WorkflowRegistry(project_root)

    if not registry.is_installed(workflow_id):
        console.print(f"[red]Error:[/red] Workflow '{workflow_id}' is not installed")
        raise typer.Exit(1)

    # Remove workflow files
    workflow_dir = project_root / ".kiss" / "workflows" / workflow_id
    if workflow_dir.exists():
        import shutil
        shutil.rmtree(workflow_dir)

    registry.remove(workflow_id)
    console.print(f"[green]✓[/green] Workflow '{workflow_id}' removed")

@workflow_app.command("search")
def workflow_search(
    query: str | None = typer.Argument(None, help="Search query"),
    tag: str | None = typer.Option(None, "--tag", help="Filter by tag"),
):
    """Search workflow catalogs."""
    from ..workflows.catalog import WorkflowCatalog, WorkflowCatalogError

    project_root = Path.cwd()
    if not (project_root / ".kiss").exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)
    catalog = WorkflowCatalog(project_root)

    try:
        results = catalog.search(query=query, tag=tag)
    except WorkflowCatalogError as exc:
        console.print(f"[red]Error:[/red] {exc}")
        raise typer.Exit(1)

    if not results:
        console.print("[yellow]No workflows found.[/yellow]")
        return

    console.print(f"\n[bold cyan]Workflows ({len(results)}):[/bold cyan]\n")
    for wf in results:
        console.print(f"  [bold]{wf.get('name', wf.get('id', '?'))}[/bold] ({wf.get('id', '?')}) v{wf.get('version', '?')}")
        desc = wf.get("description", "")
        if desc:
            console.print(f"    {desc}")
        tags = wf.get("tags", [])
        if tags:
            console.print(f"    [dim]Tags: {', '.join(tags)}[/dim]")
        console.print()

@workflow_app.command("info")
def workflow_info(
    workflow_id: str = typer.Argument(..., help="Workflow ID"),
):
    """Show workflow details and step graph."""
    from ..workflows.catalog import WorkflowCatalog, WorkflowRegistry, WorkflowCatalogError
    from ..workflows.engine import WorkflowEngine

    project_root = Path.cwd()
    if not (project_root / ".kiss").exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)

    # Check installed first
    registry = WorkflowRegistry(project_root)
    installed = registry.get(workflow_id)

    engine = WorkflowEngine(project_root)

    definition = None
    try:
        definition = engine.load_workflow(workflow_id)
    except FileNotFoundError:
        # Local workflow definition not found on disk; fall back to
        # catalog/registry lookup below.
        pass

    if definition:
        console.print(f"\n[bold cyan]{definition.name}[/bold cyan] ({definition.id})")
        console.print(f"  Version:     {definition.version}")
        if definition.author:
            console.print(f"  Author:      {definition.author}")
        if definition.description:
            console.print(f"  Description: {definition.description}")
        if definition.default_integration:
            console.print(f"  Integration: {definition.default_integration}")
        if installed:
            console.print("  [green]Installed[/green]")

        if definition.inputs:
            console.print("\n  [bold]Inputs:[/bold]")
            for name, inp in definition.inputs.items():
                if isinstance(inp, dict):
                    req = "required" if inp.get("required") else "optional"
                    console.print(f"    {name} ({inp.get('type', 'string')}) — {req}")

        if definition.steps:
            console.print(f"\n  [bold]Steps ({len(definition.steps)}):[/bold]")
            for step in definition.steps:
                stype = step.get("type", "command")
                console.print(f"    → {step.get('id', '?')} [{stype}]")
        return

    # Try catalog
    catalog = WorkflowCatalog(project_root)
    try:
        info = catalog.get_workflow_info(workflow_id)
    except WorkflowCatalogError:
        info = None

    if info:
        console.print(f"\n[bold cyan]{info.get('name', workflow_id)}[/bold cyan] ({workflow_id})")
        console.print(f"  Version:     {info.get('version', '?')}")
        if info.get("description"):
            console.print(f"  Description: {info['description']}")
        if info.get("tags"):
            console.print(f"  Tags:        {', '.join(info['tags'])}")
        console.print("  [yellow]Not installed[/yellow]")
    else:
        console.print(f"[red]Error:[/red] Workflow '{workflow_id}' not found")
        raise typer.Exit(1)

@workflow_catalog_app.command("list")
def workflow_catalog_list():
    """List configured workflow catalog sources."""
    from ..workflows.catalog import WorkflowCatalog, WorkflowCatalogError

    project_root = Path.cwd()
    catalog = WorkflowCatalog(project_root)

    try:
        configs = catalog.get_catalog_configs()
    except WorkflowCatalogError as exc:
        console.print(f"[red]Error:[/red] {exc}")
        raise typer.Exit(1)

    console.print("\n[bold cyan]Workflow Catalog Sources:[/bold cyan]\n")
    for i, cfg in enumerate(configs):
        install_status = "[green]install allowed[/green]" if cfg["install_allowed"] else "[yellow]discovery only[/yellow]"
        console.print(f"  [{i}] [bold]{cfg['name']}[/bold] — {install_status}")
        console.print(f"      {cfg['url']}")
        if cfg.get("description"):
            console.print(f"      [dim]{cfg['description']}[/dim]")
        console.print()

@workflow_catalog_app.command("add")
def workflow_catalog_add(
    url: str = typer.Argument(..., help="Catalog URL to add"),
    name: str = typer.Option(None, "--name", help="Catalog name"),
):
    """Add a workflow catalog source."""
    from ..workflows.catalog import WorkflowCatalog, WorkflowValidationError

    project_root = Path.cwd()
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)

    catalog = WorkflowCatalog(project_root)
    try:
        catalog.add_catalog(url, name)
    except WorkflowValidationError as exc:
        console.print(f"[red]Error:[/red] {exc}")
        raise typer.Exit(1)

    console.print(f"[green]✓[/green] Catalog source added: {url}")

@workflow_catalog_app.command("remove")
def workflow_catalog_remove(
    index: int = typer.Argument(..., help="Catalog index to remove (from 'catalog list')"),
):
    """Remove a workflow catalog source by index."""
    from ..workflows.catalog import WorkflowCatalog, WorkflowValidationError

    project_root = Path.cwd()
    kiss_dir = project_root / ".kiss"
    if not kiss_dir.exists():
        console.print("[red]Error:[/red] Not a kiss project (no .kiss/ directory)")
        raise typer.Exit(1)

    catalog = WorkflowCatalog(project_root)
    try:
        removed_name = catalog.remove_catalog(index)
    except WorkflowValidationError as exc:
        console.print(f"[red]Error:[/red] {exc}")
        raise typer.Exit(1)

    console.print(f"[green]✓[/green] Catalog source '{removed_name}' removed")
