# Local Development Guide

This guide shows how to iterate on the `kiss` CLI locally without publishing a
release. It also walks through developing and integrating extensions, workflows,
presets, role skills, and new AI integrations, and how to test each.

> **Asset source-of-truth:** the top-level `agent-skills/`, `subagents/`,
> `presets/`, `extensions/`, `workflows/`, and `integrations/` directories are
> authoritative. Every skill lives at `agent-skills/kiss-<name>/` with its own
> `scripts/` and `templates/` subfolders. `build/core_pack/` is a
> **build-time staging directory** (gitignored) populated by
> `scripts/hatch_build_hooks.py` during `uv build`, then mapped into the wheel
> as `kiss_cli/core_pack/` via `force-include` in `pyproject.toml`. Never edit
> files under `build/core_pack/` by hand — they are overwritten on every build.
>
> **Offline operation:** once a wheel is installed, `kiss init` and
> `kiss upgrade` never touch the network. Anything needed at runtime must be
> bundled into the wheel.

## 1. Clone and Set Up

```bash
git clone https://github.com/DauQuangThanh/kiss-u.git
cd kiss-u
git checkout -b your-feature-branch

# uv handles the virtualenv and dev dependencies
uv sync
```

## 2. Fastest Feedback — Editable Install

```bash
# Install the project in editable mode (pyproject declares the `kiss` entry point)
uv pip install -e .

kiss --help
kiss version
```

Code edits under `src/kiss_cli/` take effect immediately — no reinstall needed.
Asset edits under `templates/`, `extensions/`, etc. also take effect immediately
because the editable install reads them through `scripts/hatch_build_hooks.py`
at runtime.

## 3. Run the CLI Without Installing

```bash
# From repo root — same entry point as the installed `kiss` command
uv run python -m kiss_cli --help
uv run python -m kiss_cli init demo --integration claude
```

## 4. Invoke via uvx From the Local Tree

```bash
# Simulate what end users get, from the current working tree
uv build
uvx --from . kiss init demo-uvx --integration claude
# Or from an absolute path
uvx --from /absolute/path/to/kiss kiss --help

# Or from a pushed branch
git push origin your-feature-branch
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git@your-feature-branch \
  kiss init demo-branch-test
```

## 5. Rebuild and Reinstall as Global Tool

Use this when you want to test what a wheel install actually looks like (e.g.
reproducing packaging bugs, testing offline behavior):

```bash
# Build wheel + sdist. The hatch hook stages all assets into core_pack/
uv build

# Reinstall the freshly built wheel as a uv tool
uv tool install --force \
  "./dist/kiss-$(grep '^version' pyproject.toml | cut -d'"' -f2)-py3-none-any.whl"

kiss version
```

## 6. Running Tests

The test suite lives under `tests/`. Pytest is not in the default sync set —
install it into the venv once:

```bash
uv pip install pytest
```

Run everything:

```bash
uv run python -m pytest tests/ -q
```

Useful subsets:

```bash
# One integration at a time
uv run python -m pytest tests/integrations/test_integration_claude.py -v

# Just the registry + base-class contracts
uv run python -m pytest tests/integrations/test_registry.py tests/integrations/test_base.py -v

# Stop at the first failure, show local variables
uv run python -m pytest tests/ -x -l

# Run a specific test by name
uv run python -m pytest tests/ -k "test_setup_copies_shared_templates"
```

The integration suite uses shared `MarkdownIntegrationTests`,
`TomlIntegrationTests`, and `SkillsIntegrationTests` base classes under
`tests/integrations/` — see [§11](#11-add-support-for-a-new-ai-integration) for
how to reuse them.

## 7. Develop a New Extension

### What Extensions Do

Extensions are the primary mechanism for adding new commands (and optionally
lifecycle hooks) on top of the kiss core without touching core code. Each
extension is a self-contained directory that the `kiss extension` commands
install, remove, and upgrade within a project.

**Key capabilities:**

- **New commands** — every command in `commands/` becomes a named
  `kiss.<extension-id>.<command>` prompt registered into each AI agent's
  folder (`.claude/commands/`, `.gemini/commands/`, `.github/agents/`, …).
- **Lifecycle hooks** — an extension can declare `hooks:` in its
  `extension.yml` to run one of its commands automatically before or after a
  core kiss command (e.g. `after_kiss-taskify`).
- **Configuration** — `config-template.yml` is copied into the project at
  install time as `.kiss/extensions/<id>/<id>-config.yml`, giving the
  extension a project-local settings file.
- **Scripts** — optional `.sh` / `.ps1` scripts in `scripts/` can be
  invoked by command prompts for structured, cross-platform automation.

Extensions are **project-scoped**: they land in `.kiss/extensions/` and the
relevant AI agent directories and are never global. They are distributed via
catalog entries (upstream, community, or org-level) or directly via URL /
local path.

### 7.1 Scaffold from the template

```bash
# Copy the template into a new extension directory
cp -R extensions/template extensions/my-extension
```

Every extension has this layout:

```text
extensions/my-extension/
├── extension.yml          # Descriptor: id, version, commands, hooks, config
├── config-template.yml    # Default config copied into a project on install
├── commands/              # Command prompt files (.md with YAML frontmatter)
│   └── example.md
├── scripts/               # Optional: helper .sh / .ps1 scripts
└── README.md
```

### 7.2 Edit `extension.yml`

At minimum update `extension.id`, `name`, `version`, `description`, and the
`provides.commands` list. Command names must follow the
`kiss.<extension-id>.<command>` convention so they don't collide with core or
other extensions. See the annotated [template extension.yml](../extensions/template/extension.yml)
for every field.

### 7.3 Register in the bundled catalog (optional)

If your extension should ship **in the core wheel** (like `git`), add an entry
to [extensions/catalog.json](../extensions/catalog.json):

```json
"my-extension": {
  "id": "my-extension",
  "name": "My Extension",
  "version": "1.0.0",
  "description": "What it does",
  "author": "Dau Quang Thanh",
  "repository": "https://github.com/DauQuangThanh/kiss-u",
  "bundled": true,
  "tags": ["workflow"]
}
```

Community extensions live in separate repos and are discovered via user-added
catalogs (`kiss extension catalog add …`) — they don't need a core catalog
entry.

### 7.4 Try it in a sandbox project

```bash
# Create a throwaway project
mkdir /tmp/ext-test && cd /tmp/ext-test
kiss init . --integration claude
# Install from your local checkout (--dev mounts instead of copying)
kiss extension add my-extension \
  --from /absolute/path/to/kiss/extensions/my-extension --dev

# Verify command files landed in the agent folder
ls .claude/skills/        # or .github/prompts/, depending on the agent
cat .kiss/extensions/my-extension/my-extension-config.yml
```

Remove, tweak, reinstall:

```bash
kiss extension remove my-extension --force
# edit extensions/my-extension/...
kiss extension add my-extension --from /abs/path/.../extensions/my-extension --dev
```

### 7.5 Test the extension

Add a file under `tests/extensions/<your-ext>/` mirroring
[tests/extensions/git/](../tests/extensions/git/). The key assertions:

- `extension.yml` parses and declares the expected commands
- `install_from_directory` writes all command files and the config template
- Removal cleans up everything that was written

Run just your extension's tests:

```bash
uv run python -m pytest tests/extensions/my-extension/ -v
```

## 8. Develop a New Workflow

### What Workflows Do

Workflows are multi-step, resumable automation pipelines defined in YAML. They
orchestrate kiss commands across integrations, evaluate control flow, and pause
at human review gates — enabling end-to-end Spec-Driven Development cycles
without manually running each command in sequence.

**Key capabilities:**

- **Sequential orchestration** — a workflow runs kiss commands one after
  another, passing outputs as inputs to later steps, so a full SDD cycle
  (`specify → plan → taskify → implement`) can be triggered with a single
  `kiss workflow run` call.
- **Human review gates** — `gate` steps pause execution and wait for
  `kiss workflow resume` before continuing, letting humans review and approve
  artefacts mid-flight.
- **Control flow** — `if`, `switch`, `while`, `do-while`, `fan-out`, and
  `fan-in` steps enable conditional branching, loops, and parallelism.
- **Shell steps** — run arbitrary shell commands and capture their output as
  step results available to later steps via `{{ steps.<id>.output.* }}`.
- **Resume on interruption** — state is persisted after each step, so a
  workflow that is interrupted (power loss, gate pause, CI timeout) can be
  resumed from exactly where it stopped with `kiss workflow resume <run_id>`.
- **Expression engine** — `{{ inputs.name }}`, `{{ steps.plan.output.file }}`,
  and standard filters (`default`, `join`, `contains`, `map`) are available
  everywhere a value is expected in a workflow definition.
- **Catalog discovery** — workflows are distributed via catalog entries
  (upstream, community, or org-level) or directly from a local YAML file with
  `kiss workflow run ./my-workflow.yml`.

Workflows are **project-scoped**: installed definitions live in
`.kiss/workflows/<id>/workflow.yml`; run state is written to
`.kiss/workflows/runs/<run_id>/`.

For the full step-type reference and architecture, see
[workflows/ARCHITECTURE.md](../workflows/ARCHITECTURE.md) and
[workflows/README.md](../workflows/README.md).

### 8.1 Create a workflow definition

A workflow is a single YAML file. The `workflows/kiss/workflow.yml` shipped
with the core wheel is a good starting template:

```yaml
schema_version: "1.0"

workflow:
  id: "my-workflow"            # lowercase alphanumeric + hyphens
  name: "My Workflow"
  version: "1.0.0"
  author: "Your Name"
  description: "One-sentence description"
  integration: claude          # default integration (optional)

requires:
  kiss_version: ">=0.2.0"
  integrations:
    any: ["claude", "gemini", "copilot"]

inputs:
  spec:
    type: string
    required: true
    prompt: "Describe what you want to build"
  scope:
    type: string
    default: "full"
    enum: ["full", "backend-only", "frontend-only"]

steps:
  - id: specify
    command: kiss.specify
    input:
      args: "{{ inputs.spec }}"

  - id: review-spec
    type: gate
    message: "Review the spec before planning."
    options: [approve, reject]
    on_reject: abort

  - id: plan
    command: kiss.plan
    input:
      args: "{{ inputs.spec }}"
```

**Step ID rules:**

- Must be unique within the workflow.
- Must not contain `:` (reserved for engine-generated nested IDs such as
  `parentId:childId`).

### 8.2 Validate and run locally

```bash
# Run directly from a local YAML file — no install needed
kiss workflow run ./my-workflow.yml \
  --input spec="Build a user authentication system"

# Check run status
kiss workflow status

# Resume after a gate pause
kiss workflow resume <run_id>
```

### 8.3 Register in the bundled catalog (optional)

To ship with the core wheel, place your YAML under `workflows/<id>/` and add
an entry to [workflows/catalog.json](../workflows/catalog.json):

```json
"my-workflow": {
  "id": "my-workflow",
  "name": "My Workflow",
  "version": "1.0.0",
  "description": "What it does",
  "author": "Your Name",
  "url": "https://github.com/DauQuangThanh/kiss-u/raw/main/workflows/my-workflow/workflow.yml",
  "tags": ["sdd"]
}
```

The build hook picks up `workflows/` automatically — no `pyproject.toml` edits
required. Community workflows don't need a core catalog entry; they're
installed via `kiss workflow add <id> --from <url-or-path>`.

### 8.4 Modify an existing workflow

The built-in `kiss` workflow lives at
[workflows/kiss/workflow.yml](../workflows/kiss/workflow.yml). To modify it for
local experimentation:

1. Copy the YAML to a new directory: `cp -R workflows/kiss workflows/my-kiss`.
2. Edit the copy — change step inputs, add steps, adjust gate messages.
3. Run from the local copy:
   `kiss workflow run ./workflows/my-kiss/workflow.yml --input spec="…"`.
4. Install into a project for persistent use:
   `kiss workflow add my-kiss --from ./workflows/my-kiss`.

> **Do not edit `workflows/kiss/workflow.yml` directly for local tests** —
> it is the upstream authoritative definition and changes will be overwritten
> on the next build. Use a copy as shown above.

### 8.5 Integrate the workflow into a project

```bash
# Install from the catalog (once published)
kiss workflow add my-workflow

# Install from a local directory
kiss workflow add my-workflow --from ./workflows/my-workflow

# Run the installed workflow
kiss workflow run my-workflow --input spec="Build a user authentication system"

# List installed workflows
kiss workflow list

# Remove a workflow
kiss workflow remove my-workflow
```

### 8.6 Test the workflow

Workflow unit tests live under `tests/workflows/`. At minimum assert that:

- The YAML parses and schema-validates.
- Required inputs are detected as required.
- Step IDs are unique and follow naming rules.
- The engine reaches the expected terminal state for a representative input.

```bash
uv run python -m pytest tests/workflows/ -v
```

For step-level testing of new step types, add a module under
`tests/workflows/steps/` following the pattern in the existing step tests.

---

## 9. Develop a New Preset

### What Presets Do

Presets are stackable, priority-ordered collections of **template overrides**
and **command overrides** that change how the SDD workflow produces artefacts —
without forking core code or writing new commands. They are the right tool for
compliance-heavy spec formats, methodology tweaks, team standards, or different
language output.

**Key capabilities:**

- **Template overrides** — replace core templates (`spec-template.md`,
  `plan-template.md`, `standards-template.md`, etc.) with custom variants.
  Overrides are applied **at runtime**: kiss walks a resolution stack
  (`overrides/ → presets/ → extensions/ → core`) and returns the first match.
- **Command overrides** — replace the LLM instructions for core commands such
  as `kiss.specify` or `kiss.plan`. Command overrides are applied **at install
  time**: the preset's command files are registered into each detected AI agent
  directory (`.claude/commands/`, `.gemini/commands/`, etc.) in the correct
  format.
- **Priority stacking** — multiple presets can be installed simultaneously.
  The `--priority` flag controls precedence (lower number = higher precedence),
  so an organization-wide base layer can be overridden by a project-specific
  one.
- **No new commands** — presets customise existing commands and templates;
  they do not add new `kiss.*` commands. Use an extension when you need new
  commands.

Presets are **project-scoped**: they land in `.kiss/presets/<id>/` and are
never global. They are distributed via catalog entries or directly from a local
directory / URL.

See [presets/ARCHITECTURE.md](../presets/ARCHITECTURE.md) for the resolution
and command-registration internals.

### 9.1 Scaffold from `scaffold`

```bash
cp -R presets/scaffold presets/my-preset
```

Layout:

```text
presets/my-preset/
├── preset.yml         # Descriptor: id, version, what templates/commands it replaces
├── commands/          # Command overrides (replace core kiss.<command> files)
├── templates/         # Template overrides (spec-template.md, plan-template.md, etc.)
└── README.md
```

### 9.2 Edit `preset.yml`

Each `provides.templates` entry names **what it replaces** (`kiss.specify`,
`spec-template`, …) and points at the override file. Copy a working example
from [presets/lean/preset.yml](../presets/lean/preset.yml) and adjust.

### 9.3 Register in the bundled catalog (optional)

To ship with the core wheel, add an entry to
[presets/catalog.json](../presets/catalog.json). Community presets don't need
this — they're installed via `kiss preset add <name> --from <url-or-path>`.

### 9.4 Try it in a sandbox project

```bash
mkdir /tmp/preset-test && cd /tmp/preset-test
kiss init . --integration claude
# Install your local preset
kiss preset add my-preset --from /abs/path/to/kiss/presets/my-preset

# Verify the overridden files
cat .kiss/presets/my-preset/commands/kiss.specify.md
ls .claude/skills/kiss-specify/   # should contain your override
```

Or install it straight from `kiss init` without the two-step dance:

```bash
kiss init /tmp/preset-test --integration claude \
  --preset /abs/path/to/kiss/presets/my-preset
```

### 9.5 Test the preset

The preset test machinery lives in [tests/test_presets.py](../tests/test_presets.py).
For a new preset, at minimum assert that:

- `preset.yml` parses and declares the expected overrides
- `install_from_directory` writes overrides to the right skill/command paths
- `remove()` restores the core template
- Priority stacking resolves correctly when another preset overrides the same
  command

```bash
uv run python -m pytest tests/test_presets.py -v
```

## 10. Develop a New Role Skill

### What Role Skills Do

Role skills are the prompt bundles that power KISS's 14 custom agents
(architect, tester, devops, ux-designer, …). Each skill is a self-contained
directory under `agent-skills/kiss-<name>/` that the `kiss init` installer
copies into the AI agent's skill folder (e.g. `.claude/skills/`,
`.github/skills/`).

**Key capabilities:**

- **Agentskills.io-compliant prompt** — the root `kiss-<name>.md` file is the
  skill entrypoint, following the [agentskills.io](https://agentskills.io)
  specification so it is portable across any compliant AI platform.
- **Templates** — Markdown document templates in `templates/` define the
  shape of artefacts the skill writes (specs, ADRs, test cases, etc.).
- **References** — rubrics, glossaries, and lookup tables in `references/`
  are loaded at runtime so the agent doesn't need to embed them in the prompt.
- **Cross-platform scripts** — `scripts/bash/` and `scripts/powershell/` each
  contain a `common.sh` / `common.ps1` (shared helpers: `read_context`,
  `write_decision`, `append_debt`, etc.) plus per-action scripts that the
  prompt invokes.
- **Two execution modes** — every skill supports `interactive` (ask + confirm
  before each write) and `auto` (fill in defaults, record decisions to
  `docs/agent-decisions/`).
- **Offline, no new commands** — role skills do not add new `kiss.*` slash
  commands; they operate through the agent's native invocation
  (`@architect`, `@tester`, etc.). Use an extension when you need a new
  `kiss.*` command.

Role skills are **AI authoring aids only**: they draft artefacts, ask the
human for input, and honour `preferences.confirm_before_write`. They do not
facilitate meetings, interview stakeholders, approve changes, or communicate
with third parties.

### 10.1 Copy the scaffold

```bash
cp -R agent-skills/_template agent-skills/kiss-my-skill
mv agent-skills/kiss-my-skill/_template.md \
   agent-skills/kiss-my-skill/kiss-my-skill.md
```

`agent-skills/_template/` is developer-only scaffolding. The build
hook and compliance tests skip any folder whose name starts with
`_`, so the template is never shipped to end-users.

Layout every role-skill follows:

```text
agent-skills/kiss-my-skill/
├── kiss-my-skill.md        # agentskills.io-compliant prompt
├── templates/              # markdown templates the skill writes
├── references/             # rubrics, glossaries, loaded at runtime
├── assets/                 # non-markdown support (images, diagrams, YAML starters)
└── scripts/
    ├── bash/
    │   ├── common.sh       # shared helpers — copied verbatim from _template
    │   └── <action>.sh
    └── powershell/
        ├── common.ps1
        └── <action>.ps1
```

### 10.2 Wire it up

1. Update the `name:` field in the frontmatter to match the folder.
2. In the prompt body, reference scripts via
   `<SKILL_DIR>/kiss-my-skill/scripts/bash/<action>.sh` (the
   `<SKILL_DIR>` legend is already in the template's Usage section).
3. Every action script starts with `source "$SCRIPT_DIR/common.sh"`.
   `common.sh` ships with `read_context`, `worktype_dir`,
   `feature_scoped_dir`, `append_debt`, `write_decision`,
   `write_extract`, `resolve_auto`, `confirm_before_write`, and
   `kiss_parse_standard_args`. Do **not** edit `common.sh` per-skill;
   update it in `_template/` and re-copy to all skills if a helper
   needs changing.
4. Add the skill's bare command name (e.g. `my-skill`) to
   `_FALLBACK_CORE_COMMAND_NAMES` in
   [src/kiss_cli/extensions.py](../src/kiss_cli/extensions.py) so
   the compliance test
   `test_core_command_names_match_bundled_templates` stays green.
5. Cite the skill in the relevant agent under
   `subagents/<agent>.md`.

### 10.3 Artefact locations

Write outputs under `{context.paths.docs}/<work-type>/`
(project-scoped) or `{context.paths.docs}/<work-type>/<feature>/`
(feature-scoped). Work-type directories are a fixed convention —
see the table in the [Role Agents section of the
README](../README.md#-role-agents). Add a `<prefix>-debts.md`
alongside each work-type directory for the debt register.

### 10.4 Conform to the AI-only scope

Every role agent and skill is an AI authoring aid. Prompts must
not imply the AI conducts meetings, interviews stakeholders,
approves change requests, or communicates with third parties. Use
the `does` / `does not` pattern from any existing role agent as a
reference; every agent also carries a `## Modes` section that
distinguishes `interactive` (default, ask+confirm) from `auto`
(fill in defaults, record decisions).

### 10.5 Test

```bash
# Structural tests (bundle layout, script parity, common-source)
uv run python -m pytest tests/test_skill_bundle_layout.py -q

# Runtime helpers (read_context, write_decision, etc.)
uv run python -m pytest tests/test_skill_common_helpers.py -q

# Full suite
uv run python -m pytest tests/ -q
```

### 10.6 Smoke-test in a scratch project

```bash
tmp=$(mktemp -d) && cd "$tmp"
mkdir -p .kiss
cat > .kiss/context.yml <<'YAML'
paths: { docs: docs }
current: { feature: demo }
preferences: { confirm_before_write: false }
YAML
bash /abs/path/to/kiss/agent-skills/kiss-my-skill/scripts/bash/<action>.sh --auto
find docs
```

In `auto` mode, invoking with `KISS_AGENT=<agent-name>
KISS_AGENT_MODE=auto` causes the skill's `write_decision` calls to
log to `docs/agent-decisions/<agent-name>/<date>-decisions.md`.

## 11. Add Support for a New AI Integration

### What AI Integrations Do

An integration tells kiss how to install commands, custom agents, and the
project context file into a specific AI tool's directory layout. Adding one
makes `kiss init --integration <key>` and `kiss upgrade` work for that tool.

**Key responsibilities of an integration class:**

- **Directory layout** — declares where kiss writes command files
  (`registrar_config.dir`), what format it uses (`markdown` or `toml`), and
  where custom agents land (`config.agents_subdir`).
- **Context file** — specifies the root-level file that injects project
  context into the AI tool (e.g. `CLAUDE.md`, `GEMINI.md`, `.cursorrules`).
- **Capability flags** — `supports_argument_hints`, `supports_handoffs`, and
  `supports_multi_context_files` gate optional features per tool.
- **CLI dispatch** — if the tool has a non-interactive CLI, implementing
  `build_exec_args()` enables `kiss workflow run` to dispatch commands
  programmatically to that tool.

Integrations are **registered globally** in
`src/kiss_cli/integrations/__init__.py` (not project-scoped) and are bundled
into the wheel. A correctly implemented integration is picked up by the full
test suite automatically via parametrized registry tests.

kiss currently ships 14 integrations, registered in
[src/kiss_cli/integrations/\_\_init\_\_.py](../src/kiss_cli/integrations/__init__.py).
The inheritance hierarchy (one of these is your parent class):

- `MarkdownIntegration` — plain `.md` command files (Claude, Windsurf, Kilo Code, …)
- `TomlIntegration` — `.toml` command files with `description` + `prompt` (Gemini, Tabnine)
- `SkillsIntegration` — `kiss-<name>/SKILL.md` directory layout (Claude skills, Codex, Agy, Cursor)
- `IntegrationBase` — roll your own when the tool doesn't fit the above (Copilot variants)

### 11.1 Create the package

Python package directories can't have hyphens, so a key like `my-agent` becomes
a directory `my_agent/`. The `key` attribute stays hyphenated.

```bash
mkdir src/kiss_cli/integrations/my_agent
```

### 11.2 Implement the class

Minimal markdown-style example:

```python
# src/kiss_cli/integrations/my_agent/__init__.py
"""My Agent integration."""

from ..base import MarkdownIntegration


class MyAgentIntegration(MarkdownIntegration):
    # Capability flags — be explicit, no implicit inheritance
    supports_argument_hints = True
    supports_handoffs = False
    supports_multi_context_files = False

    key = "my-agent"
    config = {
        "name": "My Agent",
        "folder": ".myagent/",
        "skills_subdir": "commands",
        # subagents (subagents) installed by `kiss init` land at
        # ``<folder>/<agents_subdir>/``. Omit this key to use the default
        # ``"agents"``; set to ``"workflows"`` (Antigravity) or ``None``
        # (Generic — opts out of custom-agent install entirely).
        "agents_subdir": "agents",
        "install_url": "https://example.com/my-agent",
        "requires_cli": True,   # False for IDE-only agents
    }

    registrar_config = {
        "dir": ".myagent/commands",
        "format": "markdown",       # or "toml"
        "args": "$ARGUMENTS",       # how the agent receives user input
        "extension": ".md",
    }
    context_file = "MYAGENT.md"     # Root-level or nested, per the tool's convention
```

For a skills-based agent, extend `SkillsIntegration` and set `"extension":
"/SKILL.md"` in `registrar_config`. For TOML, extend `TomlIntegration` and set
`"format": "toml"`, `"args": "{{args}}"`.

### 11.3 Register the integration

Add imports and `_register(...)` calls to
[src/kiss_cli/integrations/\_\_init\_\_.py](../src/kiss_cli/integrations/__init__.py)
(alphabetical imports, registration order drives UI listing):

```python
from .my_agent import MyAgentIntegration
...
_register(MyAgentIntegration())
```

### 11.4 Add a catalog entry

Add a block for `my-agent` in [integrations/catalog.json](../integrations/catalog.json)
so it appears in `kiss integration list`.

### 11.5 Document it

- Add a row to [docs/reference/integrations.md](reference/integrations.md).
- Add a row to the matrix in
  [AI-Agents-Configs.md](../AI-Agents-Configs.md) — project config folder,
  context file, skills directory, and the tool's native subagents directory.
- If the agent has a CLI that supports non-interactive dispatch, implement
  `build_exec_args()` and add it to the "CLI-dispatch integrations" list in
  `AI-Agents-Configs.md`.
- Add the integration name to the dropdowns in
  [.github/ISSUE_TEMPLATE/bug_report.yml](../.github/ISSUE_TEMPLATE/bug_report.yml),
  [.github/ISSUE_TEMPLATE/feature_request.yml](../.github/ISSUE_TEMPLATE/feature_request.yml),
  and [.github/ISSUE_TEMPLATE/agent_request.yml](../.github/ISSUE_TEMPLATE/agent_request.yml).

### 11.6 Test the integration

Create `tests/integrations/test_integration_my_agent.py`. For common formats,
subclass the appropriate base — most integrations need only a few class-level
constants:

```python
# Markdown agent
from .test_integration_base_markdown import MarkdownIntegrationTests

class TestMyAgentIntegration(MarkdownIntegrationTests):
    KEY = "my-agent"
    FOLDER = ".myagent/"
    COMMANDS_SUBDIR = "commands"
    REGISTRAR_DIR = ".myagent/commands"
    CONTEXT_FILE = "MYAGENT.md"
```

TOML and Skills agents have analogous base classes
(`TomlIntegrationTests`, `SkillsIntegrationTests`) under
`tests/integrations/`.

Registry contract checks live in
[tests/integrations/test_registry.py](../tests/integrations/test_registry.py)
— they run parametrized over every registered key, so a correctly registered
integration is picked up automatically.

Run your tests plus the registry/base contracts:

```bash
uv run python -m pytest \
  tests/integrations/test_integration_my_agent.py \
  tests/integrations/test_registry.py \
  tests/integrations/test_base.py -v
```

### 11.7 End-to-end smoke test

```bash
mkdir /tmp/my-agent-test && cd /tmp/my-agent-test
kiss init . --integration my-agent
ls .myagent/commands/    # should contain kiss.*.md files
cat MYAGENT.md           # should contain the <!-- KISS START --> block
```

## 12. Rapid Edit Loop Summary

| Action                         | Command                                                                              |
| ------------------------------ | ------------------------------------------------------------------------------------ |
| Run CLI without install        | `uv run python -m kiss_cli --help`                                                   |
| Editable install               | `uv pip install -e .` then `kiss ...`                                                |
| Local uvx run                  | `uvx --from . kiss ...`                                                              |
| Branch uvx run                 | `uvx --from git+URL@branch kiss ...`                                                 |
| Build wheel                    | `uv build`                                                                           |
| Reinstall global tool          | `uv tool install --force ./dist/kiss-<ver>-py3-none-any.whl`                         |
| Run all tests                  | `uv run python -m pytest tests/ -q`                                                  |
| Run one test file              | `uv run python -m pytest tests/integrations/test_integration_claude.py -v`           |
| Dev-install local extension    | `kiss extension add <id> --from /abs/path --dev`                                     |
| Install local preset at init   | `kiss init . --integration claude --preset /abs/path/to/preset`                      |
| Run workflow from local YAML   | `kiss workflow run ./my-workflow.yml --input spec="…"`                               |
| Install local workflow         | `kiss workflow add my-workflow --from ./workflows/my-workflow`                        |
| Resume paused workflow         | `kiss workflow resume <run_id>`                                                       |

## 13. Cleaning Up

```bash
rm -rf .venv dist build *.egg-info
```

`core_pack/` is regenerated by the build hook; wiping it between builds is
safe and sometimes needed to surface stale-asset bugs.

## 14. Common Issues

| Symptom                                          | Fix                                                                                                                   |
| ------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `ModuleNotFoundError: typer`                     | `uv pip install -e .` or `uv sync`                                                                                    |
| `No module named 'kiss_cli.cli.extensions'`      | You're on an older wheel — rebuild and reinstall (see §5)                                                             |
| New extension not discovered by `search`         | Confirm `extensions/catalog.json` was updated and rebuilt, **or** add a user catalog with `kiss extension catalog add`|
| New integration missing from `kiss init` list    | Confirm it's registered in `src/kiss_cli/integrations/__init__.py` and imported at module load time                   |
| Scripts not executable on Linux                  | Re-run `kiss init`, or `find <agent-folder>/skills -name '*.sh' -exec chmod +x {} +`                                  |
| Asset edits not reflected in installed CLI       | You're running the wheel. Either use the editable install (§2) or rebuild and reinstall (§5)                          |
| TLS errors on corporate network                  | Configure `SSL_CERT_FILE` / `HTTPS_PROXY`. The old `--skip-tls` flag is a deprecated no-op                            |
| Workflow run not resuming                        | Check `kiss workflow status` for the `run_id`; state is saved under `.kiss/workflows/runs/<run_id>/state.json`         |
| Workflow step fails with unknown command         | Confirm the extension/core command is installed and the `kiss.*` name matches exactly                                  |
| New workflow not found by `kiss workflow search` | Confirm `workflows/catalog.json` was updated and rebuilt, **or** install directly with `--from <path>`                |
| Preset override not taking effect                | Run `kiss preset resolve <template-name>` to see which file wins the resolution stack                                  |

## 15. Next Steps

- Open a PR with your changes (do **not** push to `main` directly)
- Request review from a maintainer
- After merge, a maintainer will tag a release — the release pipeline ships
  wheel + sdist + `SHA256SUMS`
