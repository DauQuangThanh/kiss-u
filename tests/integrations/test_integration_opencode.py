"""Tests for OpencodeIntegration."""

from .test_integration_base_markdown import MarkdownIntegrationTests


class TestOpencodeIntegration(MarkdownIntegrationTests):
    KEY = "opencode"
    FOLDER = ".opencode/"
    COMMANDS_SUBDIR = "skills"
    REGISTRAR_DIR = ".opencode/skills"
    CONTEXT_FILE = "AGENTS.md"
