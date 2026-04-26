# Extension User Guide

Complete guide for using kiss extensions to enhance your workflow.

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Finding Extensions](#finding-extensions)
4. [Installing Extensions](#installing-extensions)
5. [Using Extensions](#using-extensions)
6. [Managing Extensions](#managing-extensions)
7. [Configuration](#configuration)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

---

## Introduction

### What are Extensions?

Extensions are modular packages that add new commands and functionality to kiss without bloating the core framework. They allow you to:

- **Integrate** with external tools (Jira, Linear, GitHub, etc.)
- **Automate** repetitive tasks with hooks
- **Customize** workflows for your team
- **Share** solutions across projects

### Why Use Extensions?

- **Clean Core**: Keeps kiss lightweight and focused
- **Optional Features**: Only install what you need
- **Community Driven**: Anyone can create and share extensions
- **Version Controlled**: Extensions are versioned independently

---

## Getting Started

### Prerequisites

- kiss version 0.1.0 or higher
- A kiss project (directory with `.kiss/` folder)

### Check Your Version

```bash
specify version
# Should show 0.1.0 or higher
```

### First Extension

Let's install the Jira extension as an example:

```bash
# 1. Search for the extension
kiss extension search jira

# 2. Get detailed information
kiss extension info jira

# 3. Install it
kiss extension add jira

# 4. Configure it
vim .kiss/extensions/jira/jira-config.yml

# 5. Use it
# (Commands are now available in Claude Code)
/kiss.jira.specstoissues
```

---

## Finding Extensions

`kiss extension search` searches **all active catalogs** simultaneously, including the community catalog by default. Results are annotated with their source catalog and install status.

### Browse All Extensions

```bash
kiss extension search
```

Shows all extensions across all active catalogs (default and community by default).

### Search by Keyword

```bash
# Search for "jira"
kiss extension search jira

# Search for "issue tracking"
kiss extension search issue
```

### Filter by Tag

```bash
# Find all issue-tracking extensions
kiss extension search --tag issue-tracking

# Find all Atlassian tools
kiss extension search --tag atlassian
```

### Filter by Author

```bash
# Extensions by Stats Perform
kiss extension search --author "Stats Perform"
```

### Show Verified Only

```bash
# Only show verified extensions
kiss extension search --verified
```

### Get Extension Details

```bash
# Detailed information
kiss extension info jira
```

Shows:

- Description
- Requirements
- Commands provided
- Hooks available
- Links (documentation, repository, changelog)
- Installation status

---

## Installing Extensions

### Install from Catalog

```bash
# By name (from catalog)
kiss extension add jira
```

This will:

1. Download the extension from GitHub
2. Validate the manifest
3. Check compatibility with your kiss version
4. Install to `.kiss/extensions/jira/`
5. Register commands with your AI agent
6. Create config template

### Install from URL

```bash
# From GitHub release
kiss extension add <extension-name> --from https://github.com/org/kiss-ext/archive/refs/tags/v1.0.0.zip
```

### Install from Local Directory (Development)

```bash
# For testing or development
kiss extension add --dev /path/to/extension
```

### Installation Output

```text
✓ Extension installed successfully!

Jira Integration (v1.0.0)
  Create Jira Epics, Stories, and Issues from kiss artifacts

Provided commands:
  • kiss.jira.specstoissues - Create Jira hierarchy from spec and tasks
  • kiss.jira.discover-fields - Discover Jira custom fields for configuration
  • kiss.jira.sync-status - Sync task completion status to Jira

⚠  Configuration may be required
   Check: .kiss/extensions/jira/
```

### Automatic Agent Skill Registration

If your project was initialized with `--ai-skills`, extension commands are **automatically registered as agent skills** during installation. This ensures that extensions are discoverable by agents that use the [agentskills.io](https://agentskills.io) skill specification.

```text
✓ Extension installed successfully!

Jira Integration (v1.0.0)
  ...

✓ 3 agent skill(s) auto-registered
```

When an extension is removed, its corresponding skills are also cleaned up automatically. Pre-existing skills that were manually customized are never overwritten.

---

## Using Extensions

### Using Extension Commands

Extensions add commands that appear in your AI agent (Claude Code):

```text
# In Claude Code
> /kiss.jira.specstoissues

# Or use a namespaced alias (if provided)
> /kiss.jira.sync
```

### Extension Configuration

Most extensions require configuration:

```bash
# 1. Find the config file
ls .kiss/extensions/jira/

# 2. Copy template to config
cp .kiss/extensions/jira/jira-config.template.yml \
   .kiss/extensions/jira/jira-config.yml

# 3. Edit configuration
vim .kiss/extensions/jira/jira-config.yml

# 4. Use the extension
# (Commands will now work with your config)
```

### Extension Hooks

Some extensions provide hooks that execute after core commands:

**Example**: Jira extension hooks into `/kiss.taskify`

```text
# Run core command
> /kiss.taskify

# Output includes:
## Extension Hooks

**Optional Hook**: jira
Command: `/kiss.jira.specstoissues`
Description: Automatically create Jira hierarchy after task generation

Prompt: Create Jira issues from tasks?
To execute: `/kiss.jira.specstoissues`
```

You can then choose to run the hook or skip it.

---

## Managing Extensions

### List Installed Extensions

```bash
kiss extension list
```

Output:

```text
Installed Extensions:

  ✓ Jira Integration (v1.0.0)
     Create Jira Epics, Stories, and Issues from kiss artifacts
     Commands: 3 | Hooks: 1 | Status: Enabled
```

### Update Extensions

```bash
# Check for updates (all extensions)
kiss extension update

# Update specific extension
kiss extension update jira
```

Output:

```text
🔄 Checking for updates...

Updates available:

  • jira: 1.0.0 → 1.1.0

Update these extensions? [y/N]:
```

### Disable Extension Temporarily

```bash
# Disable without removing
kiss extension disable jira

✓ Extension 'jira' disabled

Commands will no longer be available. Hooks will not execute.
To re-enable: kiss extension enable jira
```

### Re-enable Extension

```bash
kiss extension enable jira

✓ Extension 'jira' enabled
```

### Remove Extension

```bash
# Remove extension (with confirmation)
kiss extension remove jira

# Keep configuration when removing
kiss extension remove jira --keep-config

# Force removal (no confirmation)
kiss extension remove jira --force
```

---

## Configuration

### Configuration Files

Extensions can have multiple configuration files:

```text
.kiss/extensions/jira/
├── jira-config.yml           # Main config (version controlled)
├── jira-config.local.yml     # Local overrides (gitignored)
└── jira-config.template.yml  # Template (reference)
```

### Configuration Layers

Configuration is merged in this order (highest priority last):

1. **Extension defaults** (from `extension.yml`)
2. **Project config** (`jira-config.yml`)
3. **Local overrides** (`jira-config.local.yml`)
4. **Environment variables** (`KISS_JIRA_*`)

### Example: Jira Configuration

**Project config** (`.kiss/extensions/jira/jira-config.yml`):

```yaml
project:
  key: "MSATS"

defaults:
  epic:
    labels: ["spec-driven"]
```

**Local override** (`.kiss/extensions/jira/jira-config.local.yml`):

```yaml
project:
  key: "MYTEST"  # Override for local development
```

**Environment variable**:

```bash
export KISS_JIRA_PROJECT_KEY="DEVTEST"
```

Final resolved config uses `DEVTEST` from environment variable.

### Project-Wide Extension Settings

File: `.kiss/extensions.yml`

```yaml
# Extensions installed in this project
installed:
  - jira
  - linear

# Global settings
settings:
  auto_execute_hooks: true

# Hook configuration
# Available events: before_specify, after_specify, before_plan, after_plan,
#                   before_taskify, after_taskify, before_implement, after_implement,
#                   before_verify-tasks, after_verify-tasks, before_checklist, after_checklist,
#                   before_clarify-specs, after_clarify-specs, before_standardize, after_standardize,
#                   before_tasks-to-issues, after_tasks-to-issues
hooks:
  after_taskify:
    - extension: jira
      command: kiss.jira.specstoissues
      enabled: true
      optional: true
      prompt: "Create Jira issues from tasks?"
```

### Core Environment Variables

In addition to extension-specific environment variables (`KISS_{EXT_ID}_*`), kiss supports core environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `KISS_CATALOG_URL`       | Override the full catalog stack with a single URL (backward compat) | Built-in default stack |
| `GH_TOKEN` / `GITHUB_TOKEN` | GitHub API token for downloads     | None                  |

#### Example: Using a custom catalog for testing

```bash
# Point to a local or alternative catalog (replaces the full stack)
export KISS_CATALOG_URL="http://localhost:8000/catalog.json"

# Or use a staging catalog
export KISS_CATALOG_URL="https://example.com/staging/catalog.json"
```

---

## Extension Catalogs

kiss uses a **catalog stack** — an ordered list of catalogs searched simultaneously. By default, two catalogs are active:

| Priority | Catalog | Install Allowed | Purpose |
|----------|---------|-----------------|---------|
| 1 | `catalog.json` (default) | ✅ Yes | Curated extensions available for installation |
| 2 | `catalog.community.json` (community) | ❌ No (discovery only) | Browse community extensions |

### Listing Active Catalogs

```bash
kiss extension catalog list
```

### Managing Catalogs via CLI

You can view the main catalog management commands using `--help`:

```text
kiss extension catalog --help

 Usage: kiss extension catalog [OPTIONS] COMMAND [ARGS]...

 Manage extension catalogs
╭─ Options ────────────────────────────────────────────────────────────────────────╮
│ --help          Show this message and exit.                                      │
╰──────────────────────────────────────────────────────────────────────────────────╯
╭─ Commands ───────────────────────────────────────────────────────────────────────╮
│ list     List all active extension catalogs.                                     │
│ add      Add a catalog to .kiss/extension-catalogs.yml.                       │
│ remove   Remove a catalog from .kiss/extension-catalogs.yml.                  │
╰──────────────────────────────────────────────────────────────────────────────────╯
```

### Adding a Catalog (Project-scoped)

```bash
# Add an internal catalog that allows installs
kiss extension catalog add \
  --name "internal" \
  --priority 2 \
  --install-allowed \
  https://internal.company.com/kiss/catalog.json

# Add a discovery-only catalog
kiss extension catalog add \
  --name "partner" \
  --priority 5 \
  https://partner.example.com/kiss/catalog.json
```

This creates or updates `.kiss/extension-catalogs.yml`.

### Removing a Catalog

```bash
kiss extension catalog remove internal
```

### Manual Config File

You can also edit `.kiss/extension-catalogs.yml` directly:

```yaml
catalogs:
  - name: "default"
    url: "https://raw.githubusercontent.com/DauQuangThanh/kiss/main/extensions/catalog.json"
    priority: 1
    install_allowed: true
    description: "Built-in catalog of installable extensions"

  - name: "internal"
    url: "https://internal.company.com/kiss/catalog.json"
    priority: 2
    install_allowed: true
    description: "Internal company extensions"

  - name: "community"
    url: "https://raw.githubusercontent.com/DauQuangThanh/kiss/main/extensions/catalog.community.json"
    priority: 3
    install_allowed: false
    description: "Community-contributed extensions (discovery only)"
```

A user-level equivalent lives at `~/.kiss/extension-catalogs.yml`. Project-level config takes full precedence when it contains one or more catalog entries. An empty `catalogs: []` list falls back to built-in defaults.

## Organization Catalog Customization

### Why Customize Your Catalog

Organizations customize their catalogs to:

- **Control available extensions** - Curate which extensions your team can install
- **Host private extensions** - Internal tools that shouldn't be public
- **Customize for compliance** - Meet security/audit requirements
- **Support air-gapped environments** - Work without internet access

### Setting Up a Custom Catalog

#### 1. Create Your Catalog File

Create a `catalog.json` file with your extensions:

```json
{
  "schema_version": "1.0",
  "updated_at": "2026-02-03T00:00:00Z",
  "catalog_url": "https://your-org.com/kiss/catalog.json",
  "extensions": {
    "jira": {
      "name": "Jira Integration",
      "id": "jira",
      "description": "Create Jira issues from kiss artifacts",
      "author": "Your Organization",
      "version": "2.1.0",
      "download_url": "https://github.com/your-org/kiss-jira/archive/refs/tags/v2.1.0.zip",
      "repository": "https://github.com/your-org/kiss-jira",
      "license": "MIT",
      "requires": {
        "kiss_version": ">=0.1.0",
        "tools": [
          {"name": "atlassian-mcp-server", "required": true}
        ]
      },
      "provides": {
        "commands": 3,
        "hooks": 1
      },
      "tags": ["jira", "atlassian", "issue-tracking"],
      "verified": true
    },
    "internal-tool": {
      "name": "Internal Tool Integration",
      "id": "internal-tool",
      "description": "Connect to internal company systems",
      "author": "Your Organization",
      "version": "1.0.0",
      "download_url": "https://internal.your-org.com/extensions/internal-tool-1.0.0.zip",
      "repository": "https://github.internal.your-org.com/kiss-internal",
      "license": "Proprietary",
      "requires": {
        "kiss_version": ">=0.1.0"
      },
      "provides": {
        "commands": 2
      },
      "tags": ["internal", "proprietary"],
      "verified": true
    }
  }
}
```

#### 2. Host the Catalog

Options for hosting your catalog:

| Method | URL Example | Use Case |
| ------ | ----------- | -------- |
| GitHub Pages | `https://your-org.github.io/kiss-catalog/catalog.json` | Public or org-visible |
| Internal web server | `https://internal.company.com/kiss/catalog.json` | Corporate network |
| S3/Cloud storage | `https://s3.amazonaws.com/your-bucket/catalog.json` | Cloud-hosted teams |
| Local file server | `http://localhost:8000/catalog.json` | Development/testing |

**Security requirement**: URLs must use HTTPS (except `localhost` for testing).

#### 3. Configure Your Environment

##### Option A: Catalog stack config file (recommended)

Add to `.kiss/extension-catalogs.yml` in your project:

```yaml
catalogs:
  - name: "my-org"
    url: "https://your-org.com/kiss/catalog.json"
    priority: 1
    install_allowed: true
```

Or use the CLI:

```bash
kiss extension catalog add \
  --name "my-org" \
  --install-allowed \
  https://your-org.com/kiss/catalog.json
```

##### Option B: Environment variable (recommended for CI/CD, single-catalog)

```bash
# In ~/.bashrc, ~/.zshrc, or CI pipeline
export KISS_CATALOG_URL="https://your-org.com/kiss/catalog.json"
```

#### 4. Verify Configuration

```bash
# List active catalogs
kiss extension catalog list

# Search should now show your catalog's extensions
kiss extension search

# Install from your catalog
kiss extension add jira
```

### Catalog JSON Schema

Required fields for each extension entry:

| Field | Type | Required | Description |
| ----- | ---- | -------- | ----------- |
| `name` | string | Yes | Human-readable name |
| `id` | string | Yes | Unique identifier (lowercase, hyphens) |
| `version` | string | Yes | Semantic version (X.Y.Z) |
| `download_url` | string | Yes | URL to ZIP archive |
| `repository` | string | Yes | Source code URL |
| `description` | string | No | Brief description |
| `author` | string | No | Author/organization |
| `license` | string | No | SPDX license identifier |
| `requires.kiss_version` | string | No | Version constraint |
| `requires.tools` | array | No | Required external tools |
| `provides.commands` | number | No | Number of commands |
| `provides.hooks` | number | No | Number of hooks |
| `tags` | array | No | Search tags |
| `verified` | boolean | No | Verification status |

### Use Cases

#### Private/Internal Extensions

Host proprietary extensions that integrate with internal systems:

```json
{
  "internal-auth": {
    "name": "Internal SSO Integration",
    "download_url": "https://artifactory.company.com/kiss/internal-auth-1.0.0.zip",
    "verified": true
  }
}
```

#### Curated Team Catalog

Limit which extensions your team can install:

```json
{
  "extensions": {
    "jira": { "..." },
    "github": { "..." }
  }
}
```

Only `jira` and `github` will appear in `kiss extension search`.

#### Air-Gapped Environments

For networks without internet access:

1. Download extension ZIPs to internal file server
2. Create catalog pointing to internal URLs
3. Host catalog on internal web server

```json
{
  "jira": {
    "download_url": "https://files.internal/kiss/jira-2.1.0.zip"
  }
}
```

#### Development/Testing

Test new extensions before publishing:

```bash
# Start local server
python -m http.server 8000 --directory ./my-catalog/

# Point kiss to local catalog
export KISS_CATALOG_URL="http://localhost:8000/catalog.json"

# Test installation
kiss extension add my-new-extension
```

### Combining with Direct Installation

You can still install extensions not in your catalog using `--from`:

```bash
# From catalog
kiss extension add jira

# Direct URL (bypasses catalog)
kiss extension add <extension-name> --from https://github.com/someone/kiss-ext/archive/v1.0.0.zip

# Local development
kiss extension add --dev /path/to/extension
```

**Note**: Direct URL installation shows a security warning since the extension isn't from your configured catalog.

---

## Troubleshooting

### Extension Not Found

**Error**: `Extension 'jira' not found in catalog

**Solutions**:

1. Check spelling: `kiss extension search jira`
2. Refresh catalog: `kiss extension search --help`
3. Check internet connection
4. Extension may not be published yet

### Configuration Not Found

**Error**: `Jira configuration not found`

**Solutions**:

1. Check if extension is installed: `kiss extension list`
2. Create config from template:

   ```bash
   cp .kiss/extensions/jira/jira-config.template.yml \
      .kiss/extensions/jira/jira-config.yml
   ```

3. Reinstall extension: `kiss extension remove jira && kiss extension add jira`

### Command Not Available

**Issue**: Extension command not appearing in AI agent

**Solutions**:

1. Check extension is enabled: `kiss extension list`
2. Restart AI agent (Claude Code)
3. Check command file exists:

   ```bash
   ls .claude/commands/kiss.jira.*.md
   ```

4. Reinstall extension

### Incompatible Version

**Error**: `Extension requires kiss >=0.2.0, but you have 0.1.0`

**Solutions**:

1. Upgrade kiss:

   ```bash
   uv tool upgrade kiss
   ```

2. Install older version of extension:

   ```bash
   kiss extension add <extension-name> --from https://github.com/org/ext/archive/v1.0.0.zip
   ```

### MCP Tool Not Available

**Error**: `Tool 'jira-mcp-server/epic_create' not found`

**Solutions**:

1. Check MCP server is installed
2. Check AI agent MCP configuration
3. Restart AI agent
4. Check extension requirements: `kiss extension info jira`

### Permission Denied

**Error**: `Permission denied` when accessing Jira

**Solutions**:

1. Check Jira credentials in MCP server config
2. Verify project permissions in Jira
3. Test MCP server connection independently

---

## Best Practices

### 1. Version Control

**Do commit**:

- `.kiss/extensions.yml` (project extension config)
- `.kiss/extensions/*/jira-config.yml` (project config)

**Don't commit**:

- `.kiss/extensions/.cache/` (catalog cache)
- `.kiss/extensions/.backup/` (config backups)
- `.kiss/extensions/*/*.local.yml` (local overrides)
- `.kiss/extensions/.registry` (installation state)

Add to `.gitignore`:

```gitignore
.kiss/extensions/.cache/
.kiss/extensions/.backup/
.kiss/extensions/*/*.local.yml
.kiss/extensions/.registry
```

### 2. Team Workflows

**For teams**:

1. Agree on which extensions to use
2. Commit extension configuration
3. Document extension usage in README
4. Keep extensions updated together

**Example README section**:

```markdown
## Extensions

This project uses:
- **jira** (v1.0.0) - Jira integration
  - Config: `.kiss/extensions/jira/jira-config.yml`
  - Requires: jira-mcp-server

To install: `kiss extension add jira`
```

### 3. Local Development

Use local config for development:

```yaml
# .kiss/extensions/jira/jira-config.local.yml
project:
  key: "DEVTEST"  # Your test project

defaults:
  task:
    custom_fields:
      customfield_10002: 1  # Lower story points for testing
```

### 4. Environment-Specific Config

Use environment variables for CI/CD:

```bash
# .github/workflows/deploy.yml
env:
  KISS_JIRA_PROJECT_KEY: ${{ secrets.JIRA_PROJECT }}

- name: Create Jira Issues
  run: kiss extension add jira && ...
```

### 5. Extension Updates

**Check for updates regularly**:

```bash
# Weekly or before major releases
kiss extension update
```

**Pin versions for stability**:

```yaml
# .kiss/extensions.yml
installed:
  - id: jira
    version: "1.0.0"  # Pin to specific version
```

### 6. Minimal Extensions

Only install extensions you actively use:

- Reduces complexity
- Faster command loading
- Less configuration

### 7. Documentation

Document extension usage in your project:

```markdown
# PROJECT.md

## Working with Jira

After creating tasks, sync to Jira:
1. Run `/kiss.taskify` to generate tasks
2. Run `/kiss.jira.specstoissues` to create Jira issues
3. Run `/kiss.jira.sync-status` to update status
```

---

## FAQ

### Q: Can I use multiple extensions at once?

**A**: Yes! Extensions are designed to work together. Install as many as you need.

### Q: Do extensions slow down kiss?

**A**: No. Extensions are loaded on-demand and only when their commands are used.

### Q: Can I create private extensions?

**A**: Yes. Install with `--dev` or `--from` and keep private. Public catalog submission is optional.

### Q: How do I know if an extension is safe?

**A**: Look for the ✓ Verified badge. Verified extensions are reviewed by maintainers. Always review extension code before installing.

### Q: Can extensions modify kiss core?

**A**: No. Extensions can only add commands and hooks. They cannot modify core functionality.

### Q: What happens if two extensions have the same command name?

**A**: Extensions use namespaced commands (`kiss.{extension}.{command}`), so conflicts are very rare. The extension system will warn you if conflicts occur.

### Q: Can I contribute to existing extensions?

**A**: Yes! Most extensions are open source. Check the repository link in `kiss extension info {extension}`.

### Q: How do I report extension bugs?

**A**: Go to the extension's repository (shown in `kiss extension info`) and create an issue.

### Q: Can extensions work offline?

**A**: Once installed, extensions work offline. However, some extensions may require internet for their functionality (e.g., Jira requires Jira API access).

### Q: How do I backup my extension configuration?

**A**: Extension configs are in `.kiss/extensions/{extension}/`. Back up this directory or commit configs to git.

---

## Support

- **Extension Issues**: Report to extension repository (see `kiss extension info`)
- **kiss Issues**: <https://github.com/statsperform/kiss/issues>
- **Extension Catalog**: <https://github.com/statsperform/kiss/tree/main/extensions>
- **Documentation**: See EXTENSION-DEVELOPMENT-GUIDE.md and EXTENSION-PUBLISHING-GUIDE.md

---

*Last Updated: 2026-01-28*
*kiss Version: 0.1.0*
