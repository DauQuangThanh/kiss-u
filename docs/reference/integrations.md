# Supported AI Coding Agent Integrations

The kiss supports a wide range of AI coding agents. When you run `kiss init`, the CLI sets up the appropriate command files, context rules, and directory structures for your chosen AI coding agent — so you can start using Spec-Driven Development immediately, regardless of which tool you prefer.

## Supported AI Coding Agents

| Agent                                                                                | Key              | Notes                                                                                                                                     |
| ------------------------------------------------------------------------------------ | ---------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| [Claude Code](https://www.anthropic.com/claude-code)                                 | `claude`         | Skills-based integration; installs skills in `.claude/skills`                                                                              |
| [GitHub Copilot](https://code.visualstudio.com/)                                     | `copilot`        |                                                                                                                                           |
| [Cursor](https://cursor.sh/)                                                         | `cursor-agent`   |                                                                                                                                           |
| [opencode](https://opencode.ai/)                                                     | `opencode`       |                                                                                                                                           |
| [Windsurf](https://windsurf.com/)                                                    | `windsurf`       |                                                                                                                                           |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli)                            | `gemini`         |                                                                                                                                           |
| [Codex CLI](https://github.com/openai/codex)                                         | `codex`          | Skills-based integration; installs skills into `.agents/skills` and invokes them as `$kiss-<command>` |

## List Available Integrations

```bash
kiss integration list
```

Shows all available integrations, which one is currently installed, and whether each requires a CLI tool or is IDE-based.

## Install an Integration

```bash
kiss integration install <key>
```

| Option                   | Description                                                              |
| ------------------------ | ------------------------------------------------------------------------ |
| `--integration-options`  | Integration-specific options (e.g. `--integration-options="--commands-dir .myagent/cmds"`) |

Installs the specified integration into the current project. Fails if another integration is already installed — use `switch` instead. If the installation fails partway through, it automatically rolls back to a clean state.

> **Note:** All integration management commands require a project already initialized with `kiss init`. To start a new project with a specific agent, use `kiss init <project> --integration <key>` instead.

## Uninstall an Integration

```bash
kiss integration uninstall [<key>]
```

| Option    | Description                                         |
| --------- | --------------------------------------------------- |
| `--force` | Remove files even if they have been modified         |

Uninstalls the current integration (or the specified one). kiss tracks every file created during install along with a SHA-256 hash of the original content:

- **Unmodified files** are removed automatically.
- **Modified files** (where you've made manual edits) are preserved so your customizations are not lost.
- Use `--force` to remove all integration files regardless of modifications.

## Switch to a Different Integration

```bash
kiss integration switch <key>
```

| Option                   | Description                                                              |
| ------------------------ | ------------------------------------------------------------------------ |
| `--force`                | Force removal of modified files during uninstall                         |
| `--integration-options`  | Options for the target integration                                       |

Equivalent to running `uninstall` followed by `install` in a single step.

## Upgrade an Integration

```bash
kiss integration upgrade [<key>]
```

| Option                   | Description                                                              |
| ------------------------ | ------------------------------------------------------------------------ |
| `--force`                | Overwrite files even if they have been modified                          |
| `--integration-options`  | Options for the integration                                              |

Reinstalls the current integration with updated templates and commands (e.g., after upgrading kiss). Defaults to the currently installed integration; if a key is provided, it must match the installed one — otherwise the command fails and suggests using `switch` instead. Detects locally modified files and blocks the upgrade unless `--force` is used. Stale files from the previous install that are no longer needed are removed automatically.

## FAQ

### Can I use multiple integrations at the same time?

Yes. During `kiss init`, you can select multiple integrations via an interactive multi-select checklist, or specify them non-interactively with multiple `--integration` flags. You can manage multiple integrations with `kiss integration install`, `kiss integration uninstall`, and `kiss integration upgrade`.

### What happens to my changes when I uninstall or switch?

Files you've modified are preserved automatically. Only unmodified files (matching their original SHA-256 hash) are removed. Use `--force` to override this.

### How do I know which key to use?

Run `kiss integration list` to see all available integrations with their keys, or check the [Supported AI Coding Agents](#supported-ai-coding-agents) table above.

### Do I need the AI coding agent installed to use an integration?

CLI-based integrations (like Claude Code, Gemini CLI) require the tool to be installed. IDE-based integrations (like Windsurf, Cursor, GitHub Copilot for VS Code) work through the IDE itself. `kiss integration list` shows which type each integration is.

### When should I use `upgrade` vs `switch`?

Use `upgrade` when you've upgraded kiss and want to refresh the same integration's templates. Use `switch` when you want to change to a different AI coding agent.
