"""Cursor IDE integration.

Cursor Agent uses the ``.cursor/skills/kiss-<name>/SKILL.md`` layout.
"""

from __future__ import annotations

from ..base import IntegrationOption, SkillsIntegration, _strip_frontmatter_field


class CursorAgentIntegration(SkillsIntegration):
    key = "cursor-agent"
    config = {
        "name": "Cursor",
        "folder": ".cursor/",
        "skills_subdir": "skills",
        "install_url": None,
        "requires_cli": False,
    }
    registrar_config = {
        "dir": ".cursor/skills",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": "/SKILL.md",
    }

    context_file = ".cursor/rules/kiss-rules.mdc"

    supports_argument_hints = True
    supports_handoffs = True
    supports_multi_context_files = False

    def transform_custom_agent_content(self, content: str) -> str:
        """Cursor: strip color and tools (not supported by Cursor agents)."""
        content = _strip_frontmatter_field(content, "color")
        return _strip_frontmatter_field(content, "tools")

    @classmethod
    def options(cls) -> list[IntegrationOption]:
        return [
            IntegrationOption(
                "--skills",
                is_flag=True,
                default=True,
                help="Install as agent skills (recommended for Cursor)",
            ),
        ]
