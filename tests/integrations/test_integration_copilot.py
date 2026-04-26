"""Tests for CopilotIntegration."""

import textwrap

from kiss_cli.integrations import get_integration

from .test_integration_base_skills import SkillsIntegrationTests


class TestCopilotIntegration(SkillsIntegrationTests):
    KEY = "copilot"
    FOLDER = ".github/"
    COMMANDS_SUBDIR = "skills"
    REGISTRAR_DIR = ".github/skills"
    CONTEXT_FILE = "AGENTS.md"


class TestCopilotCustomAgentFilename:
    """Custom agents under .github/agents/ use the .agent.md extension."""

    def test_md_renamed_to_agent_md(self):
        i = get_integration("copilot")
        assert i.custom_agent_filename("architect.md") == "architect.agent.md"

    def test_already_agent_md_unchanged(self):
        i = get_integration("copilot")
        assert i.custom_agent_filename("architect.agent.md") == "architect.agent.md"

    def test_non_md_pass_through(self):
        i = get_integration("copilot")
        assert i.custom_agent_filename("README.txt") == "README.txt"


class TestCopilotCustomAgentTransform:
    """Frontmatter rewrite: tools→lowercase array, drop color."""

    def _src(self) -> str:
        return textwrap.dedent(
            """\
            ---
            name: architect
            description: A demo agent.
            tools: Read, Write, Edit, Bash, Glob, Grep, WebFetch, WebSearch
            model: inherit
            color: purple
            ---

            # Architect

            Body content.
            """
        )

    def test_tools_become_lowercase_array(self):
        i = get_integration("copilot")
        out = i.transform_custom_agent_content(self._src())
        assert "tools: [read, write, edit, bash, glob, grep, webfetch, websearch]" in out

    def test_color_field_dropped(self):
        i = get_integration("copilot")
        out = i.transform_custom_agent_content(self._src())
        assert "color:" not in out

    def test_other_frontmatter_preserved(self):
        i = get_integration("copilot")
        out = i.transform_custom_agent_content(self._src())
        assert "name: architect" in out
        assert "description: A demo agent." in out
        assert "model: inherit" in out

    def test_body_preserved_verbatim(self):
        i = get_integration("copilot")
        out = i.transform_custom_agent_content(self._src())
        assert "# Architect" in out
        assert "Body content." in out

    def test_already_array_form_lowercased(self):
        i = get_integration("copilot")
        src = "---\ntools: [Read, Write]\n---\n\nbody\n"
        out = i.transform_custom_agent_content(src)
        assert "tools: [read, write]" in out

    def test_no_frontmatter_passthrough(self):
        i = get_integration("copilot")
        src = "# Heading\n\nNo frontmatter here.\n"
        assert i.transform_custom_agent_content(src) == src

    def test_no_tools_field_only_drops_color(self):
        i = get_integration("copilot")
        src = "---\nname: x\ncolor: blue\n---\n\nbody\n"
        out = i.transform_custom_agent_content(src)
        assert "color:" not in out
        assert "name: x" in out

    def test_installed_custom_agent_is_transformed(self, tmp_path):
        """End-to-end: install_custom_agents writes the transformed file."""
        from pathlib import Path

        from kiss_cli.installer import install_custom_agents

        # Initialize a minimal kiss project so install_custom_agents can run.
        project = tmp_path / "proj"
        (project / ".kiss" / "integrations").mkdir(parents=True)

        results = install_custom_agents(project, ["copilot"])
        assert results.get("copilot", 0) > 0

        # Pick an agent we know ships with kiss and verify the on-disk content.
        target = project / ".github" / "agents" / "architect.agent.md"
        assert target.exists(), f"Expected {target} to be written"
        content = target.read_text(encoding="utf-8")
        assert "color:" not in content
        # Match the literal lowercase YAML inline array form.
        assert "tools: [read," in content
        assert ", websearch]" in content

        # Sanity: the body still renders.
        assert "# Architect" in content or "Architect" in content
