"""Codex CLI integration — skills-based agent.

Codex uses the ``.codex/skills/kiss-<name>/SKILL.md`` layout.
Subagents install to ``.codex/agents/``.
"""

from __future__ import annotations

from ..base import IntegrationOption, SkillsIntegration, _inject_frontmatter_field, _strip_frontmatter_field


class CodexIntegration(SkillsIntegration):
    """Integration for OpenAI Codex CLI."""

    key = "codex"
    config = {
        "name": "Codex CLI",
        "folder": ".codex/",
        "skills_subdir": "skills",
        "install_url": "https://github.com/openai/codex",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".codex/skills",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": "/SKILL.md",
    }
    context_file = "AGENTS.md"

    def build_exec_args(
        self,
        prompt: str,
        *,
        model: str | None = None,
        output_json: bool = True,
    ) -> list[str] | None:
        # Codex uses ``codex exec "prompt"`` for non-interactive mode.
        args: list[str] = ["codex", "exec", prompt]
        if model:
            args.extend(["--model", model])
        if output_json:
            args.append("--json")
        return args

    supports_argument_hints = False
    supports_handoffs = True
    supports_multi_context_files = False

    def transform_custom_agent_content(self, content: str) -> str:
        """Codex: strip color, inject developer_instructions from body."""
        content = _strip_frontmatter_field(content, "color")
        content = _inject_frontmatter_field(content, "developer_instructions", '"See body below"')
        return content

    @classmethod
    def options(cls) -> list[IntegrationOption]:
        return [
            IntegrationOption(
                "--skills",
                is_flag=True,
                default=True,
                help="Install as agent skills (default for Codex)",
            ),
        ]
