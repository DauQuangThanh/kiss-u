# Test-result formats

The ledger accepts four formats:

| Format | Source | Extract strategy |
|---|---|---|
| Inline counts | user env vars / answers | direct assignment |
| JUnit XML | CI artefact | parse `<testsuite tests failures errors skipped />` |
| TAP | `tap` reporter output | `# pass N` / `# fail N` lines |
| Plain summary | "42 passed, 3 failed" | regex match |

## Tips

- When a run is partial (e2e flaked), record it anyway with a note
  explaining why; partial data is better than silence.
- Don't delete a prior run if the same tests re-ran and passed.
  Append a new run with a note referring to the earlier failure.
- Coverage is a separate number — track it in the gate artefact,
  not here.
