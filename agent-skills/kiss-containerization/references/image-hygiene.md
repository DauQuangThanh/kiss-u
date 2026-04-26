# Container image hygiene

## Size + speed

- **Multi-stage builds** cut the final image size dramatically.
- **Layer ordering**: copy dependency manifests first; install
  deps; then copy source. Layer cache works per-change.
- **Distroless / slim / alpine** — pick based on libc + debug
  needs. Alpine is smallest; can have musl incompatibilities.

## Security

- **Non-root user** — never `USER 0` at runtime.
- **No secrets at build time** — use build-args only for non-
  sensitive context.
- **No SSH keys, tokens, or private registries baked in.**
- **Pin base by digest** (`@sha256:...`), not just tag.
- **No curl|bash install steps** — pin the artefact.
- **Scan before push** — fail CI on High / Critical CVEs.

## Observability

- **Healthcheck** mandatory for orchestrator backoff.
- **Structured logs to stdout** — never a file inside the image.
- **Signal handling** — PID 1 must handle SIGTERM. If using `sh`
  as PID 1, add `tini` or `dumb-init`.
