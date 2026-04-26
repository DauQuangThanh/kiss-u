"""Windsurf IDE integration."""

from ..base import MarkdownIntegration, _strip_frontmatter


class WindsurfIntegration(MarkdownIntegration):
    # Capability matrix (O2) — explicit for every subclass, no implicit inheritance.
    supports_argument_hints = True
    supports_handoffs = False
    supports_multi_context_files = False

    key = "windsurf"
    config = {
        "name": "Windsurf",
        "folder": ".windsurf/",
        "skills_subdir": "workflows",
        "agents_subdir": "workflows",
        "install_url": None,
        "requires_cli": False,
    }
    registrar_config = {
        "dir": ".windsurf/workflows",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": ".md",
    }
    context_file = ".windsurf/rules/kiss-rules.md"

    def transform_custom_agent_content(self, content: str) -> str:
        """Windsurf: strip frontmatter entirely (workflows are plain Markdown)."""
        return _strip_frontmatter(content)
