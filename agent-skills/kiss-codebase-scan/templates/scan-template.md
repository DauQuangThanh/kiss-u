# Codebase scan

**Date:** {date}
**Project root:** {root}
**Excluded:** {excludes}

## Languages + LOC

| Language | Files | LOC | Share |
|---|---:|---:|---:|
| TypeScript | | | |
| Python | | | |
| YAML | | | |

## Top-level layout

```text
<tree — one line per top-level dir with one-line purpose>
```

## Detected frameworks + tooling

| Category | Finding | Evidence |
|---|---|---|
| Runtime | Node 20 | `package.json` engines |
| Web framework | Express | `package.json` deps |
| Test framework | Vitest | `package.json` deps |
| Linter | ESLint | `.eslintrc*` |
| Formatter | Prettier | `.prettierrc*` |
| Build | esbuild | `package.json` deps |

## Entry points

- `src/server.ts` — HTTP server bootstrap
- `src/cli.ts` — CLI entry
- `workers/main.py` — background worker

## Test signals

- Test folder: `tests/` (or co-located)
- Coverage artefact present? y/n
- Recent pass rate: unknown (scan does not run tests)

## Unknowns

Logged as `ANALYSISDEBT-NN` in `docs/analysis/analysis-debts.md`.
