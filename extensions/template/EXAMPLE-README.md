<!-- markdownlint-disable MD025 -->
# EXAMPLE: Extension README

This is an example of what your extension README should look like after customization.
**Delete this file and replace README.md with content similar to this.**

---

# My Extension

<!-- CUSTOMIZE: Replace with your extension description -->

Brief description of what your extension does and why it's useful.

## Features

<!-- CUSTOMIZE: List key features -->

- Feature 1: Description
- Feature 2: Description
- Feature 3: Description

## Installation

```bash
# Install from catalog
kiss extension add my-extension

# Or install from local development directory
kiss extension add --dev /path/to/my-extension
```

## Configuration

1. Create configuration file:

   ```bash
   cp .kiss/extensions/my-extension/config-template.yml \
      .kiss/extensions/my-extension/my-extension-config.yml
   ```

2. Edit configuration:

   ```bash
   vim .kiss/extensions/my-extension/my-extension-config.yml
   ```

3. Set required values:
   <!-- CUSTOMIZE: List required configuration -->
   ```yaml
   connection:
     url: "https://api.example.com"
     api_key: "your-api-key"

   project:
     id: "your-project-id"
   ```

## Usage

<!-- CUSTOMIZE: Add usage examples -->

### Command: example

Description of what this command does.

```bash
# In Claude Code
> /kiss.my-extension.example
```

**Prerequisites**:

- Prerequisite 1
- Prerequisite 2

**Output**:

- What this command produces
- Where results are saved

## Configuration Reference

<!-- CUSTOMIZE: Document all configuration options -->

### Connection Settings

| Setting | Type | Required | Description |
|---------|------|----------|-------------|
| `connection.url` | string | Yes | API endpoint URL |
| `connection.api_key` | string | Yes | API authentication key |

### Project Settings

| Setting | Type | Required | Description |
|---------|------|----------|-------------|
| `project.id` | string | Yes | Project identifier |
| `project.workspace` | string | No | Workspace or organization |

## Environment Variables

Override configuration with environment variables:

```bash
# Override connection settings
export KISS_MY_EXTENSION_CONNECTION_URL="https://custom-api.com"
export KISS_MY_EXTENSION_CONNECTION_API_KEY="custom-key"
```

## Examples

<!-- CUSTOMIZE: Add real-world examples -->

### Example 1: Basic Workflow

```bash
# Step 1: Create specification
> /kiss.spec

# Step 2: Generate tasks
> /kiss.taskify

# Step 3: Use extension
> /kiss.my-extension.example
```

## Troubleshooting

<!-- CUSTOMIZE: Add common issues -->

### Issue: Configuration not found

**Solution**: Create config from template (see Configuration section)

### Issue: Command not available

**Solutions**:

1. Check extension is installed: `kiss extension list`
2. Restart AI agent
3. Reinstall extension

## License

MIT License - see LICENSE file

## Support

- **Issues**: <https://github.com/your-org/kiss-my-extension/issues>
- **kiss Docs**: <https://github.com/statsperform/kiss>

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

*Extension Version: 1.0.0*
*kiss: >=0.1.0*
