# Extension Development Guide

A guide for creating kiss extensions.

---

## Quick Start

### 1. Create Extension Directory

```bash
mkdir my-extension
cd my-extension
```

### 2. Create `extension.yml` Manifest

```yaml
schema_version: "1.0"

extension:
  id: "my-ext"                          # Lowercase, alphanumeric + hyphens only
  name: "My Extension"
  version: "1.0.0"                      # Semantic versioning
  description: "My custom extension"
  author: "Your Name"
  repository: "https://github.com/you/kiss-my-ext"
  license: "MIT"

requires:
  kiss_version: ">=0.1.0"            # Minimum kiss version
  tools:                                # Optional: External tools required
    - name: "my-tool"
      required: true
      version: ">=1.0.0"
  commands:                             # Optional: Core commands needed
    - "kiss.taskify"

provides:
  commands:
    - name: "kiss.my-ext.hello"      # Must follow pattern: kiss.{ext-id}.{cmd}
      file: "commands/hello.md"
      description: "Say hello"
      aliases: ["kiss.my-ext.hi"]    # Optional aliases, same pattern

  config:                               # Optional: Config files
    - name: "my-ext-config.yml"
      template: "my-ext-config.template.yml"
      description: "Extension configuration"
      required: false

hooks:                                  # Optional: Integration hooks
  after_kiss-taskify:
    command: "kiss.my-ext.hello"
    optional: true
    prompt: "Run hello command?"

tags:                                   # Optional: For catalog search
  - "example"
  - "utility"
```

### 3. Create Commands Directory

```bash
mkdir commands
```

### 4. Create Command File

**File**: `commands/hello.md`

```markdown
---
description: "Say hello command"
tools:                              # Optional: AI tools this command uses
  - 'some-tool/function'
scripts:                            # Optional: Helper scripts
  sh: ../../scripts/bash/helper.sh
  ps: ../../scripts/powershell/helper.ps1
---

# Hello Command

This command says hello!

## User Input

$ARGUMENTS

## Steps

1. Greet the user
2. Show extension is working

```bash
echo "Hello from my extension!"
echo "Arguments: $ARGUMENTS"
```

## Extension Configuration

Load extension config from `.kiss/extensions/my-ext/my-ext-config.yml`.

### 5. Test Locally

```bash
cd /path/to/kiss-project
kiss extension add --dev /path/to/my-extension
```

### 6. Verify Installation

```bash
kiss extension list

# Should show:
#  ✓ My Extension (v1.0.0)
#     My custom extension
#     Commands: 1 | Hooks: 1 | Status: Enabled
```

### 7. Test Command

If using Claude:

```bash
claude
> /kiss.my-ext.hello world
```

The command will be available in `.claude/commands/kiss.my-ext.hello.md`.

---

## Manifest Schema Reference

### Required Fields

#### `schema_version`

Extension manifest schema version. Currently: `"1.0"`

#### `extension`

Extension metadata block.

**Required sub-fields**:

- `id`: Extension identifier (lowercase, alphanumeric, hyphens)
- `name`: Human-readable name
- `version`: Semantic version (e.g., "1.0.0")
- `description`: Short description

**Optional sub-fields**:

- `author`: Extension author
- `repository`: Source code URL
- `license`: SPDX license identifier
- `homepage`: Extension homepage URL

#### `requires`

Compatibility requirements.

**Required sub-fields**:

- `kiss_version`: Semantic version specifier (e.g., ">=0.1.0,<2.0.0")

**Optional sub-fields**:

- `tools`: External tools required (array of tool objects)
- `commands`: Core kiss commands needed (array of command names)
- `scripts`: Core scripts required (array of script names)

#### `provides`

What the extension provides.

**Optional sub-fields**:

- `commands`: Array of command objects (at least one command or hook is required)

**Command object**:

- `name`: Command name (must match `kiss.{ext-id}.{command}`)
- `file`: Path to command file (relative to extension root)
- `description`: Command description (optional)
- `aliases`: Alternative command names (optional, array; each must match `kiss.{ext-id}.{command}`)

### Optional Fields

#### `hooks`

Integration hooks for automatic execution.

Available hook points (kiss namespace):

- `before_kiss-specify` / `after_kiss-specify`: Before/after specification generation
- `before_kiss-plan` / `after_kiss-plan`: Before/after implementation planning
- `before_kiss-taskify` / `after_kiss-taskify`: Before/after task generation
- `before_kiss-implement` / `after_kiss-implement`: Before/after implementation
- `before_kiss-verify-tasks` / `after_kiss-verify-tasks`: Before/after cross-artifact analysis
- `before_kiss-checklist` / `after_kiss-checklist`: Before/after checklist generation
- `before_kiss-clarify-specs` / `after_kiss-clarify-specs`: Before/after spec clarification
- `before_kiss-standardize` / `after_kiss-standardize`: Before/after standards update
- `before_kiss-tasks-to-issues` / `after_kiss-tasks-to-issues`: Before/after tasks-to-issues conversion

> **Note:** Legacy hook names (e.g., `before_specify`, `after_plan`) are no longer supported and will raise a validation error. Use the `kiss-` prefixed names above.

Hook object:

- `command`: Command to execute (typically from `provides.commands`, but can reference any registered command)
- `optional`: If true, prompt user before executing
- `prompt`: Prompt text for optional hooks
- `description`: Hook description
- `condition`: Execution condition (future)

#### `tags`

Array of tags for catalog discovery.

#### `defaults`

Default extension configuration values.

#### `config_schema`

JSON Schema for validating extension configuration.

---

## Command File Format

### Frontmatter (YAML)

```yaml
---
description: "Command description"          # Required
tools:                                      # Optional
  - 'tool-name/function'
scripts:                                    # Optional
  sh: ../../scripts/bash/helper.sh
  ps: ../../scripts/powershell/helper.ps1
---
```

### Body (Markdown)

Use standard Markdown with special placeholders:

- `$ARGUMENTS`: User-provided arguments
- `{SCRIPT}`: Replaced with script path during registration

**Example**:

````markdown
## Steps

1. Parse arguments
2. Execute logic

```bash
args="$ARGUMENTS"
echo "Running with args: $args"
```
````

### Script Path Rewriting

Extension commands use relative paths that get rewritten during registration:

**In extension**:

```yaml
scripts:
  sh: ../../scripts/bash/helper.sh
```

**After registration**:

```yaml
scripts:
  sh: .kiss/scripts/bash/helper.sh
```

This allows scripts to reference core kiss scripts.

---

## Configuration Files

### Config Template

**File**: `my-ext-config.template.yml`

```yaml
# My Extension Configuration
# Copy this to my-ext-config.yml and customize

# Example configuration
api:
  endpoint: "https://api.example.com"
  timeout: 30

features:
  feature_a: true
  feature_b: false

credentials:
  # DO NOT commit credentials!
  # Use environment variables instead
  api_key: "${MY_EXT_API_KEY}"
```

### Config Loading

In your command, load config with layered precedence:

1. Extension defaults (`extension.yml` → `defaults`)
2. Project config (`.kiss/extensions/my-ext/my-ext-config.yml`)
3. Local overrides (`.kiss/extensions/my-ext/my-ext-config.local.yml` - gitignored)
4. Environment variables (`KISS_MY_EXT_*`)

**Example loading script**:

```bash
#!/usr/bin/env bash
EXT_DIR=".kiss/extensions/my-ext"

# Load and merge config
config=$(yq eval '.' "$EXT_DIR/my-ext-config.yml" -o=json)

# Apply env overrides
if [ -n "${KISS_MY_EXT_API_KEY:-}" ]; then
  config=$(echo "$config" | jq ".api.api_key = \"$KISS_MY_EXT_API_KEY\"")
fi

echo "$config"
```

---

## Excluding Files with `.extensionignore`

Extension authors can create a `.extensionignore` file in the extension root to exclude files and folders from being copied when a user installs the extension with `kiss extension add`. This is useful for keeping development-only files (tests, CI configs, docs source, etc.) out of the installed copy.

### Format

The file uses `.gitignore`-compatible patterns (one per line), powered by the [`pathspec`](https://pypi.org/project/pathspec/) library:

- Blank lines are ignored
- Lines starting with `#` are comments
- `*` matches anything **except** `/` (does not cross directory boundaries)
- `**` matches zero or more directories (e.g., `docs/**/*.draft.md`)
- `?` matches any single character except `/`
- A trailing `/` restricts a pattern to directories only
- Patterns containing `/` (other than a trailing slash) are anchored to the extension root
- Patterns without `/` match at any depth in the tree
- `!` negates a previously excluded pattern (re-includes a file)
- Backslashes in patterns are normalised to forward slashes for cross-platform compatibility
- The `.extensionignore` file itself is always excluded automatically

### Example

```gitignore
# .extensionignore

# Development files
tests/
.github/
.gitignore

# Build artifacts
__pycache__/
*.pyc
dist/

# Documentation source (keep only the built README)
docs/
CONTRIBUTING.md
```

### Pattern Matching

| Pattern | Matches | Does NOT match |
|---------|---------|----------------|
| `*.pyc` | Any `.pyc` file in any directory | — |
| `tests/` | The `tests` directory (and all its contents) | A file named `tests` |
| `docs/*.draft.md` | `docs/api.draft.md` (directly inside `docs/`) | `docs/sub/api.draft.md` (nested) |
| `.env` | The `.env` file at any level | — |
| `!README.md` | Re-includes `README.md` even if matched by an earlier pattern | — |
| `docs/**/*.draft.md` | `docs/api.draft.md`, `docs/sub/api.draft.md` | — |

### Unsupported Features

The following `.gitignore` features are **not applicable** in this context:

- **Multiple `.extensionignore` files**: Only a single file at the extension root is supported (`.gitignore` supports files in subdirectories)
- **`$GIT_DIR/info/exclude` and `core.excludesFile`**: These are Git-specific and have no equivalent here
- **Negation inside excluded directories**: Because file copying uses `shutil.copytree`, excluding a directory prevents recursion into it entirely. A negation pattern cannot re-include a file inside a directory that was itself excluded. For example, the combination `tests/` followed by `!tests/important.py` will **not** preserve `tests/important.py` — the `tests/` directory is skipped at the root level and its contents are never evaluated. To work around this, exclude the directory's contents individually instead of the directory itself (e.g., `tests/*.pyc` and `tests/.cache/` rather than `tests/`).

---

## Validation Rules

### Extension ID

- **Pattern**: `^[a-z0-9-]+$`
- **Valid**: `my-ext`, `tool-123`, `awesome-plugin`
- **Invalid**: `MyExt` (uppercase), `my_ext` (underscore), `my ext` (space)

### Extension Version

- **Format**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Valid**: `1.0.0`, `0.1.0`, `2.5.3`
- **Invalid**: `1.0`, `v1.0.0`, `1.0.0-beta`

### Command Name

- **Pattern**: `^kiss\.[a-z0-9-]+\.[a-z0-9-]+$`
- **Valid**: `kiss.my-ext.hello`, `kiss.tool.cmd`
- **Invalid**: `my-ext.hello` (missing prefix), `kiss.hello` (no extension namespace)

### Command File Path

- **Must be** relative to extension root
- **Valid**: `commands/hello.md`, `commands/subdir/cmd.md`
- **Invalid**: `/absolute/path.md`, `../outside.md`

---

## Testing Extensions

### Manual Testing

1. **Create test extension**
2. **Install locally**:

   ```bash
   kiss extension add --dev /path/to/extension
   ```

3. **Verify installation**:

   ```bash
   kiss extension list
   ```

4. **Test commands** with your AI agent
5. **Check command registration**:

   ```bash
   ls .claude/commands/kiss.my-ext.*
   ```

6. **Remove extension**:

   ```bash
   kiss extension remove my-ext
   ```

### Automated Testing

Create tests for your extension:

```python
# tests/test_my_extension.py
import pytest
from pathlib import Path
from kiss_cli.extensions import ExtensionManifest

def test_manifest_valid():
    """Test extension manifest is valid."""
    manifest = ExtensionManifest(Path("extension.yml"))
    assert manifest.id == "my-ext"
    assert len(manifest.commands) >= 1

def test_command_files_exist():
    """Test all command files exist."""
    manifest = ExtensionManifest(Path("extension.yml"))
    for cmd in manifest.commands:
        cmd_file = Path(cmd["file"])
        assert cmd_file.exists(), f"Command file not found: {cmd_file}"
```

---

## Distribution

### Option 1: GitHub Repository

1. **Create repository**: `kiss-my-ext`
2. **Add files**:

   ```text
   kiss-my-ext/
   ├── extension.yml
   ├── commands/
   ├── scripts/
   ├── docs/
   ├── README.md
   ├── LICENSE
   └── CHANGELOG.md
   ```

3. **Create release**: Tag with version (e.g., `v1.0.0`)
4. **Install from repo**:

   ```bash
   git clone https://github.com/you/kiss-my-ext
   kiss extension add --dev kiss-my-ext/
   ```

### Option 2: ZIP Archive (Future)

Create ZIP archive and host on GitHub Releases:

```bash
zip -r kiss-my-ext-1.0.0.zip extension.yml commands/ scripts/ docs/
```

Users install with:

```bash
kiss extension add <extension-name> --from https://github.com/.../kiss-my-ext-1.0.0.zip
```

### Option 3: Community Reference Catalog

Submit to the community catalog for public discovery:

1. **Fork** kiss repository
2. **Add entry** to `extensions/catalog.community.json`
3. **Update** the Community Extensions table in `README.md` with your extension
4. **Create PR** following the [Extension Publishing Guide](EXTENSION-PUBLISHING-GUIDE.md)
5. **After merge**, your extension becomes available:
   - Users can browse `catalog.community.json` to discover your extension
   - Users copy the entry to their own `catalog.json`
   - Users install with: `kiss extension add my-ext` (from their catalog)

See the [Extension Publishing Guide](EXTENSION-PUBLISHING-GUIDE.md) for detailed submission instructions.

---

## Best Practices

### Naming Conventions

- **Extension ID**: Use descriptive, hyphenated names (`jira-integration`, not `ji`)
- **Commands**: Use verb-noun pattern (`create-issue`, `sync-status`)
- **Config files**: Match extension ID (`jira-config.yml`)

### Documentation

- **README.md**: Overview, installation, usage
- **CHANGELOG.md**: Version history
- **docs/**: Detailed guides
- **Command descriptions**: Clear, concise

### Versioning

- **Follow SemVer**: `MAJOR.MINOR.PATCH`
- **MAJOR**: Breaking changes
- **MINOR**: New features
- **PATCH**: Bug fixes

### Security

- **Never commit secrets**: Use environment variables
- **Validate input**: Sanitize user arguments
- **Document permissions**: What files/APIs are accessed

### Compatibility

- **Specify version range**: Don't require exact version
- **Test with multiple versions**: Ensure compatibility
- **Graceful degradation**: Handle missing features

---

## Example Extensions

### Minimal Extension

Smallest possible extension:

```yaml
# extension.yml
schema_version: "1.0"
extension:
  id: "minimal"
  name: "Minimal Extension"
  version: "1.0.0"
  description: "Minimal example"
requires:
  kiss_version: ">=0.1.0"
provides:
  commands:
    - name: "kiss.minimal.hello"
      file: "commands/hello.md"
```

````markdown
<!-- commands/hello.md -->
---
description: "Hello command"
---

# Hello World

```bash
echo "Hello, $ARGUMENTS!"
```
````

### Extension with Config

Extension using configuration:

```yaml
# extension.yml
# ... metadata ...
provides:
  config:
    - name: "tool-config.yml"
      template: "tool-config.template.yml"
      required: true
```

```yaml
# tool-config.template.yml
api_endpoint: "https://api.example.com"
timeout: 30
```

````markdown
<!-- commands/use-config.md -->
# Use Config

Load config:
```bash
config_file=".kiss/extensions/tool/tool-config.yml"
endpoint=$(yq eval '.api_endpoint' "$config_file")
echo "Using endpoint: $endpoint"
```
````

### Extension with Hooks

Extension that runs automatically:

```yaml
# extension.yml
hooks:
  after_taskify:
    command: "kiss.auto.analyze"
    optional: false  # Always run
    description: "Analyze tasks after generation"
```

---

## Troubleshooting

### Extension won't install

**Error**: `Invalid extension ID`

- **Fix**: Use lowercase, alphanumeric + hyphens only

**Error**: `Extension requires kiss >=0.2.0`

- **Fix**: Update kiss with `uv tool install kiss --force`

**Error**: `Command file not found`

- **Fix**: Ensure command files exist at paths specified in manifest

### Commands not registered

**Symptom**: Commands don't appear in AI agent

**Check**:

1. `.claude/commands/` directory exists
2. Extension installed successfully
3. Commands registered in registry:

   ```bash
   cat .kiss/extensions/.registry
   ```

**Fix**: Reinstall extension to trigger registration

### Config not loading

**Check**:

1. Config file exists: `.kiss/extensions/{ext-id}/{ext-id}-config.yml`
2. YAML syntax is valid: `yq eval '.' config.yml`
3. Environment variables set correctly

---

## Getting Help

- **Issues**: Report bugs at GitHub repository
- **Discussions**: Ask questions in GitHub Discussions
- **Examples**: See `kiss-jira` for full-featured example (Phase B)

---

## Next Steps

1. **Create your extension** following this guide
2. **Test locally** with `--dev` flag
3. **Share with community** (GitHub, catalog)
4. **Iterate** based on feedback

Happy extending! 🚀

---

## Hook Lifecycle

The hook system allows extensions to execute commands automatically at defined points in the kiss workflow. Each hook fires at a specific lifecycle event and receives the context from that event.

### Supported Hook Phases

Hook phase names follow the pattern: `(before|after)_kiss-<skill-name>`

| Hook Phase | Trigger Condition |
|------------|-------------------|
| `before_kiss-standardize` | Fires immediately before the standardize skill runs |
| `after_kiss-standardize` | Fires immediately after the standardize skill completes |
| `before_kiss-specify` | Fires immediately before the specify skill runs |
| `after_kiss-specify` | Fires immediately after the specify skill completes |
| `before_kiss-clarify-specs` | Fires immediately before the clarify skill runs |
| `after_kiss-clarify-specs` | Fires immediately after the clarify skill completes |
| `before_kiss-plan` | Fires immediately before the plan skill runs |
| `after_kiss-plan` | Fires immediately after the plan skill completes |
| `before_kiss-taskify` | Fires immediately before the taskify skill runs |
| `after_kiss-taskify` | Fires immediately after the taskify skill completes |
| `before_kiss-implement` | Fires immediately before the implement skill runs |
| `after_kiss-implement` | Fires immediately after the implement skill completes |
| `before_kiss-checklist` | Fires immediately before the checklist skill runs |
| `after_kiss-checklist` | Fires immediately after the checklist skill completes |
| `before_kiss-verify-tasks` | Fires immediately before the analyze skill runs |
| `after_kiss-verify-tasks` | Fires immediately after the analyze skill completes |
| `before_kiss-tasks-to-issues` | Fires immediately before the tasks-to-issues skill runs |
| `after_kiss-tasks-to-issues` | Fires immediately after the tasks-to-issues skill completes |

### Hook Configuration Example

```yaml
hooks:
  before_kiss-plan:
    command: "kiss.my-ext.validate-spec"
    optional: true
    prompt: "Validate spec before planning?"
    description: "Run custom validation before planning"
  
  after_kiss-implement:
    command: "kiss.my-ext.deploy"
    optional: false
    description: "Auto-deploy after implementation"
```

---

## Migrating from spec-kit Extensions

If you have an extension built for spec-kit, follow these steps to migrate to kiss:

### 1. Update Hook Phase Names

Hook phases have been renamed to use the `kiss-` prefix. Update all hook names in your `extension.yml`:

| Old Name | New Name |
|----------|----------|
| `before_standardize` | `before_kiss-standardize` |
| `after_standardize` | `after_kiss-standardize` |
| `before_specify` | `before_kiss-specify` |
| `after_specify` | `after_kiss-specify` |
| `before_clarify-specs` | `before_kiss-clarify-specs` |
| `after_clarify-specs` | `after_kiss-clarify-specs` |
| `before_plan` | `before_kiss-plan` |
| `after_plan` | `after_kiss-plan` |
| `before_taskify` | `before_kiss-taskify` |
| `after_taskify` | `after_kiss-taskify` |
| `before_implement` | `before_kiss-implement` |
| `after_implement` | `after_kiss-implement` |
| `before_checklist` | `before_kiss-checklist` |
| `after_checklist` | `after_kiss-checklist` |
| `before_verify-tasks` | `before_kiss-verify-tasks` |
| `after_verify-tasks` | `after_kiss-verify-tasks` |
| `before_tasks-to-issues` | `before_kiss-tasks-to-issues` |
| `after_tasks-to-issues` | `after_kiss-tasks-to-issues` |

### 2. What About Deprecated Hook Names?

During the transition period, kiss will accept old hook names (e.g., `before_specify`) but will emit deprecation warnings. Your extension will continue to work, but you should update the names.

Example deprecation warning:

```text
Extension 'my-ext' uses deprecated hook phase 'before_specify'. This will be removed in a future release. Rename to 'before_kiss-specify'.
```

### 3. Update Command References

Ensure that command references in hook definitions use the full canonical form:

**Before (old format)**:

```yaml
hooks:
  after_taskify:
    command: "my-ext.hello"  # Short form
```

**After (new format)**:

```yaml
hooks:
  after_kiss-taskify:
    command: "kiss.my-ext.hello"  # Canonical form
```

### 4. Timeline

- **Current release**: Old hook names accepted with deprecation warnings
- **Future release (TBD)**: Old hook names will no longer be accepted
