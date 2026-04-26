# ADR-008: Tag-triggered releases via GitHub Releases; no automatic remote push

**Date:** 2026-04-26
**Status:** Proposed
**Decider:** (decider: TBD — confirm)

## Context

KISS's release pipeline (`.github/workflows/release.yml`) runs on
git tag push, builds wheel + sdist with `uv build --wheel --sdist`,
attaches them plus a `SHA256SUMS` file to a GitHub Release
(`release.yml:128-138`), and stops there. It does not auto-publish
to PyPI. `CLAUDE.md` ("Remote repository") explicitly directs
contributors not to push commits directly to the remote — the
maintainer reviews diffs first.

This serves two distinct concerns:

1. **Release artefact provenance** — humans can inspect the
   tag-triggered build before any PyPI publication.
2. **Workflow discipline** — `main` is not auto-deployable from
   any single commit; releases are explicit, tagged events.

## Decision

Releases are **tag-triggered, GitHub-Release-only**:

- A push of an annotated tag matching the release pattern fires
  `.github/workflows/release.yml`.
- The workflow builds wheel + sdist via `uv build`, generates
  `SHA256SUMS`, and attaches them to a GitHub Release.
- **No** step automatically publishes to PyPI.
  PyPI publishing — when wired (TDEBT-018) — MUST be a separate,
  manually-invoked workflow gated on a maintainer action.
- Direct pushes to `main` are forbidden by the standards
  (`docs/standards.md` Development Workflow → "Branching").

## Consequences

- (+) Mistaken tags can be deleted before the wheel becomes
  public on PyPI.
- (+) Provenance is auditable — the tag → workflow run →
  artefacts chain is recorded by GitHub.
- (+) Air-gapped users can pull wheels from GitHub Releases
  without a PyPI account.
- (−) Users who only know `pip install kiss-u` see "package not
  found" until PyPI is wired — a documentation issue
  (`docs/installation.md`) plus TDEBT-018.
- (−) Manual PyPI step is a single point of friction for
  rapid-fire releases; acceptable trade-off for a single-developer
  team.

## Alternatives considered

- **Auto-publish to PyPI on tag** — rejected; once a version is
  on PyPI it cannot be deleted (only yanked), so the human-review
  step is structurally important.
- **Trusted Publishers (OIDC) auto-publish** — same objection as
  above; can be revisited if/when team size grows.
- **Distribute via container image only** — rejected; KISS is
  meant to be a developer-tool install, not a service.

## Source evidence

- `.github/workflows/release.yml:1-141`
- `CLAUDE.md` "Remote repository"
- `docs/standards.md` Development Workflow → "Branching"
