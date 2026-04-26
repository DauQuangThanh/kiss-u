"""Tests for per-AI subagent rendering (WP-1 through WP-6)."""

from pathlib import Path

import pytest

SAMPLE_AGENT = """\
---
name: architect
description: Software architecture authoring aid.
tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch
model: inherit
color: purple
---

# Architect

You are an AI software architecture authoring aid.
"""


class TestCodexAgentDir:
    """US-1: Codex should use .codex/agents/."""

    def test_codex_agents_dest(self, tmp_path: Path) -> None:
        from kiss_cli.integrations.codex import CodexIntegration
        i = CodexIntegration()
        dest = i.custom_agents_dest(tmp_path)
        assert dest is not None
        assert dest == tmp_path / ".codex" / "agents"


class TestOpencodeTransform:
    """US-2: OpenCode injects mode: subagent."""

    def test_injects_mode_subagent(self) -> None:
        from kiss_cli.integrations.opencode import OpencodeIntegration
        i = OpencodeIntegration()
        result = i.transform_custom_agent_content(SAMPLE_AGENT)
        assert "mode: subagent" in result


class TestGeminiTransform:
    """US-3: Gemini injects kind: subagent."""

    def test_injects_kind_subagent(self) -> None:
        from kiss_cli.integrations.gemini import GeminiIntegration
        i = GeminiIntegration()
        result = i.transform_custom_agent_content(SAMPLE_AGENT)
        assert "kind: subagent" in result


class TestWindsurfTransform:
    """US-4: Windsurf uses workflows/ and strips frontmatter."""

    def test_agents_dest_uses_workflows(self, tmp_path: Path) -> None:
        from kiss_cli.integrations.windsurf import WindsurfIntegration
        i = WindsurfIntegration()
        dest = i.custom_agents_dest(tmp_path)
        assert dest is not None
        assert dest == tmp_path / ".windsurf" / "workflows"

    def test_strips_frontmatter(self) -> None:
        from kiss_cli.integrations.windsurf import WindsurfIntegration
        i = WindsurfIntegration()
        result = i.transform_custom_agent_content(SAMPLE_AGENT)
        assert "---" not in result
        assert "name: architect" not in result
        # Body should be preserved
        assert "# Architect" in result


class TestCodexTransform:
    """US-5: Codex adds developer_instructions."""

    def test_adds_developer_instructions(self) -> None:
        from kiss_cli.integrations.codex import CodexIntegration
        i = CodexIntegration()
        result = i.transform_custom_agent_content(SAMPLE_AGENT)
        assert "developer_instructions" in result


class TestCursorTransform:
    """US-6: Cursor strips color and tools."""

    def test_strips_color_and_tools(self) -> None:
        from kiss_cli.integrations.cursor_agent import CursorAgentIntegration
        i = CursorAgentIntegration()
        result = i.transform_custom_agent_content(SAMPLE_AGENT)
        assert "color:" not in result
        assert "tools:" not in result
        # name and description preserved
        assert "name: architect" in result
        assert "description:" in result


class TestClaudePreservesAll:
    """Claude keeps all fields (color, tools) — it's the source format."""

    def test_claude_preserves_color_and_tools(self) -> None:
        from kiss_cli.integrations.claude import ClaudeIntegration
        i = ClaudeIntegration()
        result = i.transform_custom_agent_content(SAMPLE_AGENT)
        # Claude is the source format — everything preserved
        assert "color:" in result
        assert "tools:" in result
