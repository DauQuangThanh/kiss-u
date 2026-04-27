# Baseline Manifest: {label}

**Type:** {type}
**Label:** {label}
**Date:** {date}
**Git tag:** `baseline/{label}`
**Created by:** kiss-baseline

## Summary

| Metric | Value |
|---|---|
| Total files snapshotted | {file_count} |
| Baseline type | {type} |
| Source branch | {git_branch} |
| HEAD commit (at baseline) | {git_sha} |

## Included artefacts

| Source path | Destination | SHA-256 | Size |
|---|---|---|---|
| <!-- AI: source path --> | <!-- destination --> | <!-- sha256 --> | <!-- size --> |

## Open items (BASEDEBT)

See `baseline-debts.md` in this directory for files that could not
be included.

## Git tag command

```bash
git tag -a baseline/{label} -m "Baseline {label} — {type} phase"
git push origin baseline/{label}
```
