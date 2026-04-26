# ADR-005: Three output formats for integrations (Markdown, TOML, Skills)

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

The seven supported AI providers per ADR-018 (Claude Code,
GitHub Copilot, Cursor Agent, OpenCode, Windsurf, Gemini CLI,
Codex) each expect skills / commands in their own folder
layout and file format. Six of seven want the agentskills.io
`SKILL.md` folder layout; only Codex uses `.toml` for its
subagent files. Re-implementing the install path per
integration would duplicate enormous amounts of glue code.

The current code uses three abstract base classes in
`integrations/base.py`:

- `MarkdownIntegration` (line 865+) — single Markdown file per
  command.
- `TomlIntegration` (line 963+) — single TOML file per command.
- `SkillsIntegration` (line ~1000+) — `SKILL.md`-folder layout
  conformant with agentskills.io.

Each concrete integration inherits from exactly one of the three;
the concrete class supplies only the path conventions
(folder names, file extensions, frontmatter expectations). The
shared install / uninstall / upgrade lifecycle stays in
`IntegrationBase`.

## Decision

KISS's integration layer commits to **three output-format base
classes**: `MarkdownIntegration`, `TomlIntegration`,
`SkillsIntegration`. Every concrete integration MUST extend one
of the three — no integration may bypass them and re-implement
install primitives directly.

A new format (e.g. JSON, XML) MUST come with a new base class and
a superseding ADR; ad-hoc format-specific code in a concrete
integration is a Principle-V violation and MUST be flagged at
review.

## Consequences

- (+) The seven supported concrete integrations stay tiny —
  each is just a config dict + path conventions.
- (+) Adding a new supported provider (within the ADR-018
  list) is mechanical when its format matches one of the
  three.
- (+) The shared install lifecycle (template processing, manifest
  hashing, asset bundling) is exercised once across all
  integrations — fewer test surfaces.
- (−) Adding a *novel* format requires both a new base class and
  retrofitting `dispatch_command`, `process_template`,
  `bundle_skill_assets`. Not a problem today.
- (−) `IntegrationBase` is currently 1,374 LOC
  (`docs/analysis/codebase-scan.md` §2). It is the next
  decomposition target after `extensions.py` and `presets.py`
  (TDEBT-022).

## Alternatives considered

- **One base class with a `format` enum** — rejected; would push
  format-specific branching into shared code and grow the public
  surface.
- **Per-integration ad-hoc install code** — rejected; duplicates
  hashing, manifest, and asset-bundling logic across 13+
  integrations.
- **Plugin system for output formats** — premature (YAGNI); only
  three formats exist today.

## Source evidence

- `src/kiss_cli/integrations/base.py:56-1374` (the three base
  classes are at line 865, 963, …)
- `src/kiss_cli/integrations/__init__.py:14-84` (registry)
- Each `src/kiss_cli/integrations/<key>/__init__.py`
