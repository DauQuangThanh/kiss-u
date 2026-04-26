# CI/CD: design

**Date:** {date}
**Provider:** {provider}
**Manual release gate:** {manual_release}

## Stages

1. **Lint + type check** — fail fast; seconds.
2. **Unit tests** — per-PR; minutes.
3. **Integration tests** — per-PR, requires test DB/IdP stub.
4. **Security scan** — SAST + secret scan; fails on Critical.
5. **Build** — produce the immutable artefact (container image,
   package, zip).
6. **Deploy to staging** — auto on merge to main.
7. **E2E tests on staging** — smoke + critical-path user journeys.
8. **Manual approval** (if `CI_REQUIRES_MANUAL_RELEASE` = true).
9. **Deploy to production** — canary / blue-green / rolling per
   `docs/operations/deployment.md`.

## Artefact flow

- Every successful merge produces one artefact tagged `<git-sha>`.
- Release deploys that exact artefact — nothing is rebuilt at
  release time.

## Quality-gate integration

See `{context.paths.docs}/testing/<feature>/quality-gates.md`.
Each PR / merge / release gate stage in CI corresponds 1:1 to a
gate row. A red gate blocks the merge or release.

## Skeleton pipeline

See `assets/ci-pipeline.sample.yml` for a {provider} starter.
