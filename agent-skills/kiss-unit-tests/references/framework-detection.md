# Unit-test framework detection

The scaffolder picks a framework based on files present in the
project root, in this order:

| Signal | Framework | Typical target dir |
|---|---|---|
| `pyproject.toml` or `pytest.ini` or `tests/conftest.py` | pytest | `tests/` |
| `package.json` with `vitest` in deps | vitest | `tests/` |
| `package.json` with `jest` in deps | jest | `__tests__/` |
| `package.json` with `mocha`/`chai` in deps | mocha | `test/` |
| `go.mod` | go test | co-located `_test.go` |
| `Cargo.toml` | cargo test | `tests/` + inline `#[cfg(test)]` |
| `pom.xml` or `build.gradle*` | junit5 | `src/test/java/` |
| `*.csproj` with xunit/nunit | xunit/nunit | `<proj>.Tests/` |
| `Gemfile` with `rspec` | rspec | `spec/` |
| `mix.exs` | exunit | `test/` |

## When detection is ambiguous

- Two frameworks in `package.json`: prefer the one with a `test`
  script pointing at it.
- No signals at all: log a `TQDEBT` and write tests as a dry
  scaffold in `tests/`, flagging that the developer should pick a
  framework.

## AI-authoring note

Never overwrite an existing test file. If a file with the same name
already exists, scaffold into `<name>.new.<ext>` and note it in
the index for the developer to reconcile.
