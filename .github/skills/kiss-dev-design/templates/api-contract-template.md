# API Contract: {feature}

**Style:** {api_style}

## Endpoints

| Method | Path | Purpose | Auth | Body / Params | Response |
|---|---|---|---|---|---|
| GET | /api/v1/things | list things | user | `page`, `limit` | `Thing[]` |
| GET | /api/v1/things/:id | get a thing | user | `id` | `Thing` or 404 |
| POST | /api/v1/things | create a thing | user | `NewThing` | 201 `Thing` |

## Schemas

```ts
type Thing = {
  id: string;        // UUID v4
  name: string;      // 1-120 chars
  createdAt: string; // ISO 8601
}

type NewThing = Omit<Thing, 'id' | 'createdAt'>;
```

## Error responses

| Status | When | Body |
|---|---|---|
| 400 | validation | `{error, details}` |
| 401 | missing / expired token | `{error}` |
| 403 | role lacks permission | `{error}` |
| 404 | not found | `{error}` |
| 429 | over rate limit | `{error, retryAfterSeconds}` |
| 500 | server error | `{error, requestId}` |

## Versioning

- Breaking changes ship under a new `/api/vN` prefix.
- Additive changes are backward compatible and do not bump the
  version.
