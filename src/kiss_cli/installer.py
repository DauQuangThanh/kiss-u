"""Installer utilities and shared infrastructure helpers for kiss projects."""

import os
import json
import json5
import shutil
import stat
import subprocess
import tempfile
import typer
from pathlib import Path
from typing import Any, Optional

# Import UI and config modules
from .ui import console
from .version import get_kiss_version


# Constants
CLAUDE_LOCAL_PATH = Path.home() / ".claude" / "local" / "claude"
CLAUDE_NPM_LOCAL_PATH = Path.home() / ".claude" / "local" / "node_modules" / ".bin" / "claude"
SCRIPT_TYPE_CHOICES = {"sh": "POSIX Shell (bash/zsh)", "ps": "PowerShell"}
INTEGRATION_JSON = ".kiss/integration.json"


def _build_agent_config() -> dict[str, dict[str, Any]]:
    """Derive AGENT_CONFIG from INTEGRATION_REGISTRY."""
    from .integrations import INTEGRATION_REGISTRY
    config: dict[str, dict[str, Any]] = {}
    for key, integration in INTEGRATION_REGISTRY.items():
        if integration.config:
            config[key] = dict(integration.config)
    return config


AGENT_CONFIG = _build_agent_config()


def _get_step_tracker_class():
    """Lazy load StepTracker to avoid circular imports."""
    try:
        from .tracker import StepTracker
        return StepTracker
    except ImportError:
        return None


def run_command(cmd: list[str], check_return: bool = True, capture: bool = False, shell: bool = False) -> Optional[str]:
    """Run a shell command and optionally capture output."""
    try:
        if capture:
            result = subprocess.run(cmd, check=check_return, capture_output=True, text=True, shell=shell)
            return result.stdout.strip()
        else:
            subprocess.run(cmd, check=check_return, shell=shell)
            return None
    except subprocess.CalledProcessError as e:
        if check_return:
            console.print(f"[red]Error running command:[/red] {' '.join(cmd)}")
            console.print(f"[red]Exit code:[/red] {e.returncode}")
            if hasattr(e, 'stderr') and e.stderr:
                console.print(f"[red]Error output:[/red] {e.stderr}")
            raise
        return None


def check_tool(tool: str, tracker = None) -> bool:
    """Check if a tool is installed. Optionally update tracker.

    Args:
        tool: Name of the tool to check
        tracker: Optional StepTracker to update with results

    Returns:
        True if tool is found, False otherwise
    """
    # Special handling for Claude CLI local installs
    # See: https://github.com/DauQuangThanh/kiss-u/issues/123
    # See: https://github.com/DauQuangThanh/kiss-u/issues/550
    # Claude Code can be installed in two local paths:
    #   1. ~/.claude/local/claude          (after `claude migrate-installer`)
    #   2. ~/.claude/local/node_modules/.bin/claude  (npm-local install, e.g. via nvm)
    # Neither path may be on the system PATH, so we check them explicitly.
    if tool == "claude":
        if CLAUDE_LOCAL_PATH.is_file() or CLAUDE_NPM_LOCAL_PATH.is_file():
            if tracker:
                tracker.complete(tool, "available")
            return True

    found = shutil.which(tool) is not None

    if tracker:
        if found:
            tracker.complete(tool, "available")
        else:
            tracker.error(tool, "not found")

    return found


def is_git_repo(path: Path = None) -> bool:
    """Check if the specified path is inside a git repository."""
    if path is None:
        path = Path.cwd()

    if not path.is_dir():
        return False

    try:
        subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            check=True,
            capture_output=True,
            cwd=path,
        )
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False


def init_git_repo(project_path: Path, quiet: bool = False) -> tuple[bool, Optional[str]]:
    """Initialize a git repository in the specified path."""
    try:
        original_cwd = Path.cwd()
        os.chdir(project_path)
        if not quiet:
            console.print("[cyan]Initializing git repository...[/cyan]")
        subprocess.run(["git", "init"], check=True, capture_output=True, text=True)
        subprocess.run(["git", "add", "."], check=True, capture_output=True, text=True)
        subprocess.run(["git", "commit", "-m", "Initial commit from kiss template"], check=True, capture_output=True, text=True)
        if not quiet:
            console.print("[green]✓[/green] Git repository initialized")
        return True, None
    except subprocess.CalledProcessError as e:
        error_msg = f"Command: {' '.join(e.cmd)}\nExit code: {e.returncode}"
        if e.stderr:
            error_msg += f"\nError: {e.stderr.strip()}"
        elif e.stdout:
            error_msg += f"\nOutput: {e.stdout.strip()}"
        if not quiet:
            console.print(f"[red]Error initializing git repository:[/red] {e}")
        return False, error_msg
    finally:
        os.chdir(original_cwd)


def handle_vscode_settings(sub_item, dest_file, rel_path, verbose=False, tracker=None) -> None:
    """Handle merging or copying of .vscode/settings.json files.

    Note: when merge produces changes, rewritten output is normalized JSON and
    existing JSONC comments/trailing commas are not preserved.
    """
    def log(message, color="green"):
        if verbose and not tracker:
            console.print(f"[{color}]{message}[/] {rel_path}")

    def atomic_write_json(target_file: Path, payload: dict[str, Any]) -> None:
        """Atomically write JSON while preserving existing mode bits when possible."""
        temp_path: Optional[Path] = None
        try:
            with tempfile.NamedTemporaryFile(
                mode='w',
                encoding='utf-8',
                dir=target_file.parent,
                prefix=f"{target_file.name}.",
                suffix=".tmp",
                delete=False,
            ) as f:
                temp_path = Path(f.name)
                json.dump(payload, f, indent=4)
                f.write('\n')

            if target_file.exists():
                try:
                    existing_stat = target_file.stat()
                    os.chmod(temp_path, stat.S_IMODE(existing_stat.st_mode))
                    if hasattr(os, "chown"):
                        try:
                            os.chown(temp_path, existing_stat.st_uid, existing_stat.st_gid)
                        except PermissionError:
                            # Best-effort owner/group preservation without requiring elevated privileges.
                            pass
                except OSError:
                    # Best-effort metadata preservation; data safety is prioritized.
                    pass

            os.replace(temp_path, target_file)
        except Exception:
            if temp_path and temp_path.exists():
                temp_path.unlink()
            raise

    try:
        with open(sub_item, 'r', encoding='utf-8') as f:
            # json5 natively supports comments and trailing commas (JSONC)
            new_settings = json5.load(f)

        if dest_file.exists():
            merged = merge_json_files(dest_file, new_settings, verbose=verbose and not tracker)
            if merged is not None:
                atomic_write_json(dest_file, merged)
                log("Merged:", "green")
                log("Note: comments/trailing commas are normalized when rewritten", "yellow")
            else:
                log("Skipped merge (preserved existing settings)", "yellow")
        else:
            shutil.copy2(sub_item, dest_file)
            log("Copied (no existing settings.json):", "blue")

    except Exception as e:
        log(f"Warning: Could not merge settings: {e}", "yellow")
        if not dest_file.exists():
            shutil.copy2(sub_item, dest_file)


def merge_json_files(existing_path: Path, new_content: Any, verbose: bool = False) -> Optional[dict[str, Any]]:
    """Merge new JSON content into existing JSON file.

    Performs a polite deep merge where:
    - New keys are added
    - Existing keys are preserved (not overwritten) unless both values are dictionaries
    - Nested dictionaries are merged recursively only when both sides are dictionaries
    - Lists and other values are preserved from base if they exist

    Args:
        existing_path: Path to existing JSON file
        new_content: New JSON content to merge in
        verbose: Whether to print merge details

    Returns:
        Merged JSON content as dict, or None if the existing file should be left untouched.
    """
    # Load existing content first to have a safe fallback
    existing_content = None
    exists = existing_path.exists()

    if exists:
        try:
            with open(existing_path, 'r', encoding='utf-8') as f:
                # Handle comments (JSONC) natively with json5
                # Note: json5 handles BOM automatically
                existing_content = json5.load(f)
        except FileNotFoundError:
            # Handle race condition where file is deleted after exists() check
            exists = False
        except Exception as e:
            if verbose:
                console.print(f"[yellow]Warning: Could not read or parse existing JSON in {existing_path.name} ({e}).[/yellow]")
            # Skip merge to preserve existing file if unparseable or inaccessible (e.g. PermissionError)
            return None

    # Validate template content
    if not isinstance(new_content, dict):
        if verbose:
            console.print(f"[yellow]Warning: Template content for {existing_path.name} is not a dictionary. Preserving existing settings.[/yellow]")
        return None

    if not exists:
        return new_content

    # If existing content parsed but is not a dict, skip merge to avoid data loss
    if not isinstance(existing_content, dict):
        if verbose:
            console.print(f"[yellow]Warning: Existing JSON in {existing_path.name} is not an object. Skipping merge to avoid data loss.[/yellow]")
        return None

    def deep_merge_polite(base: dict[str, Any], update: dict[str, Any]) -> dict[str, Any]:
        """Recursively merge update dict into base dict, preserving base values."""
        result = base.copy()
        for key, value in update.items():
            if key not in result:
                # Add new key
                result[key] = value
            elif isinstance(result[key], dict) and isinstance(value, dict):
                # Recursively merge nested dictionaries
                result[key] = deep_merge_polite(result[key], value)
            else:
                # Key already exists and values are not both dicts; preserve existing value.
                # This ensures user settings aren't overwritten by template defaults.
                pass
        return result

    merged = deep_merge_polite(existing_content, new_content)

    # Detect if anything actually changed. If not, return None so the caller
    # can skip rewriting the file (preserving user's comments/formatting).
    if merged == existing_content:
        return None

    if verbose:
        console.print(f"[cyan]Merged JSON file:[/cyan] {existing_path.name}")

    return merged


def _locate_core_pack() -> Path | None:
    """Return the filesystem path to the bundled core_pack directory, or None.

    Only present in wheel installs: hatchling's force-include copies
    templates/, scripts/ etc. into kiss_cli/core_pack/ at build time.

    Source-checkout and editable installs do NOT have this directory.
    Callers that need to work in both environments must check the repo-root
    trees (templates/, scripts/) as a fallback when this returns None.
    """
    # Wheel install: core_pack is a sibling directory of this file
    candidate = Path(__file__).parent / "core_pack"
    if candidate.is_dir():
        return candidate
    return None


def _locate_bundled_extension(extension_id: str) -> Path | None:
    """Return the path to a bundled extension, or None.

    Checks the wheel's core_pack first, then falls back to the
    source-checkout ``extensions/<id>/`` directory.
    """
    import re as _re
    if not _re.match(r'^[a-z0-9-]+$', extension_id):
        return None

    core = _locate_core_pack()
    if core is not None:
        candidate = core / "extensions" / extension_id
        if (candidate / "extension.yml").is_file():
            return candidate

    # Source-checkout / editable install: look relative to repo root
    repo_root = Path(__file__).parent.parent.parent
    candidate = repo_root / "extensions" / extension_id
    if (candidate / "extension.yml").is_file():
        return candidate

    return None


def _locate_bundled_workflow(workflow_id: str) -> Path | None:
    """Return the path to a bundled workflow directory, or None.

    Checks the wheel's core_pack first, then falls back to the
    source-checkout ``workflows/<id>/`` directory.
    """
    import re as _re
    if not _re.match(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?$', workflow_id):
        return None

    core = _locate_core_pack()
    if core is not None:
        candidate = core / "workflows" / workflow_id
        if (candidate / "workflow.yml").is_file():
            return candidate

    # Source-checkout / editable install: look relative to repo root
    repo_root = Path(__file__).parent.parent.parent
    candidate = repo_root / "workflows" / workflow_id
    if (candidate / "workflow.yml").is_file():
        return candidate

    return None


def _locate_bundled_preset(preset_id: str) -> Path | None:
    """Return the path to a bundled preset, or None.

    Checks the wheel's core_pack first, then falls back to the
    source-checkout ``presets/<id>/`` directory.
    """
    import re as _re
    if not _re.match(r'^[a-z0-9-]+$', preset_id):
        return None

    core = _locate_core_pack()
    if core is not None:
        candidate = core / "presets" / preset_id
        if (candidate / "preset.yml").is_file():
            return candidate

    # Source-checkout / editable install: look relative to repo root
    repo_root = Path(__file__).parent.parent.parent
    candidate = repo_root / "presets" / preset_id
    if (candidate / "preset.yml").is_file():
        return candidate

    return None


def _install_shared_infra(
    project_path: Path,
    tracker = None,
    force: bool = False,
) -> bool:
    """Initialise the ``.kiss/`` state directory.

    Scripts and templates are no longer installed to a shared
    ``.kiss/scripts/`` / ``.kiss/templates/`` location — each skill
    bundles its own copy during integration setup. This function
    simply creates the ``.kiss/`` directory so subsequent state files
    (``context.yml``, ``integration.json``, extension/preset installs)
    have a place to live.

    Returns ``True`` on success.
    """
    (project_path / ".kiss").mkdir(parents=True, exist_ok=True)
    return True


def _locate_custom_agents_source() -> Path | None:
    """Resolve the bundled ``subagents/`` directory.

    Checks ``core_pack/subagents/`` first (wheel install) then the
    top-level ``subagents/`` in the source checkout.
    """
    core = _locate_core_pack()
    if core is not None:
        candidate = core / "subagents"
        if candidate.is_dir():
            return candidate
    repo_root = Path(__file__).parent.parent.parent
    candidate = repo_root / "subagents"
    return candidate if candidate.is_dir() else None


def install_custom_agents(
    project_path: Path,
    integration_keys: list[str],
    *,
    force: bool = False,
) -> dict[str, int]:
    """Deploy bundled custom agents into each installed integration's agent dir.

    For every integration in *integration_keys*, copies every ``*.md``
    under ``subagents/`` into the integration's
    ``custom_agents_dest(project_path)`` directory. Each file is also
    recorded in the integration's ``kiss-<key>.manifest.json`` so
    teardown removes it cleanly (unless the user modified it).

    Integrations with ``config["agents_subdir"] = None`` (e.g. ``generic``)
    are skipped.

    Returns a mapping of integration key → number of files written.
    """
    from .integrations import get_integration
    from .integrations.manifest import IntegrationManifest

    src_root = _locate_custom_agents_source()
    if src_root is None:
        return {}

    agent_files = sorted(src_root.glob("*.md"))
    if not agent_files:
        return {}

    results: dict[str, int] = {}
    for key in integration_keys:
        integration = get_integration(key)
        if integration is None:
            continue
        dest = integration.custom_agents_dest(project_path)
        if dest is None:
            continue

        try:
            manifest = IntegrationManifest.load(key, project_path)
        except FileNotFoundError:
            manifest = IntegrationManifest(
                key, project_path, version=get_kiss_version()
            )

        dest.mkdir(parents=True, exist_ok=True)
        count = 0
        for src in agent_files:
            dst = dest / integration.custom_agent_filename(src.name)
            if dst.exists() and not force:
                continue
            content = src.read_text(encoding="utf-8")
            transformed = integration.transform_custom_agent_content(content)
            if transformed == content:
                shutil.copy2(src, dst)
            else:
                dst.write_text(transformed, encoding="utf-8")
            manifest.record_existing(
                dst.relative_to(project_path).as_posix()
            )
            count += 1
        manifest.save()
        results[key] = count

    return results


def ensure_executable_scripts(project_path: Path, tracker = None) -> None:
    """Ensure POSIX .sh scripts have execute bits (no-op on Windows).

    Scans ``.kiss/extensions/`` (for extension scripts) and every
    registered integration's config folder (where installed skills live
    with their bundled ``scripts/bash/…`` subdirectories).
    """
    if os.name == "nt":
        return  # Windows: skip silently
    from .integrations import INTEGRATION_REGISTRY

    scan_roots = [project_path / ".kiss" / "extensions"]
    for integration in INTEGRATION_REGISTRY.values():
        folder = (integration.config or {}).get("folder") if integration.config else None
        if folder:
            scan_roots.append(project_path / folder)
    failures: list[str] = []
    updated = 0
    for scripts_root in scan_roots:
        if not scripts_root.is_dir():
            continue
        for script in scripts_root.rglob("*.sh"):
            try:
                if script.is_symlink() or not script.is_file():
                    continue
                try:
                    with script.open("rb") as f:
                        if f.read(2) != b"#!":
                            continue
                except Exception:
                    continue
                st = script.stat()
                mode = st.st_mode
                if mode & 0o111:
                    continue
                new_mode = mode
                if mode & 0o400:
                    new_mode |= 0o100
                if mode & 0o040:
                    new_mode |= 0o010
                if mode & 0o004:
                    new_mode |= 0o001
                if not (new_mode & 0o100):
                    new_mode |= 0o100
                os.chmod(script, new_mode)
                updated += 1
            except Exception as e:
                failures.append(f"{script.relative_to(project_path)}: {e}")
    if tracker:
        detail = f"{updated} updated" + (f", {len(failures)} failed" if failures else "")
        tracker.add("chmod", "Set script permissions recursively")
        (tracker.error if failures else tracker.complete)("chmod", detail)
    else:
        if updated:
            console.print(f"[cyan]Updated execute permissions on {updated} script(s) recursively[/cyan]")
        if failures:
            console.print("[yellow]Some scripts could not be updated:[/yellow]")
            for f in failures:
                console.print(f"  - {f}")


def _get_skills_dir(project_path: Path, selected_ai: str) -> Path:
    """Resolve the agent-specific skills directory.

    Returns ``project_path / <agent_folder> / "skills"``, falling back
    to ``project_path / ".agents/skills"`` for unknown agents.
    """
    agent_config = AGENT_CONFIG.get(selected_ai, {})
    agent_folder = agent_config.get("folder", "")
    if agent_folder:
        return project_path / agent_folder.rstrip("/") / "skills"
    return project_path / ".agents" / "skills"


def _read_integration_json(project_root: Path) -> dict[str, Any]:
    """Load ``.kiss/integration.json``, migrating old format on read.

    Old format ``{"integration": "claude"}`` is transparently converted
    to ``{"integrations": ["claude"]}``.  Returns ``{}`` when missing.
    """
    path = project_root / INTEGRATION_JSON
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        console.print(f"[red]Error:[/red] {path} contains invalid JSON.")
        console.print(f"Please fix or delete {INTEGRATION_JSON} and retry.")
        console.print(f"[dim]Details:[/dim] {exc}")
        raise typer.Exit(1)
    except OSError as exc:
        console.print(f"[red]Error:[/red] Could not read {path}.")
        console.print(f"Please fix file permissions or delete {INTEGRATION_JSON} and retry.")
        console.print(f"[dim]Details:[/dim] {exc}")
        raise typer.Exit(1)
    if not isinstance(data, dict):
        console.print(f"[red]Error:[/red] {path} must contain a JSON object, got {type(data).__name__}.")
        console.print(f"Please fix or delete {INTEGRATION_JSON} and retry.")
        raise typer.Exit(1)
    # Migrate old single-key format to new list format on read.
    if "integration" in data and "integrations" not in data:
        old_key = data.pop("integration")
        data["integrations"] = [old_key] if old_key else []
    return data


def _write_integration_json(
    project_root: Path,
    integrations: list[str] | str,
) -> None:
    """Write ``.kiss/integration.json`` in the multi-integration format.

    Accepts a list of integration keys (new) or a single string (compat).
    """
    if isinstance(integrations, str):
        integrations = [integrations]
    dest = project_root / INTEGRATION_JSON
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps({
        "integrations": integrations,
        "version": get_kiss_version(),
    }, indent=2) + "\n", encoding="utf-8")


def _add_integration_to_json(project_root: Path, key: str) -> None:
    """Append *key* to the integrations list (no-op if already present)."""
    data = _read_integration_json(project_root)
    keys = data.get("integrations", [])
    if key not in keys:
        keys.append(key)
    _write_integration_json(project_root, keys)


def _remove_integration_from_json(project_root: Path, key: str) -> None:
    """Remove *key* from the integrations list.  File always persists."""
    data = _read_integration_json(project_root)
    keys = data.get("integrations", [])
    if key in keys:
        keys.remove(key)
    _write_integration_json(project_root, keys)


def _remove_integration_json(project_root: Path) -> None:
    """Remove ``.kiss/integration.json`` if it exists.

    .. deprecated:: Kept for backward compatibility with callers that
       haven't migrated to ``_remove_integration_from_json``. Will be
       removed once all callers are updated (WP-2/3/4/8).
    """
    path = project_root / INTEGRATION_JSON
    if path.exists():
        path.unlink()


def _normalize_script_type(script_type: str, source: str) -> str:
    """Normalize and validate a script type from CLI/config sources."""
    normalized = script_type.strip().lower()
    if normalized in SCRIPT_TYPE_CHOICES:
        return normalized
    console.print(
        f"[red]Error:[/red] Invalid script type {script_type!r} from {source}. "
        f"Expected one of: {', '.join(sorted(SCRIPT_TYPE_CHOICES.keys()))}."
    )
    raise typer.Exit(1)


def _resolve_script_type(project_root: Path, script_type: str | None) -> str:
    """Resolve the script type from the ``--script`` CLI flag, falling
    back to the current platform's default.

    Both ``bash/`` and ``powershell/`` script variants are installed into
    every project by ``kiss init``, so the choice of variant is made at
    runtime rather than persisted in ``init-options.json``.
    """
    if script_type:
        return _normalize_script_type(script_type, "--script")
    return "ps" if os.name == "nt" else "sh"
