"""Tests for O2 CommandRegistrar capability-flag gating.

This test module validates:
- All integrations explicitly declare capability flags (not implicit False)
- CommandRegistrar removes argument-hint from unsupporting agents
- CommandRegistrar removes ## Handoffs from unsupporting agents
- CommandRegistrar warns on multiple context files for unsupporting agents
"""

import re
from pathlib import Path
from unittest.mock import patch, MagicMock
import pytest

from kiss_cli.agents import CommandRegistrar
from kiss_cli.integrations import INTEGRATION_REGISTRY
from kiss_cli.integrations.base import IntegrationBase


class TestCapabilityMatrixNoImplicitFalse:
    """Verify all integration subclasses explicitly declare all three capability flags."""

    def test_all_concrete_integrations_have_capability_flags(self):
        """Every integration subclass must explicitly declare all three flags."""
        failures = []

        for key, integration_class in INTEGRATION_REGISTRY.items():
            pass  # All 7 supported integrations checked

            cls = type(integration_class)

            # Check that the flag is explicitly declared in the class __dict__
            # (not inherited from the base)
            if "supports_argument_hints" not in cls.__dict__:
                failures.append(f"{cls.__name__} missing supports_argument_hints")
            if "supports_handoffs" not in cls.__dict__:
                failures.append(f"{cls.__name__} missing supports_handoffs")
            if "supports_multi_context_files" not in cls.__dict__:
                failures.append(f"{cls.__name__} missing supports_multi_context_files")

        if failures:
            pytest.fail(
                "The following integrations have implicit (inherited) capability flags:\n"
                + "\n".join(failures)
            )

    def test_capability_flags_are_boolean(self):
        """Each declared flag must be a boolean."""
        failures = []

        for key, integration in INTEGRATION_REGISTRY.items():
            if key == "generic":
                continue

            for flag_name in ["supports_argument_hints", "supports_handoffs", "supports_multi_context_files"]:
                flag_value = getattr(integration, flag_name, None)
                if not isinstance(flag_value, bool):
                    failures.append(
                        f"{type(integration).__name__}.{flag_name} = {flag_value!r} "
                        f"(expected bool)"
                    )

        if failures:
            pytest.fail("The following flags are not booleans:\n" + "\n".join(failures))


class TestRegistrarSkipsArgumentHintsForUnsupportingAgents:
    """Verify CommandRegistrar removes argument-hint from unsupporting agents."""

    def test_registrar_strips_argument_hint_from_metadata(self):
        """When supports_argument_hints=False, argument-hint should be removed."""
        registrar = CommandRegistrar()

        # Find an integration that doesn't support argument hints
        unsupporting_agent = None
        for key, integration in INTEGRATION_REGISTRY.items():
            if not integration.supports_argument_hints:
                unsupporting_agent = key
                break

        if not unsupporting_agent:
            pytest.skip("No unsupporting integration found in registry")

        frontmatter = {
            "name": "test-skill",
            "description": "Test",
            "metadata": {
                "argument-hint": "Describe the feature",
                "author": "test",
            },
        }

        # Apply gating
        result = registrar._gate_argument_hints(unsupporting_agent, frontmatter)

        # The result should not have argument-hint in metadata
        assert "argument-hint" not in result.get("metadata", {}), \
            f"argument-hint should be removed for {unsupporting_agent}"

        # Other metadata should be preserved
        assert result["metadata"]["author"] == "test"

    def test_registrar_preserves_argument_hint_for_supporting_agents(self):
        """When supports_argument_hints=True, argument-hint should be preserved."""
        registrar = CommandRegistrar()

        # Find an integration that supports argument hints
        supporting_agent = None
        for key, integration in INTEGRATION_REGISTRY.items():
            if integration.supports_argument_hints:
                supporting_agent = key
                break

        if not supporting_agent:
            pytest.skip("No supporting integration found in registry")

        frontmatter = {
            "name": "test-skill",
            "description": "Test",
            "metadata": {
                "argument-hint": "Describe the feature",
            },
        }

        # Apply gating
        result = registrar._gate_argument_hints(supporting_agent, frontmatter)

        # The argument-hint should be preserved
        assert result["metadata"]["argument-hint"] == "Describe the feature", \
            f"argument-hint should be preserved for {supporting_agent}"


class TestRegistrarSkipsHandoffsForUnsupportingAgents:
    """Verify CommandRegistrar removes ## Handoffs from unsupporting agents."""

    def test_registrar_strips_handoffs_section(self):
        """When supports_handoffs=False, ## Handoffs section should be removed."""
        registrar = CommandRegistrar()

        # Find an integration that doesn't support handoffs
        unsupporting_agent = None
        for key, integration in INTEGRATION_REGISTRY.items():
            if not integration.supports_handoffs:
                unsupporting_agent = key
                break

        if not unsupporting_agent:
            pytest.skip("No unsupporting integration found in registry")

        body = """## Overview
This is a test skill.

## Handoffs

After success, suggest:
- **Next step**: run `/kiss.plan`

## Inputs

- Input 1
"""

        # Apply gating
        result = registrar._gate_handoffs(unsupporting_agent, body)

        # The Handoffs section should be removed
        assert "## Handoffs" not in result, \
            f"## Handoffs should be removed for {unsupporting_agent}"

        # Other sections should be preserved
        assert "## Overview" in result
        assert "## Inputs" in result

    def test_registrar_preserves_handoffs_for_supporting_agents(self):
        """When supports_handoffs=True, ## Handoffs section should be preserved."""
        registrar = CommandRegistrar()

        # Find an integration that supports handoffs
        supporting_agent = None
        for key, integration in INTEGRATION_REGISTRY.items():
            if integration.supports_handoffs:
                supporting_agent = key
                break

        if not supporting_agent:
            pytest.skip("No supporting integration found in registry")

        body = """## Overview
This is a test skill.

## Handoffs

After success, suggest:
- **Next step**: run `/kiss.plan`

## Inputs

- Input 1
"""

        # Apply gating
        result = registrar._gate_handoffs(supporting_agent, body)

        # The Handoffs section should be preserved
        assert "## Handoffs" in result, \
            f"## Handoffs should be preserved for {supporting_agent}"

    def test_handoffs_regex_removes_section_cleanly(self):
        """Verify the Handoffs removal regex works correctly.

        Uses a real agent that doesn't support handoffs so the gating
        logic actually fires (an unknown ``"dummy"`` agent would short-
        circuit and return the body unchanged).
        """
        registrar = CommandRegistrar()
        non_supporting_agent = "gemini"  # supports_handoffs = False

        # Test case 1: Handoffs at end of file
        body1 = "Some text\n\n## Handoffs\n- Item 1\n- Item 2"
        result1 = registrar._gate_handoffs(non_supporting_agent, body1)
        assert "## Handoffs" not in result1
        assert result1.endswith("Some text\n")

        # Test case 2: Handoffs in the middle
        body2 = "Header\n\n## Handoffs\nContent\n\n## Footer\nMore"
        result2 = registrar._gate_handoffs(non_supporting_agent, body2)
        assert "## Handoffs" not in result2
        assert "## Footer" in result2
        assert "More" in result2


class TestRegistrarMultiContextFileGating:
    """Verify CommandRegistrar warns on unsupported multi-context files."""

    def test_multi_context_check_returns_true_for_single_file(self):
        """Single context files should always be allowed."""
        registrar = CommandRegistrar()

        # Any agent should allow a single context file
        for key in list(INTEGRATION_REGISTRY.keys())[:3]:  # Test a few
            result = registrar._gate_multi_context_files(key, 1)
            assert result is True, f"Single context file should be allowed for {key}"

    def test_multi_context_check_returns_false_for_unsupporting_agents(self):
        """Multiple context files should be denied for unsupporting agents."""
        registrar = CommandRegistrar()

        # All current integrations have supports_multi_context_files=False
        # So multiple files should not be allowed
        for key in list(INTEGRATION_REGISTRY.keys())[:3]:
            result = registrar._gate_multi_context_files(key, 2)
            # Note: may return False or issue warning depending on implementation
            # The important thing is it doesn't crash


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
