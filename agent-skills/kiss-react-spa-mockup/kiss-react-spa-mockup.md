---
name: kiss-react-spa-mockup
description: >-
  Scaffolds a working React SPA mockup with Vite, TypeScript, Tailwind CSS v4,
  shadcn/ui, React Router v7, react-i18next, and a 3-way theme system (light /
  dark / system). Produces a ready-to-run project directory the developer can
  open immediately with `npm install && npm run dev`. Interactive mode asks for
  the output directory, app name, pages, theme default, and supported locales.
  Use when prototyping a feature UI, bootstrapping a front-end mockup, or when
  the team needs a runnable SPA skeleton before the production app is built.
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

## Audience and tone (interactive mode)

When `KISS_AGENT_MODE=interactive` (the default), assume the user
may have limited front-end scaffolding experience. Run this skill
as a guided questionnaire:

- **One question at a time.** Do not present multiple questions together.
- **Yes / no first.** Phrase so `yes`, `no`, `not sure`, or `skip` is
  a valid answer.
- **Always recommend.** State the option you would pick and why in one
  sentence, so the user can reply "yes" / "ok" to accept.
- **Choices, not blank fields.** When yes/no isn't enough, offer 2-4
  lettered options (A/B/C/D) with one-line descriptions. Always include
  "Not sure — pick a sensible default".
- **`not sure` / `skip` triggers a sensible default** — record the
  decision as `default-applied` via `write_decision`.

When `KISS_AGENT_MODE=auto` (or `--auto`), skip the questionnaire
entirely: use all documented defaults and record each one with
`write_decision default-applied`.

## Questionnaire (interactive mode only)

Ask these questions in sequence. Stop when you have enough to scaffold:

1. **Output directory** — "Where should the SPA project be created?
   (e.g. `mockup/`, `frontend/`, or a custom path — default is `mockup/`)"

2. **App name** — "What's the npm package name for this app?
   (e.g. `my-feature-mockup` — default: derived from the current feature
   slug, or `my-app` if no feature is set)"

3. **Pages** — "Which pages should be scaffolded?
   A) Just `Home` (default)
   B) `Home` + `About`
   C) Custom list — tell me the page names separated by commas"

4. **Theme** — "Which theme mode should the app start in?
   A) System default — follows the OS dark/light preference (recommended)
   B) Light — always light
   C) Dark — always dark"

5. **Locales** — "Which languages should the app support? The scaffold ships
   English (`en`) and Vietnamese (`vi`) by default. Do you need any others?
   (Reply with BCP-47 codes separated by commas, e.g. `fr,ja` — or press
   Enter to keep the default `en,vi`)"

## Inputs

- `.kiss/context.yml` (optional — used for feature slug and paths)
- User answers from the questionnaire above

## Outputs

The script writes a fully runnable SPA project under `{KISS_SPA_OUTPUT_DIR}`:

```text
{output_dir}/
├── .gitignore
├── components.json          # shadcn/ui config
├── index.html
├── package.json
├── tsconfig.json
├── tsconfig.app.json
├── vite.config.ts
└── src/
    ├── index.css            # Tailwind v4 entry + CSS variables
    ├── main.tsx
    ├── App.tsx
    ├── router.tsx           # React Router v7 browser router
    ├── hooks/
    │   └── useTheme.ts      # 3-way theme hook (system / light / dark)
    ├── i18n/
    │   └── setup.ts         # i18next initialisation
    ├── lib/
    │   └── utils.ts         # clsx + tailwind-merge helper
    ├── locales/
    │   ├── en.json           # English translations
    │   ├── vi.json           # Vietnamese translations
    │   └── <extra>.json      # one file per additional locale
    └── pages/
        └── <Page>.tsx       # one file per requested page
```

The skill does **not** run `npm install`. After scaffolding, the user runs:

```bash
cd {output_dir}
npm install
npm run dev
```

## Context Update

This skill does not mutate `.kiss/context.yml`.

## Handoffs

- `kiss-wireframes` — wireframes produced by that skill can be used as the
  layout reference before running this skill.
- `kiss-dev-design` — the design doc describes the component model; this
  skill realises it as runnable starter code.
- `kiss-unit-tests` — once the skeleton is in place, unit tests can be
  scaffolded against the page components.

## AI authoring scope

**Does:**

- Scaffold a runnable SPA project with the tech stack below.
- Ask the user (interactive) or apply defaults (auto) for output directory,
  app name, and page list.
- Produce one `<Page>.tsx` per requested page with a minimal placeholder UI
  using shadcn/ui primitives and Tailwind utility classes.
- Record all defaults applied in auto mode to the agent-decisions log.
- Log a `SPADEV` debt entry per page that only has placeholder content.

**Does not:**

- Run `npm install` or start the dev server.
- Generate full business-logic or API integration code.
- Modify files outside `{KISS_SPA_OUTPUT_DIR}`.

## Tech stack

| Concern         | Choice              | Version pin  |
|-----------------|---------------------|--------------|
| Build tool      | Vite                | ^6.0.0       |
| UI library      | React               | ^19.0.0      |
| Language        | TypeScript          | ~5.6.0       |
| Styling         | Tailwind CSS        | ^4.0.0       |
| Components      | shadcn/ui           | (copy-paste) |
| Routing         | React Router        | ^7.2.0       |
| i18n            | react-i18next + i18next | ^15.0.0  |
| Icon set        | lucide-react        | ^0.475.0     |
| Utility helpers | clsx + tailwind-merge | latest     |

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

### Interactive (default)

```bash
bash <SKILL_DIR>/kiss-react-spa-mockup/scripts/bash/scaffold-spa.sh
```

```powershell
pwsh <SKILL_DIR>/kiss-react-spa-mockup/scripts/powershell/scaffold-spa.ps1
```

### Auto

```bash
KISS_SPA_OUTPUT_DIR=mockup \
KISS_SPA_APP_NAME=my-feature-mockup \
KISS_SPA_PAGES=Home,Dashboard,Settings \
KISS_SPA_THEME=system \
KISS_SPA_LOCALES=en,vi \
bash <SKILL_DIR>/kiss-react-spa-mockup/scripts/bash/scaffold-spa.sh --auto
```

```powershell
$env:KISS_SPA_OUTPUT_DIR = 'mockup'
$env:KISS_SPA_APP_NAME   = 'my-feature-mockup'
$env:KISS_SPA_PAGES      = 'Home,Dashboard,Settings'
$env:KISS_SPA_THEME      = 'system'
$env:KISS_SPA_LOCALES    = 'en,vi'
pwsh <SKILL_DIR>/kiss-react-spa-mockup/scripts/powershell/scaffold-spa.ps1 -Auto
```

### Standard flags

| Flag / param      | Meaning                                            | Default |
|-------------------|----------------------------------------------------|---------|
| `--auto` / `-Auto`  | Non-interactive; use env / answers / defaults    | off     |
| `--answers FILE` / `-Answers FILE` | `KEY=VALUE` input file           | —       |
| `--dry-run` / `-DryRun` | Print what would be written, no filesystem changes | off |
| `--help` / `-Help`  | Show usage and exit                              | —       |

### Answer keys

| Key                   | Meaning                               | Default                         |
|-----------------------|---------------------------------------|---------------------------------|
| `KISS_SPA_OUTPUT_DIR` | Directory to scaffold the SPA into        | `mockup`                        |
| `KISS_SPA_APP_NAME`   | npm package name                          | feature slug, or `my-app`       |
| `KISS_SPA_PAGES`      | Comma-separated page names to create      | `Home`                          |
| `KISS_SPA_THEME`      | Initial theme: `system` / `light` / `dark` | `system`                      |
| `KISS_SPA_LOCALES`    | Comma-separated BCP-47 locale codes        | `en,vi`                        |
