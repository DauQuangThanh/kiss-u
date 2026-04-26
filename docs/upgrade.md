# Upgrade Guide

> You have kiss installed and want to upgrade to the latest version to get new features, bug fixes, or updated slash commands. This guide covers both upgrading the CLI tool and updating your project files.

---

## Quick Reference

| What to Upgrade | Command | When to Use |
|----------------|---------|-------------|
| **CLI Tool Only** | `uv tool install kiss --force --from git+https://github.com/DauQuangThanh/kiss-u.git` | Get latest CLI features without touching project files |
| **Project Files** | `kiss init --here --force --ai <your-agent>` | Update slash commands, templates, and scripts in your project |
| **Both** | Run CLI upgrade, then project update | Recommended for major version updates |

---

## Part 1: Upgrade the CLI Tool

The CLI tool (`kiss`) is separate from your project files. Upgrade it to get the latest features and bug fixes.

### If you installed with `uv tool install`

Upgrade to a specific release (check [Releases](https://github.com/DauQuangThanh/kiss-u/releases) for the latest tag):

```bash
uv tool install kiss --force --from git+https://github.com/DauQuangThanh/kiss-u.git
```

### If you use one-shot `uvx` commands

Specify the desired release tag:

```bash
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git kiss init --here --ai copilot
```

### Verify the upgrade

```bash
kiss version
```

This shows the installed version of kiss. You can also run `kiss check` to verify project health.

---

## Part 2: Updating Project Files

When kiss releases new features (like new slash commands or updated templates), you can refresh your project's kiss files using `kiss upgrade`. This command re-applies bundled assets without fetching from GitHub — all assets are already included in your installed kiss package.

### Run kiss upgrade

```bash
kiss upgrade
```

This updates templates, commands, and scripts in your project to match the currently installed kiss version. It does not remove or overwrite your existing specifications, plans, or tasks — only the framework files.

### What gets updated?

Running `kiss init --here --force` will update:

- ✅ **Installed skill folders** (e.g. `.claude/skills/kiss-specify/`) — each skill is rewritten as a unit (SKILL.md + bundled `scripts/` + `templates/`). Without `--force`, only missing skills/files are added; existing ones are skipped with a warning.
- ✅ **Agent context files** (`CLAUDE.md`, `GEMINI.md`, `.cursor/rules/kiss-rules.mdc`, etc.) — the managed section between `<!-- KISS START -->` / `<!-- KISS END -->` is refreshed.

### What stays safe?

These files are **never touched** by the upgrade—the template packages don't even contain them:

- ✅ **Your standards file** (`docs/standards.md`) - **CONFIRMED SAFE**
- ✅ **Your specifications** (`docs/specs/001-my-feature/spec.md`, etc.) - **CONFIRMED SAFE**
- ✅ **Your implementation plans** (`docs/plans/001-my-feature/plan.md`, `tasks.md`, etc.) - **CONFIRMED SAFE**
- ✅ **Your source code** - **CONFIRMED SAFE**
- ✅ **Your git history** - **CONFIRMED SAFE**

The `docs/` directory is completely excluded from template packages and will never be modified during upgrades.

### Update command

Run this inside your project directory:

```bash
kiss init --here --force --ai <your-agent>
```

Replace `<your-agent>` with your AI coding agent. Refer to this list of [Supported AI Coding Agent Integrations](reference/integrations.md)

**Example:**

```bash
kiss init --here --force --ai copilot
```

### Understanding the `--force` flag

Without `--force`, the CLI warns you and asks for confirmation:

```text
Warning: Current directory is not empty (25 items)
Template files will be merged with existing content and may overwrite existing files
Proceed? [y/N]
```

With `--force`, it skips the confirmation and proceeds immediately. It also **overwrites installed skill folders** (e.g. `.claude/skills/kiss-specify/`) — SKILL.md and the bundled `scripts/` and `templates/` inside each skill — with the latest versions from the installed kiss release.

Without `--force`, shared infrastructure files that already exist are skipped — the CLI will print a warning listing the skipped files so you know which ones were not updated.

**Important: Your `docs/` directory is always safe.** The `--force` flag only affects template files (commands, scripts, templates). Your standards, feature specifications, plans, and tasks under `docs/` are never included in upgrade packages and cannot be overwritten.

---

## ⚠️ Important Warnings

### 1. Custom script or template modifications

Each installed skill bundles its own copy of scripts and templates (e.g. `.claude/skills/kiss-specify/scripts/` and `.claude/skills/kiss-specify/templates/`). If you edited any of those, `--force` will overwrite them. Back them up first:

```bash
# Back up a specific skill before upgrading
cp -r .claude/skills/kiss-specify .claude/skills/kiss-specify.backup

# Or back up every installed skill at once
cp -r .claude/skills /tmp/claude-skills-backup

# After upgrade, merge your changes back manually
```

### 2. Duplicate slash commands (IDE-based agents)

Some IDE-based agents (like Windsurf) may show **duplicate slash commands** after upgrading---both old and new versions appear.

**Solution:** Manually delete the old command files from your agent's folder.

**Example for Windsurf:**

```bash
# Navigate to the agent's commands folder
cd .windsurf/skills/

# List files and identify duplicates
ls -la

# Delete old versions (example filenames - yours may differ)
rm kiss.specify-old.md
rm kiss.plan-v1.md
```

Restart your IDE to refresh the command list.

---

## Common Scenarios

### Scenario 1: "I just want new slash commands"

```bash
# Upgrade CLI (if using persistent install)
uv tool install kiss --force --from git+https://github.com/DauQuangThanh/kiss-u.git

# Update project files to get new commands
kiss init --here --force --ai copilot
```

Your `docs/standards.md` is preserved across upgrades — no restore step needed.

### Scenario 2: "I customized skill templates or scripts"

```bash
# 1. Back up customizations (every installed skill folder)
cp -r .claude/skills /tmp/claude-skills-backup

# 2. Upgrade CLI
uv tool install kiss --force --from git+https://github.com/DauQuangThanh/kiss-u.git

# 3. Update project
kiss init --here --force --ai copilot

# 4. Manually merge template changes back
```

### Scenario 3: "I see duplicate slash commands in my IDE"

This happens with IDE-based agents (Windsurf, Cursor, etc.).

```bash
# Find the agent folder (example: .windsurf/skills/)
cd .windsurf/skills/

# List all files
ls -la

# Delete old command files
rm kiss.old-command-name.md

# Restart your IDE
```

### Scenario 4: "I'm working on a project without Git"

If you initialized your project with `--no-git`, you can still upgrade:

```bash
# Run upgrade
kiss init --here --force --ai copilot --no-git
```

Your `docs/` directory (standards, specs, plans, tasks) is preserved. The `--no-git` flag skips git initialization but doesn't affect file updates.

---

## Using `--no-git` Flag

The `--no-git` flag tells kiss to **skip git repository initialization**. This is useful when:

- You manage version control differently (Mercurial, SVN, etc.)
- Your project is part of a larger monorepo with existing git setup
- You're experimenting and don't want version control yet

**During initial setup:**

```bash
kiss init my-project --ai copilot --no-git
```

**During upgrade:**

```bash
kiss init --here --force --ai copilot --no-git
```

### What `--no-git` does NOT do

❌ Does NOT prevent file updates
❌ Does NOT skip slash command installation
❌ Does NOT affect template merging

It **only** skips running `git init` and creating the initial commit.

### Working without Git

If you use `--no-git`, you'll need to manage feature directories manually:

**Set the `KISS_FEATURE` environment variable** before using planning commands:

```bash
# Bash/Zsh
export KISS_FEATURE="001-my-feature"

# PowerShell
$env:KISS_FEATURE = "001-my-feature"
```

This tells kiss which feature directory to use when creating specs, plans, and tasks.

**Why this matters:** Without git, kiss can't detect your current branch name to determine the active feature. The environment variable provides that context manually.

---

## Troubleshooting

### "Slash commands not showing up after upgrade"

**Cause:** Agent didn't reload the command files.

**Fix:**

1. **Restart your IDE/editor** completely (not just reload window)
2. **For CLI-based agents**, verify files exist:

   ```bash
   ls -la .claude/skills/        # Claude Code
   ls -la .gemini/commands/      # Gemini
   ls -la .cursor/skills/        # Cursor
   ```

3. **Check agent-specific setup:**
   - Codex requires `CODEX_HOME` environment variable
   - Some agents need workspace restart or cache clearing

### "Warning: Current directory is not empty"

**Full warning message:**

```text
Warning: Current directory is not empty (25 items)
Template files will be merged with existing content and may overwrite existing files
Do you want to continue? [y/N]
```

**What this means:**

This warning appears when you run `kiss init --here` (or `kiss init .`) in a directory that already has files. It's telling you:

1. **The directory has existing content** - In the example, 25 files/folders
2. **Files will be merged** - New template files will be added alongside your existing files
3. **Some files may be overwritten** - If you already have kiss files (`.claude/`, `.kiss/`, etc.), they'll be replaced with the new versions

**What gets overwritten:**

Only kiss infrastructure files:

- Installed skill folders (e.g. `.claude/skills/kiss-specify/` — SKILL.md + bundled `scripts/` + `templates/`)
- Agent context files (`CLAUDE.md`, `GEMINI.md`, `.cursor/rules/kiss-rules.mdc`, etc.) — only the managed section between the `<!-- KISS START -->` / `<!-- KISS END -->` markers

**What stays untouched:**

- Your `docs/` directory (standards, specifications, plans, tasks)
- Your source code files
- Your `.git/` directory and git history
- Any other files not part of kiss templates

**How to respond:**

- **Type `y` and press Enter** - Proceed with the merge (recommended if upgrading)
- **Type `n` and press Enter** - Cancel the operation
- **Use `--force` flag** - Skip this confirmation entirely:

  ```bash
  kiss init --here --force --ai copilot
  ```

**When you see this warning:**

- ✅ **Expected** when upgrading an existing kiss project
- ✅ **Expected** when adding kiss to an existing codebase
- ⚠️ **Unexpected** if you thought you were creating a new project in an empty directory

**Prevention tip:** Before upgrading, commit any local customizations to the installed skill folders (e.g. `.claude/skills/<name>/`) — the SKILL.md and bundled scripts/templates inside each skill folder can be overwritten with `--force`.

### "CLI upgrade doesn't seem to work"

Verify the installation:

```bash
# Check installed tools
uv tool list

# Should show kiss

# Verify path
which specify

# Should point to the uv tool installation directory
```

If not found, reinstall:

```bash
uv tool uninstall kiss
uv tool install kiss --from git+https://github.com/DauQuangThanh/kiss-u.git
```

### "Do I need to run specify every time I open my project?"

**Short answer:** No, you only run `kiss init` once per project (or when upgrading).

**Explanation:**

The `kiss` CLI tool is used for:

- **Initial setup:** `kiss init` to bootstrap kiss in your project
- **Upgrades:** `kiss init --here --force` to update templates and commands
- **Diagnostics:** `kiss check` to verify tool installation

Once you've run `kiss init`, the slash commands (like `/kiss-specify`, `/kiss-plan`, etc.) are **permanently installed** in your project's agent folder (`.claude/`, `.github/prompts/`, etc.). Your AI coding agent reads these command files directly—no need to run `kiss` again.

**If your agent isn't recognizing slash commands:**

1. **Verify command files exist:**

   ```bash
   # For GitHub Copilot
   ls -la .github/skills/

   # For Claude
   ls -la .claude/skills/
   ```

2. **Restart your IDE/editor completely** (not just reload window)

3. **Check you're in the correct directory** where you ran `kiss init`

4. **For some agents**, you may need to reload the workspace or clear cache

**Related issue:** If Copilot can't open local files or uses PowerShell commands unexpectedly, this is typically an IDE context issue, not related to `kiss`. Try:

- Restarting VS Code
- Checking file permissions
- Ensuring the workspace folder is properly opened

---

## Version Compatibility

kiss follows semantic versioning for major releases. The CLI and project files are designed to be compatible within the same major version.

**Best practice:** Keep both CLI and project files in sync by upgrading both together during major version changes.

---

## Next Steps

After upgrading:

- **Test new slash commands:** Run `/kiss-standardize` or another command to verify everything works
- **Review release notes:** Check [GitHub Releases](https://github.com/DauQuangThanh/kiss-u/releases) for new features and breaking changes
- **Update workflows:** If new commands were added, update your team's development workflows
- **Check documentation:** Visit [github.io/kiss](https://github.github.io/kiss/) for updated guides
