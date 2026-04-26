# ADR-003: Offline operation after install

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

`CLAUDE.md` ("Offline operation") states: *"once `uv tool install`
(or the wheel install) finishes, `kiss init` and `kiss upgrade`
never touch the network. Anything that's needed at runtime must be
in the wheel bundle."*

The codebase enforces this in two places:

1. Every catalog read goes through
   `_locate_bundled_catalog_file()` (`_bundled_catalogs.py:28-45`),
   which falls back to repo-root paths only when running from a
   source checkout, and otherwise reads from
   `kiss_cli/core_pack/`.
2. `tests/test_offline.py` exercises `kiss init` with an
   intercepted network layer to assert no socket is opened.

The standards' Quality Gates implicitly assume this — the
"tests pass on every supported platform" gate would be flaky if
runtime behaviour depended on network conditions.

## Decision

KISS treats **offline-after-install** as a **hard architectural
invariant**, not just a feature:

- No KISS subcommand (`init`, `check`, `integration`, `preset`,
  `extension`, `workflow`, `version`) may open a network socket
  during normal operation.
- Catalogs (presets, extensions, workflows, integrations) are
  loaded only via `_locate_bundled_catalog_file()` or its
  equivalent for new asset families.
- The only network step in KISS's lifecycle is `uv tool install` /
  `pip install` itself, which fetches the wheel from
  GitHub Releases (or PyPI when wired — see TDEBT-018).
- ADR-017 (separate) extends `tests/test_offline.py` to cover
  every CLI subcommand, so this invariant is mechanically
  enforced rather than culturally enforced.

## Consequences

- (+) Predictable behaviour in air-gapped environments
  (a documented use case for SDD on regulated projects).
- (+) Faster CLI runtime (no DNS / TLS handshakes).
- (+) Smaller security surface — KISS can't be used to exfiltrate
  data through a typo in a catalog URL.
- (−) New features that "just need to fetch a small thing"
  must be redesigned to ship in the bundle or be moved to a
  separate, opt-in subcommand.
- (−) Catalog updates require shipping a new wheel; users on old
  versions see old catalogs until they `kiss upgrade`.

## Alternatives considered

- **Lazy network fetch with cache** — rejected; defeats the
  air-gap use case and fragments behaviour by network state.
- **Optional network with `--online` flag** — premature (Principle
  I, YAGNI); no current requirement asks for it.

## Source evidence

- `CLAUDE.md` "Offline operation"
- `src/kiss_cli/_bundled_catalogs.py:1-12,28-45`
- `tests/test_offline.py`
- `src/kiss_cli/installer.py:301-315` (`_locate_core_pack`)
