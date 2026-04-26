# Change register — hygiene

## Rules

1. One row per fix. If a bug needed two PRs, write two rows with
   distinct commits + PRs.
2. Always record the **reviewer**. A merge without a reviewer is a
   process gap the register surfaces.
3. Always link the **regression test**. If a bug is genuinely
   un-testable, write that in the cell — don't leave it blank.
4. Never overwrite a prior row. If the fix was reverted, add a new
   row documenting the revert.

## Linking with the source bug file

When a fix lands, update the source `BUG-NN.md`:

```text
## Fix history
- YYYY-MM-DD: fixed in `abc1234` (PR #512), reviewed by <name>.
  Regression test: `tests/regression/bug-NN.test.ts`.
- YYYY-MM-DD: reverted in `def5678` (PR #520) — reason: X.
```

The change-register row and the bug's fix-history must agree.
