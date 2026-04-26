"""Gemini CLI integration."""

from ..base import TomlIntegration, _inject_frontmatter_field, _strip_frontmatter_field


class GeminiIntegration(TomlIntegration):
    key = "gemini"
    config = {
        "name": "Gemini CLI",
        "folder": ".gemini/",
        "skills_subdir": "commands",
        "install_url": "https://github.com/google-gemini/gemini-cli",
        "requires_cli": True,
    }
    registrar_config = {
        "dir": ".gemini/commands",
        "format": "toml",
        "args": "{{args}}",
        "extension": ".toml",
    }
    context_file = "GEMINI.md"

    supports_argument_hints = False
    supports_handoffs = False
    supports_multi_context_files = False

    def transform_custom_agent_content(self, content: str) -> str:
        """Gemini: strip color, inject kind: subagent."""
        content = _strip_frontmatter_field(content, "color")
        return _inject_frontmatter_field(content, "kind", "subagent")
