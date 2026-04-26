# CI/CD providers — quick reference

| Provider | Strengths | Watch out for |
|---|---|---|
| GitHub Actions | Tight with GitHub; free tier generous; matrix builds | YAML sprawl; self-hosted runners for heavy builds |
| GitLab CI | Built-in with GitLab; strong DAG support | Runner config; default image sizes |
| Azure Pipelines | Enterprise Windows + .NET; free for OSS | YAML + classic pipeline split |
| CircleCI | Fast caching; orbs ecosystem | Pricing scales with parallelism |
| Buildkite | Self-hosted agents by design; hybrid model | You operate the agents |
| Jenkins | Widely known; plugin ecosystem | Operational burden; plugin vulnerabilities |

## Picking

- Hosted on GitHub? Start with GitHub Actions.
- Hosted on GitLab? Start with GitLab CI.
- Enterprise .NET on Azure DevOps? Azure Pipelines.
- Otherwise: whichever your team has on-call expertise for.

## Anti-patterns

- **Every job in one YAML file** — split into reusable workflows /
  templates once it grows past ~200 lines.
- **Secrets in plain text** — always use the provider's secret
  store + environment protection rules.
- **No timeouts** — a hung pipeline hogs runners; every step
  should have a timeout.
