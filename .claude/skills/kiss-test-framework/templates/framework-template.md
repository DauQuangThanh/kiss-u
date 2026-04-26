# Test framework: {feature}

**Date:** {date}

## Choices (proposed — confirm with team)

| Level | Framework | Version target | Notes |
|---|---|---|---|
| Unit | {unit} | latest stable | |
| Integration | {integration} | matches unit | share config with unit |
| End-to-end | {e2e} | latest stable | browser / mobile / API |

## Folder layout

```text
tests/
├── unit/                # mirrors source tree
├── integration/
├── e2e/
└── fixtures/            # shared test data
```

## Dev-dependencies

```text
<list frameworks + assertion libs + fakes + http-mocks>
```

## Commands

- **Run unit only:** `<cmd>`
- **Run integration:** `<cmd>`
- **Run e2e:** `<cmd>`
- **Run with coverage:** `<cmd>`
- **Watch mode:** `<cmd>`

## Seam conventions

- Mock external I/O at the **repository / gateway** layer, not
  in tests.
- Feature flags: use a test-time config, not code branches inside
  tests.
- Fixtures: small, expressive helpers > giant JSON blobs.
