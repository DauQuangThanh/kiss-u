# C4 — Level 1: System Context

**Date:** 2026-04-26
**Subject system:** KISS CLI (kiss-u)

> Drafted by `architect` (auto mode). Status: **Proposed**. Decider:
> **TBD — confirm**.

## What this shows

The people and external systems that interact with KISS, and the
direction of those interactions. No internals — see `c4-container.md`
for that.

## Diagram

```mermaid
flowchart LR
    user["User<br/><em>developer / SDD practitioner</em>"]
    kiss(("KISS CLI<br/>(kiss-u)<br/><em>Python 3.11+ Typer app</em>"))

    subgraph distribution["Distribution"]
        github["GitHub<br/><em>code, CI, releases</em>"]
        pypi["PyPI<br/><em>(unverified — confirm)</em>"]
    end

    subgraph ai_providers["AI provider tools (7 supported per ADR-018; 13 currently in code)"]
        claude["Claude Code"]
        copilot["GitHub Copilot"]
        cursor["Cursor Agent"]
        opencode["OpenCode"]
        windsurf["Windsurf"]
        gemini["Gemini CLI"]
        codex["Codex"]
    end

    git["Git<br/><em>local binary</em>"]

    user -->|installs via uv tool / wheel| kiss
    user -->|runs kiss init / kiss check / kiss workflow run| kiss
    user -->|invokes AI CLIs after init| ai_providers

    pypi -.->|wheel + sdist<br/>(unverified)| user
    github -->|wheel + sdist + SHA256SUMS<br/>via Releases| user
    github -->|source clone for development| user

    kiss -->|writes project tree| user
    kiss -->|shells out: git init / add / commit| git
    kiss -.->|optional: dispatch_command<br/>after install| ai_providers

    classDef external fill:#eef,stroke:#558,color:#000
    class github,pypi,claude,copilot,cursor,opencode,windsurf,gemini,codex,git external
```

## Actors

| Actor | Type | Relationship | Notes |
|---|---|---|---|
| User (developer) | person | primary | Single human at the keyboard. KISS is explicitly an AI-authoring aid, not a multi-stakeholder facilitator (`CLAUDE.md` "AI-only scoping"). |

## External systems

> **Spec narrowed 2026-04-26.** Per `docs/AI-urls.md` and
> ADR-018, only the seven AI providers below are supported.
> The source code currently still ships six additional
> integrations (`agy`, `auggie`, `kilocode`, `kiro_cli`,
> `tabnine`, `generic`); their removal is a future pass and
> is tracked as TDEBT-028 (architecture) / RDEBT-024 (spec).

| System | Direction | Owner | Notes |
|---|---|---|---|
| GitHub | bidirectional | `DauQuangThanh/kiss-u` | Code hosting, GitHub Actions CI, tag-triggered releases. `pyproject.toml:19-20`. |
| PyPI | outbound (KISS → PyPI) | external | **(unverified — confirm)** — only GitHub Releases are wired today (`.github/workflows/release.yml:128-138`). Logged as TDEBT-018. |
| Git | local invocation | local binary | `installer.py:128-149` shells out for `git init`, `git add`, `git commit`. |
| Claude Code | AI provider | Anthropic | `integrations/claude/__init__.py:42-54`; agent file `<root>/CLAUDE.md`. |
| GitHub Copilot | AI provider | GitHub | `integrations/copilot/__init__.py:34-39`; agent file `<root>/AGENTS.md`. |
| Cursor Agent | AI provider | Cursor | `integrations/cursor_agent/__init__.py:13-26`; agent file `<root>/AGENTS.md`. |
| OpenCode | AI provider | external | `integrations/opencode/__init__.py`; agent file `<root>/AGENTS.md`. |
| Windsurf | AI provider | Codeium | `integrations/windsurf/__init__.py`; agent file `<root>/AGENTS.md`. |
| Gemini CLI | AI provider | Google | `integrations/gemini/__init__.py:8-21`; agent file `<root>/GEMINI.md`. |
| Codex | AI provider | OpenAI | `integrations/codex/__init__.py:14-27`; agent file `<root>/AGENTS.md`; subagents in TOML. |

## Trust & data-flow boundaries

- **Network calls at runtime: none** (post-install). Defended by
  `tests/test_offline.py` and the `_locate_bundled_catalog_file()`
  indirection (`_bundled_catalogs.py:28-45`).
- **Network calls at install time:** `uv tool install` /
  `pip install` fetch the wheel from GitHub Releases (or PyPI when
  wired). Subsequent `kiss …` invocations stay local.
- **Code execution risk:** KISS does **not** execute untrusted
  code at install time. `HookExecutor` (`extensions.py:2063+`)
  *can* run extension hooks, but only against installed
  extensions the user has explicitly added.
- **Output integrity:** every file written carries a SHA-256 in a
  per-integration manifest (`integrations/manifest.py:50-265`),
  enabling diff-aware uninstall (CADR-004 / ADR-004 below).
- **Asset integrity:** the wheel ships
  `core_pack/sha256sums.txt`; `_integrity.verify_asset_integrity()`
  is defined (`_integrity.py:24-79`) but its production call site
  was not located by the technical-analyst (ANALYSISDEBT-002 /
  TDEBT-002 here).

## Re-design notes (vs. extracted state)

This Level-1 view is **unchanged** by the re-design. The boundary
shape — single CLI process, offline runtime, fan-out to per-AI
file trees — is sound and aligns with the standards. All
re-design moves are inside C1 (the `kiss` CLI process) and are
shown in `c4-container.md` and `c4-component.md`.
