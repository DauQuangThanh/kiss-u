# Standup shorthand

Users often type standup notes in terse shorthand. Recognise these
patterns when structuring the notes:

| Shorthand | Expansion |
|---|---|
| `y=` | yesterday |
| `t=` | today |
| `b=` | blockers |
| `y: …` / `today: …` / `tomorrow: …` | same as above, spelled out |
| `none` / `-` / `n/a` | no update / no blocker |
| `wait on X` / `blocked by X` | blocker — X is the dependency |
| `PR #123` / `BL-14` | link to a PR or backlog item |

## Parsing rules

- Split on newlines first; each line should start with a name or a
  label.
- If a name prefix is missing and the previous line named someone,
  assume continuation.
- Preserve any linked IDs (PR numbers, BL ids, RISK ids) verbatim.
- Do NOT invent team members. If a name is new to this sprint, flag
  it for the user to confirm.
