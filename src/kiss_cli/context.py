"""Context file management for kiss projects."""

import yaml
from pathlib import Path
from typing import Any


def _render_context_content(
    integrations: list[str],
    docs_dir: str = "docs",
    specs_dir: str = "docs/specs",
    plans_dir: str = "docs/plans",
    tasks_dir: str = "docs/tasks",
    templates_dir: str = "templates",
    scripts_dir: str = "scripts",
    output_lang: str = "English",
    interaction_lang: str = "English",
    output_format: str = "markdown",
    task_numbering: str = "sequential",
    confirm_before_write: bool = True,
    auto_update_context: bool = True,
) -> str:
    """Render the full annotated context.yml content string.

    Called by both ``create_context_file`` (first-time) and
    ``merge_context_file`` (re-render with existing user values) so that
    comments are always preserved regardless of how the file is updated.
    """
    integrations_yaml = "\n".join(f"  - {i}" for i in integrations)
    cbw = str(confirm_before_write).lower()
    auc = str(auto_update_context).lower()

    return f"""\
# kiss context file — project-level state for Spec-Driven Development (SDD).
# AI agents and kiss commands read this file to understand the project layout
# and track what is currently being worked on.
# Edit any value below to match your project's conventions.

# Version of this schema. Do not change unless you are migrating to a newer
# version of kiss that requires a different schema.
schema_version: "1.0"

# ---------------------------------------------------------------------------
# paths — where SDD artifacts live, relative to the project root.
# Change these if you keep docs, specs, or scripts in non-default locations.
# ---------------------------------------------------------------------------
paths:
  # Root documentation directory. General docs and top-level indexes go here.
  docs: {docs_dir}

  # Specification files (.md). Each feature should have its own spec here.
  specs: {specs_dir}

  # Plan files (.md). Detailed implementation plans derived from specs.
  plans: {plans_dir}

  # Task files (.md). Granular tasks broken down from plans.
  tasks: {tasks_dir}

  # Prompt / template files shipped alongside each installed skill
  # (each skill folder has its own ``templates/`` subdirectory). Paths
  # are resolved from the active skill's folder at runtime.
  templates: {templates_dir}

  # Helper scripts shipped alongside each installed skill (each skill
  # folder has its own ``scripts/bash/`` and ``scripts/powershell/``
  # subdirectories). Paths are resolved from the active skill's folder.
  scripts: {scripts_dir}

# ---------------------------------------------------------------------------
# current — the active "work item" for this session.
# kiss commands and AI agents use these values to resume context automatically.
# Set a field to null (or leave blank) when nothing is active.
# ---------------------------------------------------------------------------
current:
  # Human-readable name of the feature currently being developed.
  # Example: "user-authentication"
  feature: null

  # Path (relative to project root) of the active spec file.
  # Example: docs/specs/user-authentication.md
  spec: null

  # Path (relative to project root) of the active plan file.
  # Example: docs/plans/user-authentication.md
  plan: null

  # Path (relative to project root) of the active tasks list file.
  # Example: docs/tasks/user-authentication/tasks.md
  tasks: null

  # Path (relative to project root) of the active checklist file.
  # Example: docs/tasks/user-authentication/checklist.md
  checklist: null

  # Git branch currently being used for this feature.
  # Example: feature/user-authentication
  branch: null

# ---------------------------------------------------------------------------
# preferences — controls how kiss commands behave.
# ---------------------------------------------------------------------------
preferences:
  # Format used when kiss writes new documents.
  # Supported values: "markdown"
  output_format: {output_format}

  # How tasks are numbered inside a plan.
  # "sequential" — 1, 2, 3 …
  # "timestamp"  — tasks prefixed with a date/time stamp
  task_numbering: {task_numbering}

  # When true, kiss will ask for confirmation before writing any file.
  # Set to false for a fully automated / CI workflow.
  confirm_before_write: {cbw}

  # When true, kiss automatically updates the "current" section above
  # whenever you run commands that change the active spec, plan, or task.
  auto_update_context: {auc}

# ---------------------------------------------------------------------------
# language — natural-language preferences for what kiss writes and asks.
# Free-form strings (e.g. "English", "Spanish", "Vietnamese", "fr-CA").
# AI agents and skills should honour these settings: produce artefacts in
# `output` and conduct interactive Q&A in `interaction`. Defaults to
# English for both. Set them independently when the user reads / writes in
# different languages.
# ---------------------------------------------------------------------------
language:
  # Language used when kiss writes documents — specs, plans, tasks,
  # designs, ADRs, reviews, status reports, and any other artefact.
  output: {output_lang}

  # Language used when kiss asks questions, presents options, and
  # confirms decisions with the user.
  interaction: {interaction_lang}

# ---------------------------------------------------------------------------
# integrations — AI providers that were installed into this project.
# kiss uses this list to apply provider-specific prompts and settings.
# Add or remove entries to match the AI tools your team actually uses.
# Run `kiss install` to interactively manage integrations.
# ---------------------------------------------------------------------------
integrations:
{integrations_yaml}
"""


def create_context_file(
    project_path: Path,
    integrations: list[str] = None,
    docs_dir: str = "docs",
    specs_dir: str = "docs/specs",
    plans_dir: str = "docs/plans",
    tasks_dir: str = "docs/tasks",
    templates_dir: str = "templates",
    scripts_dir: str = "scripts",
) -> None:
    """Create .kiss/context.yml with the documented schema.

    Args:
        project_path: Root directory of the kiss project
        integrations: List of selected integration keys (defaults to ["claude"])
        docs_dir: Path to docs directory (relative to project root)
        specs_dir: Path to specs directory (relative to project root)
        plans_dir: Path to plans directory (relative to project root)
        tasks_dir: Path to tasks directory (relative to project root)
        templates_dir: Path to templates directory (relative to project root)
        scripts_dir: Path to scripts directory (relative to project root)
    """
    if integrations is None:
        integrations = ["claude"]

    content = _render_context_content(
        integrations=integrations,
        docs_dir=docs_dir,
        specs_dir=specs_dir,
        plans_dir=plans_dir,
        tasks_dir=tasks_dir,
        templates_dir=templates_dir,
        scripts_dir=scripts_dir,
    )

    context_file = project_path / ".kiss" / "context.yml"
    context_file.parent.mkdir(parents=True, exist_ok=True)
    context_file.write_text(content, encoding="utf-8")


def load_context_file(project_root: Path) -> dict[str, Any]:
    """Load and parse .kiss/context.yml.

    Args:
        project_root: Root directory of the kiss project

    Returns:
        Parsed context dictionary, or empty dict if file doesn't exist

    Raises:
        yaml.YAMLError: If the context file is malformed
    """
    context_file = project_root / ".kiss" / "context.yml"
    if not context_file.exists():
        return {}

    with open(context_file, "r", encoding="utf-8") as f:
        return yaml.safe_load(f) or {}


def _deep_merge(existing: dict, template: dict) -> dict:
    """Recursively merge *template* into *existing*; existing values win."""
    merged = dict(existing)
    for key, tval in template.items():
        if key not in merged:
            merged[key] = tval
        elif isinstance(merged[key], dict) and isinstance(tval, dict):
            merged[key] = _deep_merge(merged[key], tval)
        # else: existing scalar/list wins — do not overwrite
    return merged


def merge_context_file(
    project_root: Path,
    new_integrations: list[str] | None = None,
) -> None:
    """Merge template defaults into an existing context.yml.

    Existing user values are preserved; only new schema keys are added.
    The ``integrations`` list is union-merged (no duplicates).
    ``schema_version`` is always updated to the template value.

    Comments are preserved by re-rendering the fully-annotated template
    with the user's existing values substituted in, rather than round-
    tripping through ``yaml.dump`` which strips all comments.
    """
    existing = load_context_file(project_root)
    if not existing:
        create_context_file(project_root, integrations=new_integrations)
        return

    # Union-merge integrations list
    old_list = existing.get("integrations", [])
    new_list = new_integrations or []
    union = list(dict.fromkeys(old_list + new_list))  # preserves order, no dups

    paths = existing.get("paths", {}) or {}
    prefs = existing.get("preferences", {}) or {}
    lang  = existing.get("language", {}) or {}

    content = _render_context_content(
        integrations=union,
        docs_dir=paths.get("docs", "docs"),
        specs_dir=paths.get("specs", "docs/specs"),
        plans_dir=paths.get("plans", "docs/plans"),
        tasks_dir=paths.get("tasks", "docs/tasks"),
        templates_dir=paths.get("templates", "templates"),
        scripts_dir=paths.get("scripts", "scripts"),
        output_lang=lang.get("output", "English"),
        interaction_lang=lang.get("interaction", "English"),
        output_format=prefs.get("output_format", "markdown"),
        task_numbering=prefs.get("task_numbering", "sequential"),
        confirm_before_write=prefs.get("confirm_before_write", True),
        auto_update_context=prefs.get("auto_update_context", True),
    )

    context_file = project_root / ".kiss" / "context.yml"
    context_file.write_text(content, encoding="utf-8")


def _build_context_template(integrations: list[str]) -> dict[str, Any]:
    """Return the default context dict that create_context_file would write."""
    return {
        "schema_version": "1.0",
        "paths": {
            "docs": "docs",
            "specs": "docs/specs",
            "plans": "docs/plans",
            "tasks": "docs/tasks",
            "templates": "templates",
            "scripts": "scripts",
        },
        "current": {
            "feature": None,
            "spec": None,
            "plan": None,
            "tasks": None,
            "checklist": None,
            "branch": None,
        },
        "preferences": {
            "output_format": "markdown",
            "task_numbering": "sequential",
            "confirm_before_write": True,
            "auto_update_context": True,
        },
        "language": {
            "output": "English",
            "interaction": "English",
        },
        "integrations": integrations,
    }


def save_context_file(project_root: Path, data: dict[str, Any]) -> None:
    """Save context data to .kiss/context.yml.

    Args:
        project_root: Root directory of the kiss project
        data: Context dictionary to save
    """
    context_file = project_root / ".kiss" / "context.yml"
    context_file.parent.mkdir(parents=True, exist_ok=True)
    context_file.write_text(
        yaml.dump(data, default_flow_style=False, sort_keys=False, allow_unicode=True),
        encoding="utf-8",
    )
