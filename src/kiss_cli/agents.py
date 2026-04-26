"""
Agent Command Registrar for kiss

Shared infrastructure for registering commands with AI agents.
Used by both the extension system and the preset system to write
command files into agent-specific directories in the correct format.
"""

import os
from pathlib import Path
from typing import Dict, List, Any

import platform
import re
from copy import deepcopy
import yaml


def _build_agent_configs() -> dict[str, Any]:
    """Derive CommandRegistrar.AGENT_CONFIGS from INTEGRATION_REGISTRY."""
    from kiss_cli.integrations import INTEGRATION_REGISTRY

    configs: dict[str, dict[str, Any]] = {}
    for key, integration in INTEGRATION_REGISTRY.items():
        if integration.registrar_config:
            configs[key] = dict(integration.registrar_config)
    return configs


class CommandRegistrar:
    """Handles registration of commands with AI agents.

    Supports writing command files in Markdown or TOML format to the
    appropriate agent directory, with correct argument placeholders
    and companion files (e.g. Copilot .prompt.md).
    """

    # Derived from INTEGRATION_REGISTRY — single source of truth.
    # Populated lazily via _ensure_configs() on first use.
    AGENT_CONFIGS: dict[str, dict[str, Any]] = {}
    _configs_loaded: bool = False

    def __init__(self) -> None:
        self._ensure_configs()

    def __init_subclass__(cls, **kwargs: Any) -> None:
        super().__init_subclass__(**kwargs)
        cls._ensure_configs()

    @classmethod
    def _ensure_configs(cls) -> None:
        if not cls._configs_loaded:
            try:
                cls.AGENT_CONFIGS = _build_agent_configs()
                cls._configs_loaded = True
            except ImportError:
                pass  # Circular import during module init; retry on next access

    @staticmethod
    def parse_frontmatter(content: str) -> tuple[dict, str]:
        """Parse YAML frontmatter from Markdown content.

        Args:
            content: Markdown content with YAML frontmatter

        Returns:
            Tuple of (frontmatter_dict, body_content)
        """
        if not content.startswith("---"):
            return {}, content

        # Find second ---
        end_marker = content.find("---", 3)
        if end_marker == -1:
            return {}, content

        frontmatter_str = content[3:end_marker].strip()
        body = content[end_marker + 3 :].strip()

        try:
            frontmatter = yaml.safe_load(frontmatter_str) or {}
        except yaml.YAMLError:
            frontmatter = {}

        if not isinstance(frontmatter, dict):
            frontmatter = {}

        return frontmatter, body

    @staticmethod
    def render_frontmatter(fm: dict) -> str:
        """Render frontmatter dictionary as YAML.

        Args:
            fm: Frontmatter dictionary

        Returns:
            YAML-formatted frontmatter with delimiters
        """
        if not fm:
            return ""

        yaml_str = yaml.dump(
            fm, default_flow_style=False, sort_keys=False, allow_unicode=True
        )
        return f"---\n{yaml_str}---\n"

    @staticmethod
    def _get_integration_for_agent(agent_name: str) -> Any:
        """Get the integration object for the given agent name.

        Returns None if the integration cannot be found.
        """
        try:
            from kiss_cli.integrations import get_integration
            return get_integration(agent_name)
        except (ImportError, Exception):
            return None

    def _gate_argument_hints(self, agent_name: str, frontmatter: dict) -> dict:
        """Remove argument-hint from metadata if the agent doesn't support it.

        Args:
            agent_name: Name of the agent
            frontmatter: Frontmatter dictionary

        Returns:
            Modified frontmatter (or original if no changes needed)
        """
        integration = self._get_integration_for_agent(agent_name)
        if not integration or integration.supports_argument_hints:
            return frontmatter

        # Strip argument-hint from metadata
        fm = deepcopy(frontmatter)
        if "metadata" in fm and isinstance(fm["metadata"], dict):
            fm["metadata"].pop("argument-hint", None)
        return fm

    def _gate_handoffs(self, agent_name: str, body: str) -> str:
        """Remove ## Handoffs section from body if the agent doesn't support it.

        Args:
            agent_name: Name of the agent
            body: Body content

        Returns:
            Modified body (or original if no changes needed)
        """
        integration = self._get_integration_for_agent(agent_name)
        if not integration or integration.supports_handoffs:
            return body

        # Delete from ## Handoffs to next ## section or end of file
        HANDOFFS_RE = re.compile(r"(?ms)^##\s+Handoffs\b.*?(?=^## |\Z)")
        result = HANDOFFS_RE.sub("", body).rstrip()
        if result:
            result += "\n"
        return result

    def _gate_multi_context_files(self, agent_name: str, num_context_files: int) -> bool:
        """Check if agent supports writing multiple context files.

        Args:
            agent_name: Name of the agent
            num_context_files: Number of context files to be written

        Returns:
            True if the write should proceed, False if it should be skipped
        """
        if num_context_files <= 1:
            return True

        integration = self._get_integration_for_agent(agent_name)
        if integration and integration.supports_multi_context_files:
            return True

        # Multiple context files not supported; log a warning if possible
        try:
            from typer import secho
            secho(
                f"⚠ {agent_name} does not support multiple context files; "
                f"writing only the first one",
                fg="yellow"
            )
        except (ImportError, Exception):
            pass  # Silently skip warning if typer not available
        return False

    def _adjust_script_paths(self, frontmatter: dict) -> dict:
        """Normalize script paths in frontmatter.

        Strips legacy ``../../`` repo-relative prefixes so references end
        up relative to the installed skill folder (where scripts and
        templates now live alongside the command file). No-op for paths
        that already use the skill-relative form.

        Args:
            frontmatter: Frontmatter dictionary

        Returns:
            Modified frontmatter with normalized project paths
        """
        frontmatter = deepcopy(frontmatter)

        scripts = frontmatter.get("scripts")
        if isinstance(scripts, dict):
            for key, script_path in scripts.items():
                if isinstance(script_path, str):
                    scripts[key] = self.rewrite_project_relative_paths(script_path)
        return frontmatter

    @staticmethod
    def rewrite_project_relative_paths(text: str) -> str:
        """Rewrite legacy repo-relative paths.

        Scripts and templates now ship inside each skill's own folder
        (``<skill>/scripts/…``, ``<skill>/templates/…``). Source template
        files already use those short paths directly, so this function's
        only remaining job is to flatten any stray ``../../`` prefixes
        that may appear in user-authored content.
        """
        if not isinstance(text, str) or not text:
            return text

        for old, new in (
            ("../../scripts/", "scripts/"),
            ("../../templates/", "templates/"),
        ):
            text = text.replace(old, new)

        return text

    def render_markdown_command(
        self, frontmatter: dict, body: str, source_id: str, context_note: str = None
    ) -> str:
        """Render command in Markdown format.

        Args:
            frontmatter: Command frontmatter
            body: Command body content
            source_id: Source identifier (extension or preset ID)
            context_note: Custom context comment (default: <!-- Source: {source_id} -->)

        Returns:
            Formatted Markdown command file content
        """
        if context_note is None:
            context_note = f"\n<!-- Source: {source_id} -->\n"
        return self.render_frontmatter(frontmatter) + "\n" + context_note + body

    def render_toml_command(self, frontmatter: dict, body: str, source_id: str) -> str:
        """Render command in TOML format.

        Args:
            frontmatter: Command frontmatter
            body: Command body content
            source_id: Source identifier (extension or preset ID)

        Returns:
            Formatted TOML command file content
        """
        toml_lines = []

        if "description" in frontmatter:
            toml_lines.append(
                f"description = {self._render_basic_toml_string(frontmatter['description'])}"
            )
            toml_lines.append("")

        toml_lines.append(f"# Source: {source_id}")
        toml_lines.append("")

        # Keep TOML output valid even when body contains triple-quote delimiters.
        # Prefer multiline forms, then fall back to escaped basic string.
        if '"""' not in body:
            toml_lines.append('prompt = """')
            toml_lines.append(body)
            toml_lines.append('"""')
        elif "'''" not in body:
            toml_lines.append("prompt = '''")
            toml_lines.append(body)
            toml_lines.append("'''")
        else:
            toml_lines.append(f"prompt = {self._render_basic_toml_string(body)}")

        return "\n".join(toml_lines)

    @staticmethod
    def _render_basic_toml_string(value: str) -> str:
        """Render *value* as a TOML basic string literal."""
        escaped = (
            value.replace("\\", "\\\\")
            .replace('"', '\\"')
            .replace("\n", "\\n")
            .replace("\r", "\\r")
            .replace("\t", "\\t")
        )
        return f'"{escaped}"'

    def render_skill_command(
        self,
        agent_name: str,
        skill_name: str,
        frontmatter: dict,
        body: str,
        source_id: str,
        source_file: str,
        project_root: Path,
    ) -> str:
        """Render a command override as a SKILL.md file.

        SKILL-target agents should receive the same skills-oriented
        frontmatter shape used elsewhere in the project instead of the
        original command frontmatter.

        Technical debt note:
        Spec-kit currently has multiple SKILL.md generators (template packaging,
        init-time conversion, and extension/preset overrides). Keep the skill
        frontmatter keys aligned (name/description/compatibility/metadata, with
        metadata.author and metadata.source subkeys) to avoid drift across agents.
        """
        if not isinstance(frontmatter, dict):
            frontmatter = {}

        agent_config = self.AGENT_CONFIGS.get(agent_name, {})
        if agent_config.get("extension") == "/SKILL.md":
            body = self.resolve_skill_placeholders(
                agent_name, frontmatter, body, project_root
            )

        description = frontmatter.get(
            "description", f"Spec-kit workflow command: {skill_name}"
        )
        skill_frontmatter = self.build_skill_frontmatter(
            agent_name,
            skill_name,
            description,
            f"{source_id}:{source_file}",
        )
        return self.render_frontmatter(skill_frontmatter) + "\n" + body

    @staticmethod
    def build_skill_frontmatter(
        agent_name: str,
        skill_name: str,
        description: str,
        source: str,
    ) -> dict:
        """Build consistent SKILL.md frontmatter across all skill generators."""
        skill_frontmatter = {
            "name": skill_name,
            "description": description,
            "compatibility": "Requires kiss project structure with .kiss/ directory",
            "metadata": {
                "author": "github-kiss",
                "source": source,
            },
        }
        return skill_frontmatter

    @staticmethod
    def resolve_skill_placeholders(
        agent_name: str, frontmatter: dict, body: str, project_root: Path
    ) -> str:
        """Resolve script placeholders for skills-backed agents."""
        try:
            from .config import load_init_options
        except ImportError:
            return body

        if not isinstance(frontmatter, dict):
            frontmatter = {}

        scripts = frontmatter.get("scripts", {}) or {}
        if not isinstance(scripts, dict):
            scripts = {}

        init_opts = load_init_options(project_root)
        if not isinstance(init_opts, dict):
            init_opts = {}

        script_variant = init_opts.get("script")
        if script_variant not in {"sh", "ps"}:
            fallback_order = []
            default_variant = (
                "ps" if platform.system().lower().startswith("win") else "sh"
            )
            secondary_variant = "sh" if default_variant == "ps" else "ps"

            if default_variant in scripts:
                fallback_order.append(default_variant)
            if secondary_variant in scripts:
                fallback_order.append(secondary_variant)

            for key in scripts:
                if key not in fallback_order:
                    fallback_order.append(key)

            script_variant = fallback_order[0] if fallback_order else None

        script_command = scripts.get(script_variant) if script_variant else None
        if script_command:
            script_command = script_command.replace("{ARGS}", "$ARGUMENTS")
            body = body.replace("{SCRIPT}", script_command)

        body = body.replace("{ARGS}", "$ARGUMENTS").replace("__AGENT__", agent_name)

        # Resolve __CONTEXT_FILE__ from init-options
        context_file = init_opts.get("context_file") or ""
        body = body.replace("__CONTEXT_FILE__", context_file)

        return CommandRegistrar.rewrite_project_relative_paths(body)

    def _convert_argument_placeholder(
        self, content: str, from_placeholder: str, to_placeholder: str
    ) -> str:
        """Convert argument placeholder format.

        Args:
            content: Command content
            from_placeholder: Source placeholder (e.g., "$ARGUMENTS")
            to_placeholder: Target placeholder (e.g., "{{args}}")

        Returns:
            Content with converted placeholders
        """
        return content.replace(from_placeholder, to_placeholder)

    @staticmethod
    def _compute_output_name(
        agent_name: str, cmd_name: str, agent_config: Dict[str, Any]
    ) -> str:
        """Compute the on-disk command or skill name for an agent."""
        if agent_config["extension"] != "/SKILL.md":
            return cmd_name

        short_name = cmd_name
        if short_name.startswith("kiss."):
            short_name = short_name[len("kiss.") :]
        short_name = short_name.replace(".", "-")

        return f"kiss-{short_name}"

    @staticmethod
    def _ensure_inside(candidate: Path, base: Path) -> None:
        """Validate that a write target stays within the expected base directory.

        Uses lexical normalization so traversal via ``..`` or absolute paths is
        rejected while intentionally symlinked sub-directories remain
        supported.

        Args:
            candidate: Path that will be written.
            base: Directory the write must remain within.

        Raises:
            ValueError: If the normalized candidate path escapes ``base``.
        """
        normalized = Path(os.path.normpath(candidate))
        base_normalized = Path(os.path.normpath(base))
        if not normalized.is_relative_to(base_normalized):
            raise ValueError(
                f"Output path {candidate!r} escapes directory {base!r}"
            )

    def register_commands(
        self,
        agent_name: str,
        commands: List[Dict[str, Any]],
        source_id: str,
        source_dir: Path,
        project_root: Path,
        context_note: str = None,
    ) -> List[str]:
        """Register commands for a specific agent.

        Args:
            agent_name: Agent name (claude, gemini, copilot, etc.)
            commands: List of command info dicts with 'name', 'file', and optional 'aliases'
            source_id: Identifier of the source (extension or preset ID)
            source_dir: Directory containing command source files
            project_root: Path to project root
            context_note: Custom context comment for markdown output

        Returns:
            List of registered command names

        Raises:
            ValueError: If agent is not supported
        """
        self._ensure_configs()
        if agent_name not in self.AGENT_CONFIGS:
            raise ValueError(f"Unsupported agent: {agent_name}")

        agent_config = self.AGENT_CONFIGS[agent_name]
        commands_dir = project_root / agent_config["dir"]
        commands_dir.mkdir(parents=True, exist_ok=True)

        registered = []

        for cmd_info in commands:
            cmd_name = cmd_info["name"]
            cmd_file = cmd_info["file"]

            source_file = source_dir / cmd_file
            if not source_file.exists():
                continue

            content = source_file.read_text(encoding="utf-8")
            frontmatter, body = self.parse_frontmatter(content)

            if frontmatter.get("strategy") == "wrap":
                from .presets import _substitute_core_template
                body, core_frontmatter = _substitute_core_template(body, cmd_name, project_root, self)
                frontmatter = dict(frontmatter)
                for key in ("scripts", "agent_scripts"):
                    if key not in frontmatter and key in core_frontmatter:
                        frontmatter[key] = core_frontmatter[key]
                frontmatter.pop("strategy", None)

            frontmatter = self._adjust_script_paths(frontmatter)

            for key in agent_config.get("strip_frontmatter_keys", []):
                frontmatter.pop(key, None)

            if agent_config.get("inject_name") and not frontmatter.get("name"):
                frontmatter["name"] = cmd_name

            # O2: Gate capability flags
            frontmatter = self._gate_argument_hints(agent_name, frontmatter)
            body = self._gate_handoffs(agent_name, body)

            body = self._convert_argument_placeholder(
                body, "$ARGUMENTS", agent_config["args"]
            )

            output_name = self._compute_output_name(agent_name, cmd_name, agent_config)

            if agent_config["extension"] == "/SKILL.md":
                output = self.render_skill_command(
                    agent_name,
                    output_name,
                    frontmatter,
                    body,
                    source_id,
                    cmd_file,
                    project_root,
                )
            elif agent_config["format"] == "markdown":
                body = self.resolve_skill_placeholders(agent_name, frontmatter, body, project_root)
                body = self._convert_argument_placeholder(body, "$ARGUMENTS", agent_config["args"])
                output = self.render_markdown_command(frontmatter, body, source_id, context_note)
            elif agent_config["format"] == "toml":
                body = self.resolve_skill_placeholders(agent_name, frontmatter, body, project_root)
                body = self._convert_argument_placeholder(body, "$ARGUMENTS", agent_config["args"])
                output = self.render_toml_command(frontmatter, body, source_id)
            else:
                raise ValueError(f"Unsupported format: {agent_config['format']}")

            dest_file = commands_dir / f"{output_name}{agent_config['extension']}"
            self._ensure_inside(dest_file, commands_dir)
            dest_file.parent.mkdir(parents=True, exist_ok=True)
            dest_file.write_text(output, encoding="utf-8")

            registered.append(cmd_name)

            for alias in cmd_info.get("aliases", []):
                alias_output_name = self._compute_output_name(
                    agent_name, alias, agent_config
                )

                if agent_config.get("inject_name"):
                    alias_frontmatter = deepcopy(frontmatter)
                    alias_frontmatter["name"] = alias

                    if agent_config["extension"] == "/SKILL.md":
                        alias_output = self.render_skill_command(
                            agent_name,
                            alias_output_name,
                            alias_frontmatter,
                            body,
                            source_id,
                            cmd_file,
                            project_root,
                        )
                    elif agent_config["format"] == "markdown":
                        alias_output = self.render_markdown_command(
                            alias_frontmatter, body, source_id, context_note
                        )
                    elif agent_config["format"] == "toml":
                        alias_output = self.render_toml_command(
                            alias_frontmatter, body, source_id
                        )
                    else:
                        raise ValueError(
                            f"Unsupported format: {agent_config['format']}"
                        )
                else:
                    # For other agents, reuse the primary output
                    alias_output = output
                    if agent_config["extension"] == "/SKILL.md":
                        alias_output = self.render_skill_command(
                            agent_name,
                            alias_output_name,
                            frontmatter,
                            body,
                            source_id,
                            cmd_file,
                            project_root,
                        )

                alias_file = (
                    commands_dir / f"{alias_output_name}{agent_config['extension']}"
                )
                self._ensure_inside(alias_file, commands_dir)
                alias_file.parent.mkdir(parents=True, exist_ok=True)
                alias_file.write_text(alias_output, encoding="utf-8")
                registered.append(alias)

        return registered

    def register_commands_for_all_agents(
        self,
        commands: List[Dict[str, Any]],
        source_id: str,
        source_dir: Path,
        project_root: Path,
        context_note: str = None,
    ) -> Dict[str, List[str]]:
        """Register commands for all detected agents in the project.

        Args:
            commands: List of command info dicts
            source_id: Identifier of the source (extension or preset ID)
            source_dir: Directory containing command source files
            project_root: Path to project root
            context_note: Custom context comment for markdown output

        Returns:
            Dictionary mapping agent names to list of registered commands
        """
        results = {}

        self._ensure_configs()
        for agent_name, agent_config in self.AGENT_CONFIGS.items():
            agent_dir = project_root / agent_config["dir"]

            if agent_dir.exists():
                try:
                    registered = self.register_commands(
                        agent_name,
                        commands,
                        source_id,
                        source_dir,
                        project_root,
                        context_note=context_note,
                    )
                    if registered:
                        results[agent_name] = registered
                except ValueError:
                    continue

        return results

    def unregister_commands(
        self, registered_commands: Dict[str, List[str]], project_root: Path
    ) -> None:
        """Remove previously registered command files from agent directories.

        Args:
            registered_commands: Dict mapping agent names to command name lists
            project_root: Path to project root
        """
        self._ensure_configs()
        for agent_name, cmd_names in registered_commands.items():
            if agent_name not in self.AGENT_CONFIGS:
                continue

            agent_config = self.AGENT_CONFIGS[agent_name]
            commands_dir = project_root / agent_config["dir"]

            for cmd_name in cmd_names:
                output_name = self._compute_output_name(
                    agent_name, cmd_name, agent_config
                )
                cmd_file = commands_dir / f"{output_name}{agent_config['extension']}"
                if cmd_file.exists():
                    cmd_file.unlink()
                    # For SKILL.md agents each command lives in its own subdirectory
                    # (e.g. .agents/skills/kiss-ext-cmd/SKILL.md). Remove the
                    # parent dir when it becomes empty to avoid orphaned directories.
                    parent = cmd_file.parent
                    if parent != commands_dir and parent.exists():
                        try:
                            parent.rmdir()  # no-op if dir still has other files
                        except OSError:
                            pass


# Populate AGENT_CONFIGS after class definition.
# Catches ImportError from circular imports during module loading;
# _configs_loaded stays False so the next explicit access retries.
try:
    CommandRegistrar._ensure_configs()
except ImportError:
    pass
