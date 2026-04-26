# ADR-007: Asset integrity via wheel-baked `sha256sums.txt`

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

The wheel bundles ~100s of MB worth of skills, presets, extensions,
workflows, and agent prompts (`kiss_cli/core_pack/`). If any of
those files becomes corrupted between build and install (download
truncation, archive extraction error, accidental edit by a tool
like a linter running over the install dir), KISS's `kiss init`
would write garbage into the user's project and the bug would be
hard to trace back to corruption rather than a logic error.

`scripts/generate-checksums.py:31-68` runs at build time, writes
`build/core_pack/sha256sums.txt` with one `<sha256>  <rel-path>`
line per asset, sorted. `_integrity.py:24-79` defines
`verify_asset_integrity(core_pack_root)` which reads the file and
re-hashes every asset, raising `AssetCorruptionError` on
mismatch.

A gap exists today: the technical-analyst could not locate a
production call site for `verify_asset_integrity` during normal
`kiss init` (ANALYSISDEBT-002 / TDEBT-002). The verification
function exists but is dormant.

## Decision

KISS commits to **asset integrity verification at install time**,
backed by the build-baked `sha256sums.txt`:

- `scripts/generate-checksums.py` runs unconditionally as part of
  `CustomBuildHook.initialize` (`hatch_build_hooks.py:129-138`).
- The wheel ships `kiss_cli/core_pack/sha256sums.txt`.
- `_integrity.verify_asset_integrity(core_pack_root)` MUST be
  invoked once per `kiss init` (and per `kiss upgrade`) at the
  start of the run, before any project tree is written.
- On `AssetCorruptionError`, KISS aborts with a non-zero exit and
  a message naming the file and the expected hash; no partial
  install is written.

The "MUST be invoked" clause is a **change** from today's
implementation — wiring this into the runtime path is what
TDEBT-002 tracks. This ADR locks the *commitment*; the wiring
work is a developer-agent task.

## Consequences

- (+) Corruption between build and install becomes a loud, early
  failure rather than a silent quality bug.
- (+) Tampering with `kiss_cli/core_pack/` after install (e.g. a
  malicious post-install script) is detectable on the next run.
- (+) Builds are reproducible at the byte level (the same input
  tree always produces the same `sha256sums.txt`).
- (−) Adds I/O at the start of every `kiss init`; for a wheel
  containing thousands of small files this is ~100ms on an SSD
  `(unverified — confirm benchmark)` (TDEBT-023).
- (−) Requires a one-time fix to wire `verify_asset_integrity`
  into the init flow.

## Alternatives considered

- **Sign the wheel with sigstore / GPG** — orthogonal; a wheel
  signature protects the *download*, not corruption *after* the
  download. Could be layered on later.
- **No integrity check** — current state. Rejected — silent
  corruption is worse than slow startup.
- **Verify on every catalog read** — rejected; redundant given
  catalogs are small subsets of the bundle, and the install
  start is the natural choke point.

## Source evidence

- `scripts/generate-checksums.py:31-68`
- `scripts/hatch_build_hooks.py:129-138`
- `src/kiss_cli/_integrity.py:11-21,24-99`
- `pyproject.toml:41-42` (`force-include` to `kiss_cli/core_pack`)
