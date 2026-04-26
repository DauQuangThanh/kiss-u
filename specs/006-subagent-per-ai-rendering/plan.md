# Implementation Plan: subagent-per-ai-rendering

**Branch**: `006-subagent-per-ai-rendering` | **Date**: 2026-04-26 | **Spec**: [spec.md](spec.md)

## Summary

Fix per-AI subagent rendering so each of the 7 supported AIs
receives correctly-formatted subagent files: right directory,
right file extension, right frontmatter fields, and content limits
respected.

## Technical Context

**Language/Version**: Python 3.11+
**Source files**: `src/kiss_cli/integrations/{codex,opencode,gemini,windsurf,cursor_agent}/__init__.py`
**Testing**: pytest
**Constraints**: Offline (ADR-003), <=40 LOC/function (Principle III)

## Work Packages

### WP-1: Fix Codex agent directory (US-1)

Change `folder` from `.agents/` to `.codex/` in Codex config.

### WP-2: Add OpenCode `mode: subagent` (US-2)

Override `transform_custom_agent_content` in OpenCode to inject
`mode: subagent` into YAML frontmatter.

### WP-3: Add Gemini `kind: subagent` (US-3)

Override `transform_custom_agent_content` in Gemini to inject
`kind: subagent` into YAML frontmatter.

### WP-4: Windsurf workflow adaptation (US-4)

- Set `agents_subdir` to `workflows`
- Override `transform_custom_agent_content` to strip frontmatter
  (Windsurf workflows are plain Markdown)
- Warn on >12,000 chars

### WP-5: Codex frontmatter adaptation (US-5)

Override `transform_custom_agent_content` in Codex to restructure
body as `developer_instructions`.

### WP-6: Strip unsupported fields (US-6)

- Cursor: strip `color`, `tools`
- All: strip `color` field from base class (only Claude uses it)

## Dependency Graph

All WPs are independent (different integration files).

## Source Code

```text
src/kiss_cli/integrations/
├── codex/__init__.py       # WP-1, WP-5
├── opencode/__init__.py    # WP-2
├── gemini/__init__.py      # WP-3
├── windsurf/__init__.py    # WP-4
├── cursor_agent/__init__.py # WP-6
└── base.py                 # WP-6 (strip color from base)

tests/
├── test_subagent_rendering.py  # New: per-AI transformation tests
```
