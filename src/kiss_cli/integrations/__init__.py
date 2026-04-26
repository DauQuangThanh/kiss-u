"""Integration registry for AI coding assistants.

Each integration is a self-contained subpackage that handles setup/teardown
for a specific AI assistant (Claude, Copilot, Gemini, etc.).
"""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from .base import IntegrationBase

# Maps integration key → IntegrationBase instance.
# Populated by later stages as integrations are migrated.
INTEGRATION_REGISTRY: dict[str, IntegrationBase] = {}


def _register(integration: IntegrationBase) -> None:
    """Register an integration instance in the global registry.

    Raises ``ValueError`` for falsy keys and ``KeyError`` for duplicates.
    """
    key = integration.key
    if not key:
        raise ValueError("Cannot register integration with an empty key.")
    if key in INTEGRATION_REGISTRY:
        raise KeyError(f"Integration with key {key!r} is already registered.")
    INTEGRATION_REGISTRY[key] = integration


def get_integration(key: str) -> IntegrationBase | None:
    """Return the integration for *key*, or ``None`` if not registered."""
    return INTEGRATION_REGISTRY.get(key)


# -- Register built-in integrations --------------------------------------


def _register_builtins() -> None:
    """Register the seven supported AI integrations.

    Supported AIs per ``docs/AI-urls.md`` and ADR-018:
    Claude Code, GitHub Copilot, Cursor Agent, OpenCode,
    Windsurf, Gemini CLI, Codex.
    """
    from .claude import ClaudeIntegration
    from .codex import CodexIntegration
    from .copilot import CopilotIntegration
    from .cursor_agent import CursorAgentIntegration
    from .gemini import GeminiIntegration
    from .opencode import OpencodeIntegration
    from .windsurf import WindsurfIntegration

    _register(ClaudeIntegration())
    _register(CopilotIntegration())
    _register(OpencodeIntegration())
    _register(CursorAgentIntegration())
    _register(CodexIntegration())
    _register(GeminiIntegration())
    _register(WindsurfIntegration())


_register_builtins()
