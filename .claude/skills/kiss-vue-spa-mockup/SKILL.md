---
name: "kiss-vue-spa-mockup"
description: "Scaffolds a working Vue 3 SPA mockup with Vite, TypeScript, Tailwind CSS v4, PrimeVue, Vue Router v4, Pinia, vue-i18n v9, and 3-way theming (system / light / dark). Produces a ready-to-run project directory the developer can open immediately with `npm install && npm run dev`. Interactive mode asks for the output directory, app name, views, theme, and supported locales. Use when prototyping a feature UI, bootstrapping a front-end mockup, or when the team needs a runnable Vue SPA skeleton before the production app is built."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-vue-spa-mockup/kiss-vue-spa-mockup.md"
user-invocable: true
disable-model-invocation: false
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

3. **Views** — "Which views should be scaffolded?
   A) Just `Home` (default)
   B) `Home` + `About`
   C) Custom list — tell me the view names separated by commas"

4. **Theme** — "Which default theme should the app start with?
   A) System default — matches the user's OS setting (recommended)
   B) Always light
   C) Always dark"

5. **Locales** — "Which languages should the app support?
   Tell me as comma-separated BCP-47 codes (e.g. `en,vi,fr`).
   English (`en`) and Vietnamese (`vi`) are always included.
   (default: `en,vi`)"

## Inputs

- `.kiss/context.yml` (optional — used for feature slug and paths)
- User answers from the questionnaire above

## Outputs

The script writes a fully runnable SPA project under `{KISS_VUE_SPA_OUTPUT_DIR}`:

```text
{output_dir}/
├── .gitignore
├── index.html
├── package.json
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
├── vite.config.ts
└── src/
    ├── assets/
    │   └── main.css          # Tailwind v4 entry + CSS variables
    ├── i18n/
    │   └── index.ts          # vue-i18n createI18n setup
    ├── locales/
    │   ├── en.json           # English translations
    │   ├── vi.json           # Vietnamese translations
    │   └── <locale>.json     # one file per extra locale requested
    ├── main.ts               # app bootstrap: Vue + Router + Pinia + PrimeVue + i18n
    ├── App.vue               # root component: nav + RouterView + theme/lang switcher
    ├── router/
    │   └── index.ts          # Vue Router createRouter + routes
    ├── stores/
    │   └── app.ts            # Pinia store: 3-way theme (system|light|dark)
    └── views/
        └── <View>View.vue    # one file per requested view
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
  scaffolded against the view components.

## AI authoring scope

**Does:**
- Scaffold a runnable Vue 3 SPA with the tech stack below.
- Ask the user (interactive) or apply defaults (auto) for output directory,
  app name, and view list.
- Produce one `<View>View.vue` per requested view with a minimal placeholder
  UI using PrimeVue components and Tailwind utility classes.
- Record all defaults applied in auto mode to the agent-decisions log.
- Log a `VUEDEV` debt entry per view that only has placeholder content.

**Does not:**
- Run `npm install` or start the dev server.
- Generate full business-logic or API integration code.
- Modify files outside `{KISS_VUE_SPA_OUTPUT_DIR}`.

## Tech stack

| Concern         | Choice              | Version pin  |
|-----------------|---------------------|--------------|
| Build tool      | Vite                | ^6.0.0       |
| UI library      | Vue 3               | ^3.5.0       |
| Language        | TypeScript          | ~5.6.0       |
| Styling         | Tailwind CSS        | ^4.0.0       |
| Components      | PrimeVue            | ^4.3.0       |
| Routing         | Vue Router          | ^4.5.0       |
| State           | Pinia               | ^3.0.0       |
| Icon set        | PrimeIcons          | ^7.0.0       |
| i18n            | vue-i18n            | ^9.14.0      |

## Usage

> `<SKILL_DIR>` = the integration's skills root (e.g. `.claude/skills/`
> for Claude Code, `.agents/skills/` for Antigravity / Codex,
> `.cursor/skills/` for Cursor, `.windsurf/workflows/` for Windsurf).
> Scripts live at `<SKILL_DIR>/<skill-name>/scripts/…`.

### Interactive (default)

```bash
bash <SKILL_DIR>/kiss-vue-spa-mockup/scripts/bash/scaffold-vue-spa.sh
```

```powershell
pwsh <SKILL_DIR>/kiss-vue-spa-mockup/scripts/powershell/scaffold-vue-spa.ps1
```

### Auto

```bash
KISS_VUE_SPA_OUTPUT_DIR=mockup \
KISS_VUE_SPA_APP_NAME=my-feature-mockup \
KISS_VUE_SPA_VIEWS=Home,Dashboard,Settings \
bash <SKILL_DIR>/kiss-vue-spa-mockup/scripts/bash/scaffold-vue-spa.sh --auto
```

```powershell
$env:KISS_VUE_SPA_OUTPUT_DIR = 'mockup'
$env:KISS_VUE_SPA_APP_NAME   = 'my-feature-mockup'
$env:KISS_VUE_SPA_VIEWS      = 'Home,Dashboard,Settings'
pwsh <SKILL_DIR>/kiss-vue-spa-mockup/scripts/powershell/scaffold-vue-spa.ps1 -Auto
```

### Standard flags

| Flag / param        | Meaning                                          | Default |
|---------------------|--------------------------------------------------|---------|
| `--auto` / `-Auto`  | Non-interactive; use env / answers / defaults    | off     |
| `--answers FILE` / `-Answers FILE` | `KEY=VALUE` input file          | —       |
| `--dry-run` / `-DryRun` | Print what would be written, no filesystem changes | off |
| `--help` / `-Help`  | Show usage and exit                              | —       |

### Answer keys

| Key                        | Meaning                               | Default                         |
|----------------------------|---------------------------------------|---------------------------------|
| `KISS_VUE_SPA_OUTPUT_DIR`  | Directory to scaffold the SPA into   | `mockup`                        |
| `KISS_VUE_SPA_APP_NAME`    | npm package name                      | feature slug, or `my-app`       |
| `KISS_VUE_SPA_VIEWS`       | Comma-separated view names to create  | `Home`                          |
| `KISS_VUE_SPA_THEME`       | Initial theme: `system` / `light` / `dark` | `system`                  |
| `KISS_VUE_SPA_LOCALES`     | Comma-separated BCP-47 locale codes   | `en,vi`                         |
