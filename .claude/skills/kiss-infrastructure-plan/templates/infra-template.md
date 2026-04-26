# Infrastructure: design

**Date:** {date}
**Tool:** {tool}
**Cloud:** {cloud}
**Environments:** {envs}

## Account / subscription layout

- **Management / billing** — single, audit-only
- **Shared services** — identity, logging, DNS
- **Per-env accounts** — one per environment from {envs}

## Network

- **VPC / VNet per env** — non-overlapping CIDR blocks
- **Public subnets** — load balancer ingress only
- **Private subnets** — compute + data
- **Service endpoints / PrivateLink / VNet peering** — as required

## Compute

| Service | Target | Rationale |
|---|---|---|
| Web app | <managed container service> | |
| API | <same> | |
| Worker | <same> | |

## Storage + data

| Resource | Service | Notes |
|---|---|---|
| Primary database | <managed DB> | backup + PITR |
| Object storage | <managed> | versioned + lifecycle |
| Cache | <managed> | |

## IAM boundaries

- One role per service; least privilege.
- Humans: federated via IdP → short-lived creds.
- Secrets: managed secret store, never environment variables at
  rest.

## Starter module

See `assets/infra-starter.tf` (or equivalent for the chosen tool).

## Open questions

- Logged as `OPSDEBT-NN` in `docs/operations/ops-debts.md`.
