"""Copilot integration — GitHub Copilot in VS Code.

Installs agent skills into ``.github/skills/`` using the
``kiss-<name>/SKILL.md`` layout (the same shape Claude uses), and
deploys custom agents into ``.github/agents/`` with the ``.agent.md``
filename convention the GitHub Copilot IDE expects.

CLI dispatch is not supported — the IDE handles invocation.
"""

from __future__ import annotations

import re

from ..base import IntegrationOption, SkillsIntegration


_FRONTMATTER_RE = re.compile(r"\A(---\r?\n)(.*?)(\r?\n---\r?\n)", re.DOTALL)
_TOOLS_LINE_RE = re.compile(r"(?m)^([ \t]*)tools:[ \t]*(.+?)[ \t]*$")
_COLOR_LINE_RE = re.compile(r"(?m)^[ \t]*color:[ \t]*[^\r\n]*\r?\n?")


class CopilotIntegration(SkillsIntegration):
    """Integration for GitHub Copilot in the VS Code IDE."""

    key = "copilot"
    config = {
        "name": "GitHub Copilot",
        "folder": ".github/",
        "skills_subdir": "skills",
        "install_url": None,
        "requires_cli": False,
    }
    registrar_config = {
        "dir": ".github/skills",
        "format": "markdown",
        "args": "$ARGUMENTS",
        "extension": "/SKILL.md",
    }
    context_file = "AGENTS.md"

    supports_argument_hints = False
    supports_handoffs = False
    supports_multi_context_files = False

    @classmethod
    def options(cls) -> list[IntegrationOption]:
        return [
            IntegrationOption(
                "--skills",
                is_flag=True,
                default=True,
                help="Install as agent skills (default for Copilot)",
            ),
        ]

    def custom_agent_filename(self, src_name: str) -> str:
        """Copilot custom agents use the ``.agent.md`` extension."""
        if src_name.endswith(".md") and not src_name.endswith(".agent.md"):
            return src_name[: -len(".md")] + ".agent.md"
        return src_name

    def transform_custom_agent_content(self, content: str) -> str:
        """Rewrite a custom-agent file's frontmatter for Copilot.

        - ``tools: A, B, C`` → ``tools: [a, b, c]`` (always a YAML inline
          array, every entry lowercased) so Copilot's allowlist matches
          its lowercase tool identifiers.
        - The ``color:`` field is dropped — Copilot has no UI for it.

        Frontmatter outside these two keys, and the body of the file, are
        preserved verbatim.
        """
        match = _FRONTMATTER_RE.match(content)
        if not match:
            return content
        opening, frontmatter, closing = match.groups()
        body = content[match.end():]

        frontmatter = _COLOR_LINE_RE.sub("", frontmatter)

        def _rewrite_tools(m: re.Match[str]) -> str:
            indent = m.group(1)
            raw = m.group(2).strip()
            if raw.startswith("[") and raw.endswith("]"):
                raw = raw[1:-1]
            items = [t.strip() for t in raw.split(",") if t.strip()]
            rendered = ", ".join(t.lower() for t in items)
            return f"{indent}tools: [{rendered}]"

        frontmatter = _TOOLS_LINE_RE.sub(_rewrite_tools, frontmatter, count=1)

        return f"{opening}{frontmatter}{closing}{body}"

    def build_exec_args(
        self,
        prompt: str,
        *,
        model: str | None = None,
        output_json: bool = True,
    ) -> list[str] | None:
        # IDE-only — no CLI dispatch.
        return None

    def build_command_invocation(self, command_name: str, args: str = "") -> str:
        """Copilot IDE invokes skills directly; just return the args as prompt."""
        return args or ""
