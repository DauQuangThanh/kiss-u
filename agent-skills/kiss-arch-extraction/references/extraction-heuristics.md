# Architecture extraction heuristics

## Containers

- Look for entries in `docker-compose.yml`, Kubernetes manifests
  (`k8s/**`, `charts/**`), Terraform `aws_ecs_*` / `k8s_deployment`
  resources, and Procfiles.
- A directory with its own Dockerfile + entrypoint is likely a
  container boundary.

## Integrations

- Environment variable naming: `*_URL`, `*_API_KEY`, `*_CLIENT_ID`
  usually identifies external services.
- SDK imports: `@stripe/*`, `@okta/*`, `boto3`, `@aws-sdk/*`.
- Webhook endpoints in routes often indicate outbound integrations.

## Data flow

- Trace requests from HTTP entrypoints into service modules into
  repository / gateway modules; stop at the first I/O boundary.
- Queues / topics are edges — look for publish + consume both
  directions.

## Implicit decisions

- If a library appears prominently but no ADR exists, it was
  implicitly chosen. Flag as a candidate ADR, not as a finding.
- Don't invent the rationale — use "decision evident from
  implementation, rationale not documented".
