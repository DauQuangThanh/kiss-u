# Implementation Plan: narrow-to-seven-ais

**Branch**: `004-narrow-to-seven-ais` | **Date**: 2026-04-26 | **Spec**: [spec.md](spec.md)

## Summary

Remove the 6 unsupported AI integration packages (agy, auggie,
generic, kilocode, kiro\_cli, tabnine) from source, tests, docs,
and catalog. Wire asset integrity verification into `kiss init`.
Resolve RDEBT-003, RDEBT-004, RDEBT-024.

## Technical Context

**Language/Version**: Python 3.11+
**Primary Dependencies**: Typer, Rich, hatchling
**Testing**: pytest (existing suite)
**Constraints**: Offline-only (ADR-003), Principle III (small units), >=80% coverage

## Standards Check

| Gate | Status | Notes |
|------|--------|-------|
| Test-First (Principle II) | PASS | Verify existing tests pass after removal |
| Small Units (Principle III) | PASS | Removing code, not adding complexity |
| Coverage >= 80% | WATCH | Removing test files reduces total count; remaining must pass |
| Lint zero-warnings | PASS | Ruff via CI |

## Work Packages

### WP-1: Remove integration packages (US-1)

Delete 6 directories under `src/kiss_cli/integrations/`:
`agy/`, `auggie/`, `generic/`, `kilocode/`, `kiro_cli/`,
`tabnine/`.

### WP-2: Update registry (US-1)

Update `src/kiss_cli/integrations/__init__.py` to only import
and register the 7 supported integrations.

### WP-3: Remove tests (US-2)

Delete 6 test files under `tests/integrations/`:
`test_integration_agy.py`, `test_integration_auggie.py`,
`test_integration_generic.py`, `test_integration_kilocode.py`,
`test_integration_kiro_cli.py`, `test_integration_tabnine.py`.

Update remaining test files that reference removed integrations.

### WP-4: Clean source references (US-5)

- `src/kiss_cli/__init__.py`: remove `tabnine` from
  `_TOML_AGENTS`
- `src/kiss_cli/installer.py`: remove `kiro-cli` special case
  from `check_tool`
- `src/kiss_cli/cli/check.py`: remove 6 entries from
  `INTEGRATION_INSTALL_DIRS`
- `src/kiss_cli/agents.py`: remove references if any
- `src/kiss_cli/presets.py`: remove references if any

### WP-5: Clean catalog and docs (US-3)

- `integrations/catalog.json`: keep only 7 entries
- Update spec files under `docs/specs/` to remove removed-AI
  references or mark as historical
- Update `docs/specs/requirement-debts.md`: resolve RDEBT-003,
  RDEBT-004, RDEBT-024

### WP-6: Wire asset integrity (US-4)

- Add `verify_asset_integrity(core_pack_root)` call in
  `cli/init.py` before reading the bundle
- Add call in `cli/integration.py` upgrade path
- Add test for integrity check during init

## Dependency Graph

```text
WP-1 (remove packages) → WP-2 (update registry)
WP-3 (remove tests)    ── parallel with WP-1/WP-2
WP-4 (clean source)    ── depends on WP-1/WP-2
WP-5 (clean docs)      ── independent
WP-6 (asset integrity) ── independent
```

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| Removing packages breaks imports in unexpected places | High | Grep for all references before deleting; run full test suite |
| Existing user projects have removed integrations installed | Medium | Users must switch before upgrading kiss; document in upgrade.md |
| Asset integrity adds startup latency | Low | Integrity check is O(n) file hashes; measured as <1s for 58 skills |
