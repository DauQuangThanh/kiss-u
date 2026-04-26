# Contract: `.kiss/integration.json` Schema

**Version**: 2.0 (multi-integration)

## Schema

```json
{
  "integrations": ["claude", "copilot"],
  "version": "0.1.0"
}
```

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `integrations` | `list[str]` | Yes | Ordered list of installed integration keys. May be empty. |
| `version` | `str` | Yes | kiss CLI version that last wrote this file. |

## Backward Compatibility

When `_read_integration_json()` encounters the legacy format:

```json
{"integration": "claude", "version": "0.1.0"}
```

It MUST return the equivalent new format:

```json
{"integrations": ["claude"], "version": "0.1.0"}
```

The file is rewritten in the new format on the next write.

## Consumers

| Consumer | Operation | File |
|----------|-----------|------|
| `integration_install` | read + append | `cli/integration.py` |
| `integration_uninstall` | read + remove | `cli/integration.py` |
| `integration_upgrade` | read (validate key) | `cli/integration.py` |
| `integration_switch` | read + remove + append | `cli/integration.py` |
| `check_skills` | read (list integrations) | `cli/check.py` |
| `check_integrations` | read (list integrations) | `cli/check.py` |
| `kiss init` | write (initial creation) | `cli/init.py` |
