# ADR-009: Static integration registry — no runtime plugin discovery

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

`src/kiss_cli/integrations/__init__.py:40-81` registers the 13
built-in AI-provider integrations inline in
`_register_builtins()` today. ADR-018 (2026-04-26) narrows the
**supported** set to seven (per `docs/AI-urls.md`); the
remaining six packages (`agy`, `auggie`, `kilocode`,
`kiro_cli`, `tabnine`, `generic`) are pending removal in a
future source-code pass — see RDEBT-024 / TDEBT-028. There is
no `entry_points`-based plugin discovery, no scanning of
`~/.kiss/plugins/`, and no remote catalog of providers.

The decision is deliberate: KISS bundles every integration it
supports, so the offline-after-install invariant (ADR-003) holds
and the asset-integrity invariant (ADR-007) covers everything
the user will execute.

A loose-plugin model would require:

- Network access at runtime (rejected by ADR-003), or
- A trust model for third-party plugins (large security surface),
  or
- Distribution-side plugin signing (large infra surface).

None of those are currently justified — the user requirement is
"bring up Claude / Gemini / Cursor / … on a project, offline",
not "extend the CLI from outside".

## Decision

KISS uses a **static integration registry** keyed by built-in
class names registered in `_register_builtins()`. Adding a new
integration requires:

1. A new package under `src/kiss_cli/integrations/<key>/`.
2. A class extending `MarkdownIntegration`, `TomlIntegration`,
   or `SkillsIntegration` (per ADR-005).
3. An entry in `_register_builtins()` plus a metadata entry in
   `integrations/catalog.json`.
4. A test under `tests/`.
5. A PR (`docs/standards.md` Development Workflow).

There is no out-of-tree plugin mechanism. The `Generic`
integration (`integrations/generic/__init__.py`) currently
remains in source as a "bring your own AI" escape hatch via a
`--commands-dir` flag, but per ADR-018 it is **out of scope**
and slated for removal alongside the other five unsupported
integrations.

## Consequences

- (+) Every integration ships with a known hash (ADR-007) and is
  exercised in CI.
- (+) New providers are added by editing one file
  (`_register_builtins`) and adding one package — the contribution
  surface is obvious.
- (−) The `Generic` escape hatch (today still in code) is out of
  scope per ADR-018; "bring your own AI" is no longer a
  supported pattern. Users on unsupported AIs must wait for an
  upstream addition or fork.
- (−) A user who wants a private integration must fork or
  contribute upstream; cannot ship their own wheel that augments
  KISS's registry.
- (−) The registry list in `_register_builtins()` is duplicated
  in `integrations/catalog.json` for catalog operations. Drift
  between the two would be a bug; not currently caught by an
  automated check (TDEBT-024).

## Alternatives considered

- **`entry_points` plugin discovery** — rejected; breaks
  offline-after-install (a user could `pip install` a malicious
  plugin) and breaks asset-integrity guarantees.
- **Remote catalog of integrations** — rejected (ADR-003).
- **Configuration-only integration enablement** (no code
  registration) — rejected; integration classes contain real
  logic (path conventions, dispatch_command behaviour, frontmatter
  rules) that cannot be expressed in pure config.

## Source evidence

- `src/kiss_cli/integrations/__init__.py:14-84`
- `src/kiss_cli/integrations/generic/__init__.py:17-51`
- `integrations/catalog.json` (asset)
- `pyproject.toml` — no `entry_points` declared
