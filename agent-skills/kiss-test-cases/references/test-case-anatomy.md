# Test-case anatomy

A minimal case has **five** fields. If any are missing, the case
is not executable.

| Field | Question answered |
|---|---|
| **Preconditions** | what state must the system be in? |
| **Steps** | what does the tester / automation do? |
| **Expected** | what observable outcome confirms pass? |
| **Type** | positive / negative / boundary |
| **Level** | unit / integration / e2e |

## Per type

- **Positive** — happy path. One per AC.
- **Negative** — invalid input, missing permission, expired
  session, etc. 1–2 per AC.
- **Boundary** — limits: max field length, just-below / just-above
  a threshold, empty collections. 1 per AC minimum.

## Writing style

- One verb per step. "Click Submit." not "Click Submit and wait
  then verify."
- Observable expected outcomes. "Response is 201 with a non-empty
  `id`" beats "Response looks good".
- Short preconditions. Link to a fixture rather than listing 12
  rows.

## Anti-patterns

- **Scripted narrative** — multi-paragraph prose. Break it up.
- **Implementation-coupled** — "Clicking button with id #foo".
  Refer to user-visible labels instead; they change less.
- **Coverage theatre** — 100 "smoke" cases that all pass trivially.
  Test the hard cases.
