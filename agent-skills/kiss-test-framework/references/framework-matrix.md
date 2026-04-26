# Framework matrix — recommended defaults

| Language / stack | Unit | Integration | E2E (web) |
|---|---|---|---|
| TypeScript / Node | vitest | vitest + supertest | playwright |
| Python | pytest | pytest + httpx | playwright-python |
| Go | go test | go test + httptest | playwright |
| Rust | cargo test | cargo test + wiremock-rs | playwright |
| Java / Kotlin | junit5 | junit5 + testcontainers | playwright + rest-assured |
| .NET | xunit | xunit + testcontainers | playwright |
| Ruby | rspec | rspec-rails | capybara |

## Pairing principles

- Unit and integration should share the runner when possible — one
  command, one config, one report.
- E2E runs in CI but should also be runnable locally against a
  staging-equivalent stack.
- Contract tests (Pact / Spring Cloud Contract) sit at the
  integration level and deserve their own file tree.

## Edge cases

- Legacy codebases with Mocha + Chai — keep them; migrating to
  Vitest should be an explicit ADR.
- Mixed-language monorepos — each language picks its own row, but
  the e2e runner is shared.
