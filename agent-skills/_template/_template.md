---
name: _template
description: >-
  Canonical scaffolding template for a new KISS role-skill bundle. Copy this
  folder, rename to kiss-<name>/, rename the command prompt to kiss-<name>.md,
  and adapt the sections below. Not shipped in the installer wheel.
license: MIT
compatibility: Designed for Claude Code and agentskills.io-compatible agents.
metadata:
  author: Dau Quang Thanh
  version: '1.0'
---

## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty).

## Inputs

This skill reads from `.kiss/context.yml` via `scripts/bash/common.sh`
(or `scripts/powershell/common.ps1`). Standard placeholders:

- `{context.paths.docs}` — documentation root
- `{context.paths.specs}` — SDD specs directory
- `{context.paths.plans}` — SDD plans directory
- `{context.paths.tasks}` — SDD tasks directory
- `{context.current.feature}` — active feature slug (required for
  feature-scoped outputs)
- `{context.current.branch}` — active git branch

A new skill based on this template should additionally list:

- Any upstream artefacts it reads (e.g.
  `{context.paths.docs}/architecture/c4-context.md`).

## Outputs

A new skill writes to one of:

- Project-scoped: `{context.paths.docs}/<work-type>/<artefact>.md`
- Feature-scoped: `{context.paths.docs}/<work-type>/{context.current.feature}/<artefact>.md`

Work-type directories are a fixed convention (see
`CLAUDE.md` §Key Facts). They are **not** configurable in
`.kiss/context.yml` — `paths.docs` is the configurable root.

Every output file may optionally be accompanied by an `<artefact>.extract`
companion file (key=value lines) so downstream skills consume structured
values instead of re-parsing markdown.

## Context Update

This skill does not mutate `.kiss/context.yml` directly. `kiss` CLI
commands are the only writers to that file.

## Handoffs

Document which downstream skills or agents read this skill's outputs.
Example:

- `kiss-test-strategy` reads `{context.paths.docs}/architecture/*.md`

## AI authoring scope

This skill is an AI authoring aid. It:

- Drafts artefacts from available inputs.
- Asks the single human user at the keyboard for information when an
  input is missing.
- Honours `{context.preferences.confirm_before_write}`.

It does **not**:

- Facilitate meetings, interview third parties, negotiate, approve or
  sign off on anything.
- Mutate code or files outside the work-type output directory without
  explicit user confirmation.

## Usage

Every new skill exposes at least one action script. The sample action
in this template is `example-action`:

```bash
bash scripts/bash/example-action.sh --help
```

```powershell
pwsh scripts/powershell/example-action.ps1 -Help
```

### Standard flags (every action script)

- `--auto` / `-Auto` — non-interactive; resolves answers from env vars,
  `--answers` file, upstream `.extract` files, documented defaults
  (in that order).
- `--answers FILE` / `-Answers FILE` — `KEY=VALUE` input file (one per
  line; `#` comments permitted).
- `--dry-run` / `-DryRun` — print what would be written without
  touching the filesystem.
- `--help` / `-Help` — show the action's usage and exit.

## Folder layout

```text
kiss-<name>/
├── kiss-<name>.md            # this file
├── templates/                # markdown templates written by the skill
├── references/               # rubrics, glossaries, loaded at runtime
├── assets/                   # non-markdown support material
└── scripts/
    ├── bash/
    │   ├── common.sh         # shared helpers — DO NOT modify per-skill
    │   └── <action>.sh       # one script per exposed action
    └── powershell/
        ├── common.ps1
        └── <action>.ps1
```

## Creating a new skill from this template

1. Copy `agent-skills/_template/` to `agent-skills/kiss-<name>/`.
2. Rename `_template.md` → `kiss-<name>.md`.
3. Update the `name:` and `description:` frontmatter.
4. Copy `scripts/bash/common.sh` and `scripts/powershell/common.ps1`
   verbatim (they are identical across all skills).
5. Replace the `example-action.{sh,ps1}` scripts with actions the new
   skill actually performs.
6. Populate `templates/`, `references/`, `assets/` with real content.
7. Update the Inputs / Outputs / Handoffs sections above.
