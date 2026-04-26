"""Health check commands for kiss projects.

Provides:
- `kiss check --skills` — validate installed skill files
- `kiss check --integrations` — check integration configs exist
- `kiss check --context` — validate .kiss/context.yml schema
- `kiss check` (no subcommand) — run all three checks in sequence
"""

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import typer
import yaml
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from kiss_cli.integrations import get_integration
from kiss_cli.installer import _read_integration_json
from . import app


@dataclass
class CheckFinding:
    """A single finding from a kiss check sub-command."""

    file: str
    check: str  # "skills", "integrations", "context"
    expected: str
    actual: str
    fix: str

# Sub-app so `kiss check ...` groups the health-check commands under a single
# subcommand namespace. Registered with the main app at the bottom of this
# module so decorators fire at import time.
check_app = typer.Typer(
    name="check",
    help="Run health checks on the kiss project",
    add_completion=False,
    invoke_without_command=True,
)

console = Console()

# Allowed top-level frontmatter fields per agentskills.io
ALLOWED_FRONTMATTER_FIELDS = {
    "name",
    "description",
    "license",
    "compatibility",
    "metadata",
    "allowed-tools",
}

# Standard placeholder vocabulary (Phase 5.3)
STANDARD_PLACEHOLDERS = {
    "{context.paths.specs}",
    "{context.paths.plans}",
    "{context.paths.tasks}",
    "{context.paths.templates}",
    "{context.paths.scripts}",
    "{context.current.feature}",
    "{context.current.spec}",
    "{context.current.plan}",
    "{context.current.tasks}",
    "{context.current.checklist}",
    "{context.current.branch}",
    "{context.preferences.confirm_before_write}",
}

# Required body sections per Phase 5.4
REQUIRED_BODY_SECTIONS = {
    "## Inputs",
    "## Outputs",
    "## Context Update",
}

# Integration key to default install directory mapping
INTEGRATION_INSTALL_DIRS = {
    "claude": ".claude/skills",
    "copilot": ".github/skills",
    "cursor-agent": ".cursor/skills",
    "opencode": ".opencode/skills",
    "windsurf": ".windsurf/skills",
    "gemini": ".gemini/skills",
    "codex": ".codex/skills",
}


def _extract_frontmatter_and_body(content: str) -> tuple[dict[str, Any], str]:
    """Extract YAML frontmatter and Markdown body."""
    lines = content.split('\n')
    if not lines or not lines[0].startswith('---'):
        return {}, content

    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].startswith('---'):
            end_idx = i
            break

    if end_idx is None:
        return {}, content

    fm_text = '\n'.join(lines[1:end_idx])
    body_text = '\n'.join(lines[end_idx+1:])

    try:
        fm = yaml.safe_load(fm_text) or {}
    except yaml.YAMLError:
        fm = {}

    return fm, body_text


def _validate_skill_file(skill_path: Path) -> tuple[bool, str]:
    """Validate a single skill file for agentskills.io compliance.

    Returns (is_valid, message).
    """
    try:
        content = skill_path.read_text(encoding="utf-8")
    except Exception as e:
        return False, f"Failed to read: {e}"

    fm, body = _extract_frontmatter_and_body(content)

    # Check: has name and description
    if "name" not in fm:
        return False, "Missing 'name' field"
    if "description" not in fm:
        return False, "Missing 'description' field"

    # Check: only allowed frontmatter fields
    non_standard = set(fm.keys()) - ALLOWED_FRONTMATTER_FIELDS
    if non_standard:
        return False, f"Non-standard frontmatter fields: {non_standard}"

    # Check: name format
    name = fm.get("name", "")
    if not (1 <= len(name) <= 64):
        return False, f"Name length {len(name)} not in range 1-64"
    if not re.match(r'^[a-z0-9]+(-[a-z0-9]+)*$', name):
        return False, f"Name format invalid: {name}"

    # Check: description length
    desc = fm.get("description", "")
    if not (1 <= len(desc) <= 1024):
        return False, f"Description length {len(desc)} not in range 1-1024"

    # Check: has required body sections
    missing_sections = []
    for section in REQUIRED_BODY_SECTIONS:
        if section not in body:
            missing_sections.append(section)
    if missing_sections:
        return False, f"Missing body sections: {missing_sections}"

    # Check: no handoffs in frontmatter
    if "handoffs" in fm:
        return False, "Handoffs must be in body (## Handoffs), not frontmatter"

    # Check: no hardcoded paths
    hardcoded_patterns = [
        r'\.specify/specs/',
        r'\.specify/plans/',
        r'\.specify/taskify/',
        r'\.specify/templates/',
        r'\.specify/scripts/',
        r'\.kiss/specs/',
        r'\.kiss/plans/',
        r'\.kiss/tasks/',
        r'\.kiss/templates/',
        r'\.kiss/scripts/',
    ]
    for pattern in hardcoded_patterns:
        if re.search(pattern, body):
            return False, f"Hardcoded path found: {pattern}"

    # Check: only standard placeholders
    found_placeholders = set(re.findall(r'\{context\.\S+?\}', body))
    non_standard = found_placeholders - STANDARD_PLACEHOLDERS
    if non_standard:
        return False, f"Non-standard placeholders: {non_standard}"

    # Check: metadata has author and version
    metadata = fm.get("metadata", {})
    if "author" not in metadata:
        return False, "Missing metadata.author"
    if "version" not in metadata:
        return False, "Missing metadata.version"

    return True, "OK"


def _get_integration_install_dir(integration_key: str) -> Path | None:
    """Get the install directory for an integration.

    First tries to read from the integration's config (folder + skills_subdir).
    Falls back to hardcoded map if not available.
    """
    integration = get_integration(integration_key)
    if integration and integration.config:
        folder = integration.config.get("folder")
        subdir = integration.config.get("skills_subdir", "commands")
        if folder:
            return Path(folder) / subdir

    # Fallback to hardcoded map
    return Path(INTEGRATION_INSTALL_DIRS.get(integration_key, ""))


def _get_installed_integrations(project_root: Path) -> list[str]:
    """Get the list of installed integrations from integration.json or init-options.json."""
    data = _read_integration_json(project_root)
    keys = data.get("integrations", [])
    if keys:
        return keys
    # Fallback to init-options.json
    init_options_path = project_root / ".kiss" / "init-options.json"
    if init_options_path.exists():
        try:
            opts = json.loads(init_options_path.read_text(encoding="utf-8"))
            return opts.get("integrations", [])
        except Exception:
            pass
    return []


def check_skills(project_root: Path | None = None) -> tuple[int, list[CheckFinding]]:
    """Validate all skill files in integration directories.

    Returns (exit_code, findings_list).
    """
    if project_root is None:
        project_root = Path.cwd()

    findings: list[CheckFinding] = []
    integrations = _get_installed_integrations(project_root)
    if not integrations:
        console.print("[yellow]No integrations configured[/yellow]")
        return 0, findings

    total = 0
    passed = 0

    for integration_key in integrations:
        skill_dir = _get_integration_install_dir(integration_key)
        if not skill_dir:
            findings.append(CheckFinding(
                file=integration_key, check="skills",
                expected="Known integration key",
                actual=f"Unknown integration: {integration_key}",
                fix=f"Run kiss integration install {integration_key}",
            ))
            continue

        full_skill_dir = project_root / skill_dir
        if not full_skill_dir.exists():
            findings.append(CheckFinding(
                file=str(skill_dir), check="skills",
                expected="Skill directory exists",
                actual="Directory not found",
                fix=f"Run kiss integration install {integration_key}",
            ))
            continue

        for subdir in full_skill_dir.iterdir():
            if not subdir.is_dir():
                continue
            skill_file = subdir / "SKILL.md"
            if skill_file.exists():
                total += 1
                is_valid, message = _validate_skill_file(skill_file)
                if is_valid:
                    passed += 1
                else:
                    findings.append(CheckFinding(
                        file=str(skill_file.relative_to(project_root)),
                        check="skills",
                        expected="Valid SKILL.md",
                        actual=message,
                        fix=f"Run kiss integration upgrade {integration_key} --force",
                    ))

    # Print summary
    console.print()
    summary = f"Skills: {passed}/{total} passed" if total else "No skill files found"
    if not findings:
        console.print(f"[green]{summary}[/green]")
    else:
        console.print(f"[red]{summary}[/red]")

    return (0 if not findings else 1), findings


def check_integrations(project_root: Path | None = None) -> tuple[int, list[CheckFinding]]:
    """Check that integration config files exist.

    Returns (exit_code, findings_list).
    """
    if project_root is None:
        project_root = Path.cwd()

    findings: list[CheckFinding] = []
    integrations = _get_installed_integrations(project_root)
    if not integrations:
        console.print("[yellow]No integrations configured[/yellow]")
        return 0, findings

    expected_dirs: dict[str, Path] = {}

    for integration_key in integrations:
        integration = get_integration(integration_key)
        if not integration:
            findings.append(CheckFinding(
                file=integration_key, check="integrations",
                expected="Registered integration",
                actual=f"Unknown integration: {integration_key}",
                fix=f"Remove '{integration_key}' from .kiss/integration.json",
            ))
            continue

        skill_dir = _get_integration_install_dir(integration_key)
        if not skill_dir:
            findings.append(CheckFinding(
                file=integration_key, check="integrations",
                expected="Install directory determinable",
                actual="Cannot determine install dir",
                fix=f"Run kiss integration install {integration_key}",
            ))
            continue

        expected_dirs[integration_key] = skill_dir
        full_path = project_root / skill_dir
        if full_path.exists():
            console.print(f"  [green]✓[/green] {integration_key}: {skill_dir}")
        else:
            findings.append(CheckFinding(
                file=str(skill_dir), check="integrations",
                expected="Directory exists",
                actual="MISSING",
                fix=f"Run kiss integration install {integration_key}",
            ))

    # Scan for orphaned integration files
    for expected_key, expected_dir in expected_dirs.items():
        parent_dir = project_root / expected_dir.parent
        if not parent_dir.exists():
            continue
        for item in parent_dir.iterdir():
            if not item.is_dir():
                continue
            is_configured = any(
                item.name == dir_path.name
                for dir_path in expected_dirs.values()
            )
            if not is_configured:
                findings.append(CheckFinding(
                    file=str(item.relative_to(project_root)),
                    check="integrations",
                    expected="Belongs to a configured integration",
                    actual="Orphaned directory",
                    fix="Remove manually or run kiss integration uninstall",
                ))

    console.print()
    if not findings:
        console.print("[green]Integrations: OK[/green]")
    else:
        console.print("[red]Integrations: Issues found[/red]")

    return (0 if not findings else 1), findings


def check_context(project_root: Path | None = None) -> tuple[int, list[CheckFinding]]:
    """Validate .kiss/context.yml schema.

    Checks:
    - schema_version == "1.0"
    - Top-level keys are {schema_version, paths, current, preferences, integrations}
    - paths.* has string values for {specs, plans, taskify, templates, scripts}
    - current.* has string or null values for {feature, spec, plan, taskify, checklist, branch}
    - preferences.* has correct types
    - Each paths.* directory exists (warn if not)
    - Each current.* path file exists (warn if not)

    Returns (exit_code, findings_list).
    """
    if project_root is None:
        project_root = Path.cwd()

    findings: list[CheckFinding] = []
    context_path = project_root / ".kiss" / "context.yml"
    if not context_path.exists():
        console.print("[yellow]Warning: .kiss/context.yml not found[/yellow]")
        return 0, findings

    try:
        context = yaml.safe_load(context_path.read_text(encoding="utf-8")) or {}
    except Exception as e:
        console.print(f"[red]Error parsing context.yml: {e}[/red]")
        findings.append(CheckFinding(
            file=".kiss/context.yml", check="context",
            expected="Valid YAML", actual=str(e),
            fix="Fix the YAML syntax or delete and re-run kiss init --here",
        ))
        return 1, findings

    errors = []
    warnings = []

    # Check: schema_version == "1.0"
    schema_version = context.get("schema_version")
    if schema_version != "1.0":
        errors.append(f"schema_version: expected '1.0', got {schema_version!r}")

    # Check: top-level keys
    expected_keys = {
        "schema_version",
        "paths",
        "current",
        "preferences",
        "language",
        "integrations",
    }
    actual_keys = set(context.keys())
    if actual_keys != expected_keys:
        missing = expected_keys - actual_keys
        extra = actual_keys - expected_keys
        if missing:
            errors.append(f"Missing top-level keys: {missing}")
        if extra:
            errors.append(f"Extra top-level keys: {extra}")

    # Check: paths section
    paths = context.get("paths", {})
    if isinstance(paths, dict):
        expected_path_keys = {"docs", "specs", "plans", "tasks", "templates", "scripts"}
        actual_path_keys = set(paths.keys())
        if actual_path_keys != expected_path_keys:
            missing = expected_path_keys - actual_path_keys
            extra = actual_path_keys - expected_path_keys
            if missing:
                errors.append(f"paths: missing keys {missing}")
            if extra:
                errors.append(f"paths: extra keys {extra}")

        # Check: paths.* values are strings and directories exist
        for key, value in paths.items():
            if not isinstance(value, str):
                errors.append(f"paths.{key}: expected string, got {type(value).__name__}")
            else:
                path_obj = project_root / value
                if not path_obj.exists():
                    warnings.append(f"paths.{key}: directory does not exist ({value})")

    else:
        errors.append(f"paths: expected dict, got {type(paths).__name__}")

    # Check: current section
    current = context.get("current", {})
    if isinstance(current, dict):
        expected_current_keys = {"feature", "spec", "plan", "tasks", "checklist", "branch"}
        actual_current_keys = set(current.keys())
        if actual_current_keys != expected_current_keys:
            missing = expected_current_keys - actual_current_keys
            extra = actual_current_keys - expected_current_keys
            if missing:
                errors.append(f"current: missing keys {missing}")
            if extra:
                errors.append(f"current: extra keys {extra}")

        # Check: current.* values are strings or null
        for key, value in current.items():
            if value is not None and not isinstance(value, str):
                errors.append(
                    f"current.{key}: expected string or null, got {type(value).__name__}"
                )
            elif isinstance(value, str):
                # File exists check (warn only)
                file_obj = project_root / value
                if not file_obj.exists():
                    warnings.append(f"current.{key}: file does not exist ({value})")

    else:
        errors.append(f"current: expected dict, got {type(current).__name__}")

    # Check: preferences section
    preferences = context.get("preferences", {})
    if isinstance(preferences, dict):
        expected_pref_keys = {
            "output_format",
            "task_numbering",
            "confirm_before_write",
            "auto_update_context",
        }
        actual_pref_keys = set(preferences.keys())
        if actual_pref_keys != expected_pref_keys:
            missing = expected_pref_keys - actual_pref_keys
            extra = actual_pref_keys - expected_pref_keys
            if missing:
                errors.append(f"preferences: missing keys {missing}")
            if extra:
                errors.append(f"preferences: extra keys {extra}")

        # Check: preferences.* types
        type_checks = {
            "output_format": str,
            "task_numbering": str,
            "confirm_before_write": bool,
            "auto_update_context": bool,
        }
        for key, expected_type in type_checks.items():
            value = preferences.get(key)
            if value is not None and not isinstance(value, expected_type):
                errors.append(
                    f"preferences.{key}: expected {expected_type.__name__}, "
                    f"got {type(value).__name__}"
                )

    else:
        errors.append(f"preferences: expected dict, got {type(preferences).__name__}")

    # Check: language section
    language = context.get("language", {})
    if isinstance(language, dict):
        expected_language_keys = {"output", "interaction"}
        actual_language_keys = set(language.keys())
        if actual_language_keys != expected_language_keys:
            missing = expected_language_keys - actual_language_keys
            extra = actual_language_keys - expected_language_keys
            if missing:
                errors.append(f"language: missing keys {missing}")
            if extra:
                errors.append(f"language: extra keys {extra}")

        # Check: language.* values are non-empty strings
        for key in ("output", "interaction"):
            value = language.get(key)
            if value is None:
                continue
            if not isinstance(value, str):
                errors.append(
                    f"language.{key}: expected string, got {type(value).__name__}"
                )
            elif not value.strip():
                errors.append(f"language.{key}: must be a non-empty string")

    else:
        errors.append(f"language: expected dict, got {type(language).__name__}")

    # Check: integrations is a list
    integrations = context.get("integrations")
    if not isinstance(integrations, list):
        errors.append(
            f"integrations: expected list, got {type(integrations).__name__}"
        )

    # Print results
    console.print()
    for warning in warnings:
        console.print(f"  [yellow]⚠[/yellow] {warning}")

    if errors:
        for error in errors:
            console.print(f"  [red]✗[/red] {error}")
            findings.append(CheckFinding(
                file=".kiss/context.yml", check="context",
                expected="Valid schema", actual=error,
                fix="Edit .kiss/context.yml to fix the issue, or delete and re-run kiss init --here",
            ))
        console.print("[red]Context: FAILED[/red]")
    else:
        console.print("[green]Context: OK[/green]")

    return (1 if findings else 0), findings


def _render_findings(findings: list[CheckFinding]) -> None:
    """Render a Rich table of check findings."""
    table = Table(title="Findings", show_lines=True)
    table.add_column("File", style="cyan")
    table.add_column("Check", style="bold")
    table.add_column("Issue")
    table.add_column("Suggested Fix", style="green")
    for f in findings:
        table.add_row(f.file, f.check, f.actual, f.fix)
    console.print(table)


@check_app.callback(invoke_without_command=True)
def check_all(ctx: typer.Context) -> None:
    """Run all health checks in sequence.

    If no subcommand is specified, runs --skills, --integrations, and --context.
    """
    if ctx.invoked_subcommand is not None:
        # A subcommand was specified, let it handle execution
        return

    # No subcommand — run all checks
    project_root = Path.cwd()
    console.print("[bold]kiss check — running all health checks[/bold]\n")

    exit_codes = []
    all_findings: list[CheckFinding] = []

    console.print("[bold]Checking skills...[/bold]")
    code, findings = check_skills(project_root)
    exit_codes.append(code)
    all_findings.extend(findings)
    console.print()

    console.print("[bold]Checking integrations...[/bold]")
    code, findings = check_integrations(project_root)
    exit_codes.append(code)
    all_findings.extend(findings)
    console.print()

    console.print("[bold]Checking context...[/bold]")
    code, findings = check_context(project_root)
    exit_codes.append(code)
    all_findings.extend(findings)
    console.print()

    # Render findings table if any
    if all_findings:
        table = Table(title="Findings", show_lines=True)
        table.add_column("File", style="cyan")
        table.add_column("Check", style="bold")
        table.add_column("Issue")
        table.add_column("Suggested Fix", style="green")
        for f in all_findings:
            table.add_row(f.file, f.check, f.actual, f.fix)
        console.print(table)
        console.print()

    # Exit code is max of all subchecks
    max_exit_code = max(exit_codes) if exit_codes else 0

    if max_exit_code == 0:
        console.print(
            Panel(
                "[green bold]ALL CHECKS PASSED[/green bold]",
                style="green",
            )
        )
    else:
        console.print(
            Panel(
                "[red bold]FAILURES DETECTED[/red bold]",
                style="red",
            )
        )

    raise typer.Exit(max_exit_code)


@check_app.command()
def skills() -> None:
    """Validate all skill files in integration directories."""
    exit_code, findings = check_skills(Path.cwd())
    if findings:
        _render_findings(findings)
    raise typer.Exit(exit_code)


@check_app.command()
def integrations() -> None:
    """Check that integration config files exist."""
    exit_code, findings = check_integrations(Path.cwd())
    if findings:
        _render_findings(findings)
    raise typer.Exit(exit_code)


@check_app.command()
def context() -> None:
    """Validate .kiss/context.yml schema."""
    exit_code, findings = check_context(Path.cwd())
    if findings:
        _render_findings(findings)
    raise typer.Exit(exit_code)


# Register the check_app as a subcommand of the main app so users invoke
# `kiss check`, `kiss check skills`, `kiss check integrations`, `kiss check context`.
app.add_typer(check_app, name="check")
