# Given/When/Then — style guide

GWT acceptance criteria are a contract between the product-owner
and the test-architect. Write each criterion so the tester can
translate it into an automated test without ambiguity.

## Anatomy

- **Given** — the context / preconditions the system must be in.
  State the data, the role, the configuration. *Not* the action.
- **When** — the single trigger event. One verb. If you find
  yourself writing two actions with "and", split into two criteria.
- **Then** — the observable outcome. Measurable, verifiable without
  asking someone a question.

## Good examples

> **Given** an authenticated user with a standard plan
> **When** they upload a file ≤ 10 MB via the /api/upload endpoint
> **Then** the response is 201 with a valid object URL and the file
> appears in their library within 2 seconds.
>
> **Given** an unauthenticated request
> **When** it targets any endpoint under /api/private
> **Then** the response is 401 and no session cookie is set.

## Common mistakes

- **"Then" says how, not what.** "Then it calls service X" → wrong.
  Rewrite: "Then …the user sees / the response contains / …".
- **Pronouns without antecedent.** "When they click it" — click
  what? Be explicit.
- **Business phrases.** "Then performance is acceptable" → rewrite
  with a measurable threshold ("within 200 ms p95").
- **Multiple Whens.** Split into two criteria.

## AI-authoring note

Draft criteria from the spec, but always leave them as proposals
the user can edit. A criterion is "accepted" only when the user or
the product-owner explicitly confirms it.
