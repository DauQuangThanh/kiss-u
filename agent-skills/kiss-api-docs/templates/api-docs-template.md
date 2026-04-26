# API documentation (extracted)

**Date:** {date}
**Style:** {style}

## Endpoints

| Method | Path | Source | Auth | Notes |
|---|---|---|---|---|
| GET | /api/v1/things | `src/api/things.ts:14` | user | list |
| POST | /api/v1/things | `src/api/things.ts:40` | user | create |

## Schemas

```ts
// Extracted from types at src/types/thing.ts
type Thing = { id: string; name: string; createdAt: string }
type NewThing = Omit<Thing, 'id' | 'createdAt'>
```

## Auth

- Middleware: `src/auth/middleware.ts:12` — OIDC Bearer
- Public endpoints: `/health`, `/api/public/*`

## Error responses

| Status | Seen in | Payload |
|---|---|---|
| 400 | validation failure | `{error, details}` |
| 401 | missing / expired token | `{error}` |
| 403 | role-based | `{error}` |
| 404 | not found | `{error}` |
| 500 | handler | `{error, requestId}` |

## Gaps / unknowns

- Logged as `ANALYSISDEBT-NN`.
