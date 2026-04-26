"""Tests for INTEGRATION_REGISTRY — mechanics, completeness, and registrar alignment."""

import pytest

from kiss_cli.integrations import (
    INTEGRATION_REGISTRY,
    _register,
    get_integration,
)
from kiss_cli.integrations.base import MarkdownIntegration
from .conftest import StubIntegration


# The seven supported integration keys (per docs/AI-urls.md).
ALL_INTEGRATION_KEYS = [
    "claude", "copilot", "cursor-agent",
    "opencode", "windsurf", "gemini", "codex",
]


class TestRegistry:
    def test_registry_is_dict(self):
        assert isinstance(INTEGRATION_REGISTRY, dict)

    def test_register_and_get(self):
        stub = StubIntegration()
        _register(stub)
        try:
            assert get_integration("stub") is stub
        finally:
            INTEGRATION_REGISTRY.pop("stub", None)

    def test_get_missing_returns_none(self):
        assert get_integration("nonexistent-xyz") is None

    def test_register_empty_key_raises(self):
        class EmptyKey(MarkdownIntegration):
            key = ""
        with pytest.raises(ValueError, match="empty key"):
            _register(EmptyKey())

    def test_register_duplicate_raises(self):
        stub = StubIntegration()
        _register(stub)
        try:
            with pytest.raises(KeyError, match="already registered"):
                _register(StubIntegration())
        finally:
            INTEGRATION_REGISTRY.pop("stub", None)


class TestRegistryCompleteness:
    """Every expected integration must be registered."""

    @pytest.mark.parametrize("key", ALL_INTEGRATION_KEYS)
    def test_key_registered(self, key):
        assert key in INTEGRATION_REGISTRY, f"{key} missing from registry"


class TestRegistrarKeyAlignment:
    """Every integration key must have a matching AGENT_CONFIGS entry.

    All seven supported integrations must have a matching entry.
    """

    @pytest.mark.parametrize(
        "key",
        ALL_INTEGRATION_KEYS,
    )
    def test_integration_key_in_registrar(self, key):
        from kiss_cli.agents import CommandRegistrar
        assert key in CommandRegistrar.AGENT_CONFIGS, (
            f"Integration '{key}' is registered but has no AGENT_CONFIGS entry"
        )

    def test_no_stale_cursor_shorthand(self):
        """The old 'cursor' shorthand must not appear in AGENT_CONFIGS."""
        from kiss_cli.agents import CommandRegistrar
        assert "cursor" not in CommandRegistrar.AGENT_CONFIGS
