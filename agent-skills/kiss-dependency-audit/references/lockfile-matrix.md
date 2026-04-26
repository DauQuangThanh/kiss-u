# Lockfile matrix

| Language / tool | Lockfile | List command |
|---|---|---|
| npm / yarn / pnpm | `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` | `npm ls --all` / `pnpm list --depth=Infinity` |
| Python (uv) | `uv.lock` | `uv tree` |
| Python (poetry) | `poetry.lock` | `poetry show --tree` |
| Python (pip-tools) | `requirements.txt` | `pip list --format=json` |
| Go | `go.sum` | `go list -m all` |
| Rust | `Cargo.lock` | `cargo tree` |
| Java (Maven) | `pom.xml` | `mvn dependency:tree` |
| Java (Gradle) | `gradle.lockfile` | `./gradlew dependencies` |
| Ruby | `Gemfile.lock` | `bundle list` |
| .NET | `packages.lock.json` | `dotnet list package --include-transitive` |
| Elixir | `mix.lock` | `mix deps.tree` |

## Which lockfile to audit

The first lockfile encountered in the project root wins. If the
project has multiple (polyglot monorepo), audit each and write one
section per language.

## CVE sources (cite every claim)

- GitHub Security Advisories (preferred — structured data)
- OSV.dev (aggregator)
- Vendor advisory mailing lists
- MITRE CVE records

Never rely on training-time knowledge for versions — always fetch.
