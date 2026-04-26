# Implementation Plan: skill-renames

**Branch**: `005-skill-renames` | **Date**: 2026-04-26 | **Spec**: [spec.md](spec.md)

## Summary

Rename 9 agent-skill directories and their prompt files per the
ADR-019 naming audit. Update frontmatter, cross-references, spec
documentation, and resolve RDEBT-029/031.

## Work Packages

### WP-1: Rename 9 skill directories + prompt files + frontmatter

For each of the 9 renames: `mv` directory, `mv` prompt file,
`sed` the `name:` frontmatter field.

### WP-2: Update cross-references

Grep all skill prompts for old names and update references.

### WP-3: Update spec documentation

Update the Naming Audit Appendix in agent-skills-system/spec.md.
Resolve RDEBT-029 and RDEBT-031.

## Execution

All 9 renames are independent — can run in parallel.
WP-2 and WP-3 depend on WP-1.
