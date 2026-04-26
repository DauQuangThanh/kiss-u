# Installation Guide

## Prerequisites

- **Linux/macOS** (or Windows; PowerShell scripts now supported without WSL)
- AI coding agent: [Claude Code](https://www.anthropic.com/claude-code), [GitHub Copilot](https://code.visualstudio.com/), [Codex CLI](https://github.com/openai/codex), or [Gemini CLI](https://github.com/google-gemini/gemini-cli) — see [Supported AI Coding Agent Integrations](reference/integrations.md) for the full list
- [uv](https://docs.astral.sh/uv/) for package management
- [Python 3.11+](https://www.python.org/downloads/)
- [Git](https://git-scm.com/downloads)

## Installation

> **Important:** The only official, maintained packages for kiss come from the [DauQuangThanh/kiss](https://github.com/DauQuangThanh/kiss-u) GitHub repository. Any packages with the same name available on PyPI (e.g. `kiss` on pypi.org) are **not** affiliated with this project and are not maintained by the kiss maintainers. For normal installs, use the GitHub-based commands shown below. For offline or air-gapped environments, locally built wheels created from this repository are also valid.

### Initialize a New Project

The easiest way to get started is to initialize a new project. Pin a specific release tag for stability (check [Releases](https://github.com/DauQuangThanh/kiss-u/releases) for the latest):

```bash
# Install from a specific stable release (recommended — replace vX.Y.Z with the latest tag)
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git@vX.Y.Z kiss init <PROJECT_NAME>

# Or install latest from main (may include unreleased changes)
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git kiss init <PROJECT_NAME>
```

Or initialize in the current directory:

```bash
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git@vX.Y.Z kiss init .
# or use the --here flag
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git@vX.Y.Z kiss init --here
```

### Select AI Integrations

By default, `kiss init` presents a multi-select checklist during initialization. Claude is pre-selected; you can select any combination of supported agents. To specify integrations non-interactively:

```bash
# Specify one or more integrations
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git@vX.Y.Z kiss init <project_name> --integration claude
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git@vX.Y.Z kiss init <project_name> --integration claude --integration copilot
```

### Script Type (Shell vs PowerShell)

Every installed skill folder bundles both Bash (`.sh`) and PowerShell (`.ps1`) variants of every support script, so there is nothing to pick at install time. `kiss` auto-selects the right variant based on the host OS (`ps` on Windows, `sh` elsewhere) when it wires up the generated SKILL.md.

### Skip Tool Verification

If you prefer to get the templates without checking for the right tools:

```bash
uvx --from git+https://github.com/DauQuangThanh/kiss-u.git@vX.Y.Z kiss init <project_name> --integration claude --ignore-agent-tools
```

## Verification

After installation, run the following command to confirm the correct version is installed:

```bash
kiss version
```

This helps verify you are running the official kiss build from GitHub, not an unrelated package with the same name.

After initialization, you should see the following commands available in your AI agent:

- `/kiss-specify` - Create specifications
- `/kiss-plan` - Generate implementation plans  
- `/kiss-taskify` - Break down into actionable tasks

Each installed skill folder (e.g. `.claude/skills/kiss-specify/`) contains its own `scripts/bash/` and `scripts/powershell/` directories, so the skill works on both POSIX and Windows regardless of which `--script` variant you requested.

## Troubleshooting

### Enterprise / Air-Gapped Installation

Every GitHub Release ships a pre-built wheel, an sdist, and a `SHA256SUMS`
file. The wheel bundles every template, preset, extension, workflow, and
support script that kiss ships with, so once installed it needs **no** network
access for `kiss init` or `kiss upgrade`.

**Step 1: Download the wheel on a connected machine (same OS and Python version as the target)**

Grab the wheel and its runtime dependencies. Using the attached release wheel
avoids a build step:

```bash
# Fetch the release wheel (replace vX.Y.Z with the version you want)
curl -L -o kiss.whl \
  https://github.com/DauQuangThanh/kiss-u/releases/download/vX.Y.Z/kiss-X.Y.Z-py3-none-any.whl

# Resolve and download all runtime dependencies next to it
mkdir dist && mv kiss.whl dist/
pip download -d dist/ dist/kiss.whl
```

If your policy requires building from source, use the sdist instead:

```bash
curl -L -o dist/kiss.tar.gz \
  https://github.com/DauQuangThanh/kiss-u/releases/download/vX.Y.Z/kiss-X.Y.Z.tar.gz
pip install build
python -m build --wheel --outdir dist/ dist/kiss.tar.gz
pip download -d dist/ dist/kiss-*.whl
```

> **Important:** `pip download` resolves platform-specific wheels (e.g., PyYAML includes native extensions). You must run this step on a machine with the **same OS and Python version** as the air-gapped target. If you need to support multiple platforms, repeat this step on each target OS (Linux, macOS, Windows) and Python version.

**Step 2: Transfer the `dist/` directory to the air-gapped machine**

Copy the entire `dist/` directory (which contains the `kiss` wheel and all dependency wheels) to the target machine via USB, network share, or other approved transfer method.

**Step 3: Install on the air-gapped machine**

```bash
pip install --no-index --find-links=./dist kiss
```

**Step 4: Initialize a project (no network required)**

```bash
# Initialize a project — no GitHub access needed
kiss init my-project --integration claude
```

kiss automatically uses the bundled assets (templates, commands, scripts,
presets, extensions, and workflows) that ship inside the installed wheel. No
network access is required for `kiss init` or `kiss upgrade`.

> **Note:** Python 3.11+ is required.
>
> **Windows note:** Offline scaffolding requires PowerShell 7+ (`pwsh`), not Windows PowerShell 5.x (`powershell.exe`). Install from <https://aka.ms/powershell>.

### Git Credential Manager on Linux

If you're having issues with Git authentication on Linux, you can install Git Credential Manager:

```bash
#!/usr/bin/env bash
set -e
echo "Downloading Git Credential Manager v2.6.1..."
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.1/gcm-linux_amd64.2.6.1.deb
echo "Installing Git Credential Manager..."
sudo dpkg -i gcm-linux_amd64.2.6.1.deb
echo "Configuring Git to use GCM..."
git config --global credential.helper manager
echo "Cleaning up..."
rm gcm-linux_amd64.2.6.1.deb
```
