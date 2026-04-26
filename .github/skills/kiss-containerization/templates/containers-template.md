# Containers: design

**Date:** {date}
**Runtime:** {runtime}
**Base image:** {base_image}

## Build strategy

- **Multi-stage** — build stage (fat) → runtime stage (slim).
- **Non-root** — run as a dedicated user with uid > 10000.
- **Read-only FS** where possible; writable volume mounts for
  state only.
- **Signal handling** — honour SIGTERM for graceful shutdown.
- **Healthcheck** — simple endpoint + interval.

## Image hygiene

- Pin base image by digest.
- Multi-arch if runtime targets mix x86_64 + arm64.
- Scan image in CI before publishing (`kiss-dependency-audit`).
- Strip build toolchain from the final image.

## Local development

See `assets/compose.sample.yml` for a compose starter with the
runtime + supporting services (DB, cache, IdP stub).

## Registry

- Registry: <project registry>
- Tag format: `<service>:<git-sha>` plus `latest` for mainline.
- Retention: keep last N production tags + current dev tag.
