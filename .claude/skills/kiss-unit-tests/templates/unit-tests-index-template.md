# Unit-tests index: {feature}

**Date:** {date}
**Framework:** {framework}
**Target dir:** {target_dir}
**Minimum coverage target:** {min_coverage}%

## Files

| Test file | Module under test | AC refs | Status |
|---|---|---|---|
| `tests/<module>.test.ts` | <module> | AC-01, AC-03 | Scaffolded |

## Cases per file

<!-- Populated as test files are generated; each line:
     ### tests/<module>.test.ts
     - happy: <short>
     - negative: <short>
     - boundary: <short>
-->

## How to run

- Happy path: `<framework-command> tests/`
- With coverage: `<framework-command> --coverage`

## Notes

- Each skeleton contains at least one `TODO(kiss-unit-tests)` marker
  where the developer must fill in a real assertion the AI could not
  infer from design + AC alone.
- Tests are scaffolds, not production tests. Run them and expect
  `TODO` failures.
