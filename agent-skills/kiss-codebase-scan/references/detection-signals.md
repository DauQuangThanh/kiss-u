# Codebase detection signals

Primary signals the scanner looks for. If conflicting signals
appear (e.g. both `package.json` and `pyproject.toml`), report a
polyglot codebase with both.

| Signal | Implies |
|---|---|
| `package.json` | Node.js |
| `pyproject.toml` / `requirements.txt` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml` / `build.gradle*` | Java / Kotlin |
| `Gemfile` | Ruby |
| `*.csproj` / `*.sln` | .NET |
| `mix.exs` | Elixir |
| `Dockerfile` | containerised |
| `terraform/**` / `*.tf` | IaC: Terraform |
| `.github/workflows/*.yml` | CI: GitHub Actions |
| `docker-compose.yml` | local orchestration |
| `k8s/**` / `charts/**` | Kubernetes |
| `swagger.{json,yaml}` / `openapi.{json,yaml}` | HTTP API |
| `proto/*.proto` | gRPC |

## Counting LOC

Count source lines only (exclude blank + comment-only when cheap;
otherwise report raw lines and note it). Exclude common build /
dependency directories via the `CS_EXCLUDE_GLOBS` default.
