# Gate design — guidance

## Principles

1. **Fast gates run first.** Lint + unit + type checks should fail
   a PR in under 5 minutes.
2. **Every gate has exactly one owner.** If a gate fails, it's
   clear who fixes it.
3. **Gates block merge, not development.** A red gate means "don't
   merge", not "stop coding".
4. **Thresholds, not sentiment.** Every gate is a numeric threshold
   or a binary pass/fail — never "looks good".

## Per-stage purpose

- **PR gate** — fast feedback; developer should see red quickly.
- **Merge gate** — slower tests that require integration services
  (DBs, queues, IdP stubs).
- **Release gate** — e2e on a staging-equivalent; manual review of
  runbooks; security deep scan.

## Common anti-patterns

- **Coverage as the only signal** — a 90%-covered codebase can
  still be broken. Pair coverage with mutation or assertion
  density.
- **One gate, many checks** — when a gate fails, nobody knows
  which check went red. Split.
- **Waivers without expiry** — silent drift. Always expire.
