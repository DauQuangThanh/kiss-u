"""opencode integration."""

from ..base import MarkdownIntegration, _inject_frontmatter_field, _strip_frontmatter_field


class OpencodeIntegration(MarkdownIntegration):
    key = "opencode"
    config = {
        "name": "opencode",
        "folder": ".opencode/",
        "skills_subdir": "skills",
        "install_url": "https://opencode.ai",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".opencode/skills",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".md",
    }
    context_file = "AGENTS.md"

    supports_argument_hints = True
    supports_handoffs = False
    supports_multi_context_files = False

    def transform_custom_agent_content(self, content: str) -> str:
        """OpenCode: strip color, inject mode: subagent."""
        content = _strip_frontmatter_field(content, "color")
        return _inject_frontmatter_field(content, "mode", "subagent")
