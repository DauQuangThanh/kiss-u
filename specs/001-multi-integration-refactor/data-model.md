# Data Model: multi-integration-refactor

**Date**: 2026-04-26

## Entity Changes

### `.kiss/integration.json` (MODIFIED)

**Before** (current):

```json
{
  "integration": "claude",
  "version": "0.1.0"
}
```

**After** (new):

```json
{
  "integrations": ["claude", "copilot"],
  "version": "0.1.0"
}
```

**Migration**: `_read_integration_json()` transparently converts
old format to new on read. Next write operation saves in new
format.

**Validation rules**:

- `integrations` MUST be a list of strings (may be empty).
- Each string MUST be a valid key in `INTEGRATION_REGISTRY`.
- No duplicate keys in the list.
- `version` MUST be a non-empty string (kiss CLI version).

**State transitions**:

- `[]` → `["claude"]` (install)
- `["claude"]` → `["claude", "copilot"]` (install another)
- `["claude", "copilot"]` → `["copilot"]` (uninstall claude)
- `["copilot"]` → `[]` (uninstall copilot)
- `["claude"]` → `["copilot"]` (switch claude → copilot)

### `.kiss/context.yml` (MODIFIED — merge behavior)

**No schema change.** The `integrations:` key already accepts a
list. The change is behavioral: on upgrade, existing values are
preserved via deep merge instead of overwrite.

**Merge rules**:

| Key type | Merge behavior |
|----------|----------------|
| Scalar (string, bool, int) | Existing value wins |
| Dict (paths, current, preferences, language) | Recursive merge |
| List (integrations) | Union merge (no duplicates) |
| `schema_version` | Always updated to new version |

### `.kiss/init-options.json` (MODIFIED)

**Before**: Contains singular `"integration"` key.
**After**: Contains `"integrations"` list. Drop singular key.

Same migration shim as `integration.json`.

### `CheckFinding` (NEW — internal model)

Used by `kiss check` to collect findings before rendering.

```python
@dataclass
class CheckFinding:
    file: str          # Path to the affected file/entity
    check: str         # Sub-check name: "skills", "integrations", "context"
    expected: str      # What was expected
    actual: str        # What was found
    fix: str           # Suggested fix action
```

## Relationships

```text
integration.json
  └── integrations: [keys]
       ├── .kiss/integrations/<key>.manifest.json  (one per key)
       ├── .<provider>/skills/kiss-*/               (one tree per key)
       └── context.yml integrations: [keys]         (kept in sync)
```

## Invariants

1. `integration.json.integrations` is always the authoritative
   list of installed integrations.
2. For every key in `integration.json.integrations`, a
   `.kiss/integrations/<key>.manifest.json` MUST exist.
3. `context.yml.integrations` MUST equal
   `integration.json.integrations` after any install/uninstall
   operation.
4. Each integration's directory tree is disjoint from all others
   (FR-018 — no shared folders).
