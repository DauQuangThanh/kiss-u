# ADR-017: Enforce the offline-runtime invariant via boundary tests

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

ADR-003 commits KISS to **offline operation after install**. The
existing defence is a single test, `tests/test_offline.py`, which
exercises `kiss init` with the network blocked.

This is necessary but not sufficient:

- It only covers `kiss init`. The `kiss check`, `kiss
  integration` (`install` / `uninstall` / `switch` / `upgrade`),
  `kiss preset`, `kiss extension`, `kiss workflow run / resume /
  status`, and `kiss version` subcommands are not checked.
- Future code added inside `extensions.py` /
  `presets.py` (or, post-decomposition, the `extensions/` /
  `presets/` packages) could quietly call `urllib`, `requests`,
  or any network-using library and the existing test would not
  catch it.

The risk is not theoretical: the project's catalogs of presets,
extensions, and workflows include URL fields, and a future
"smart catalog refresh" feature could naively reach for them at
runtime.

## Decision

KISS enforces the offline-runtime invariant **mechanically** via
boundary tests:

1. **Network-block fixture.** A pytest fixture (`tests/conftest.py`
   or a dedicated `tests/_network_block.py`) intercepts:
   - `socket.socket.connect`, `socket.socket.connect_ex`
   - `urllib.request.urlopen`, `urllib3` connection attempts
   - `http.client.HTTPConnection.connect`
   - and raises a clear `RuntimeError("Network access during
     offline-mode test")` on any attempt.
2. **Per-subcommand offline coverage.** `tests/test_offline.py`
   is expanded to one test per top-level KISS subcommand:
   - `kiss init …`
   - `kiss check skills` / `check integrations` / `check context`
   - `kiss integration list` / `install` / `uninstall` / `switch`
     / `upgrade`
   - `kiss preset list` / `add` / `remove` / `info`
   - `kiss extension list` / `add` / `remove` / `info` / `update`
   - `kiss workflow list` / `run` / `resume` / `status`
   - `kiss version`
3. **Test runs in CI.** The expanded `test_offline.py` is part of
   the standard `pytest` matrix
   (`.github/workflows/test.yml:30-55`); a network call from any
   subcommand fails the build.
4. **Catalog refresh is out of scope.** If a future feature ever
   needs network access, it ships behind an explicit
   `--online` opt-in flag and the boundary test confirms the
   default path stays offline.

The fixture itself is **shared** — reused by any future test that
wants to assert a code path is offline.

## Consequences

- (+) The offline guarantee stops being a single test of one
  command and becomes a checkable property of the whole CLI
  surface.
- (+) Future contributions adding network calls fail loudly in CI
  rather than silently regressing the invariant.
- (+) Air-gapped users (a real use case for SDD on regulated
  projects) get a contractual guarantee, not a hope.
- (−) Test setup is more elaborate (mocking `socket.connect`
  intercepts is tricky to do cleanly across Linux + Windows;
  `(unverified — confirm)` portability of `urllib3` patching).
- (−) Some legitimate I/O calls go through `socket` indirectly
  (e.g. unix-domain sockets used by some libraries internally);
  the fixture must allow loopback / unix sockets while blocking
  remote TCP. Calibration may require iteration.

## Alternatives considered

- **Document the invariant, do not test** — current state for 6
  of the 7 subcommands. Rejected — drift is inevitable.
- **Run integration tests on an air-gapped CI runner** —
  rejected; complex infra change, smaller blast radius
  achievable in pure pytest.
- **Static analysis (`flake8-imports-no-network`)** — rejected;
  insufficient (catches imports, not transitive calls through
  dependencies).

## Source evidence

- ADR-003 (the invariant being defended)
- `tests/test_offline.py` (current single-command coverage)
- `docs/analysis/api-docs.md` §1 (full CLI surface this ADR
  expands coverage to)
- `.github/workflows/test.yml:30-55`
