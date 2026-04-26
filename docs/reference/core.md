# Core Commands

The core `kiss` commands handle project initialization, system checks, and version information.

## Initialize a Project

```bash
kiss init [<project_name>]
```

| Option                   | Description                                                              |
| ------------------------ | ------------------------------------------------------------------------ |
| `--integration <key>` | AI coding agent integration to use (e.g. `claude`, `copilot`, `gemini`). Can be specified multiple times to install multiple integrations. Without this flag, kiss presents an interactive multi-select checklist. See the [Integrations reference](integrations.md) for all available keys |
| `--integration-options` | Options for the integration (e.g. `--integration-options="--commands-dir .myagent/cmds"`). Pass with the matching `--integration` flag |
| `--here`                 | Initialize in the current directory instead of creating a new one        |
| `--force`                | Force merge/overwrite when initializing in an existing directory         |
| `--no-git`               | Skip git repository initialization                                       |
| `--ignore-agent-tools`   | Skip checks for AI coding agent CLI tools                                |
| `--preset <id>`          | Install a preset during initialization                                   |
| `--branch-numbering`     | Branch numbering strategy: `sequential` (default) or `timestamp`         |

Creates a new kiss project with the necessary directory structure, templates, scripts, and AI coding agent integration files. By default, presents a multi-select checklist to choose integrations; Claude is pre-selected. You can specify integrations non-interactively with `--integration`.

Use `<project_name>` to create a new directory, or `--here` (or `.`) to initialize in the current directory. If the directory already has files, use `--force` to merge without confirmation. The context file `.kiss/context.yml` is created with paths, current state, and preferences configuration.

### Examples

```bash
# Create a new project (interactive multi-select for integrations)
kiss init my-project

# Install with specific integrations
kiss init my-project --integration claude

# Install multiple integrations
kiss init my-project --integration claude --integration copilot

# Initialize in the current directory
kiss init --here

# Force merge into a non-empty directory
kiss init --here --force

# Skip git initialization
kiss init my-project --integration claude --no-git

# Install a preset during initialization
kiss init my-project --integration claude --preset compliance

# Use timestamp-based branch numbering (useful for distributed teams)
kiss init my-project --integration claude --branch-numbering timestamp
```

### Environment Variables

| Variable          | Description                                                              |
| ----------------- | ------------------------------------------------------------------------ |
| `KISS_FEATURE` | Override feature detection for non-Git repositories. Set to the feature directory name (e.g., `001-photo-albums`) to work on a specific feature when not using Git branches. Must be set in the context of the agent prior to using `/kiss-plan` or follow-up commands. |

## Check Installed Tools

```bash
kiss check
```

Checks that required tools are available on your system: `git` and any CLI-based AI coding agents. IDE-based agents are skipped since they don't require a CLI tool.

## Version Information

```bash
kiss version
```

Displays the kiss CLI version, Python version, platform, and architecture.

A quick version check is also available via:

```bash
kiss --version
kiss -V
```
