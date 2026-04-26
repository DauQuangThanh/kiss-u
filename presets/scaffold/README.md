# My Preset

A custom preset for kiss. Copy this directory and customize it to create your own.

## Templates Included

| Template | Type | Description |
|----------|------|-------------|
| `spec-template` | template | Custom feature specification template (overrides core and extensions) |
| `myext-template` | template | Override of the myext extension's report template |
| `kiss.specify` | command | Custom specification command (overrides core) |
| `kiss.myext.myextcmd` | command | Override of the myext extension's myextcmd command |

## Development

1. Copy this directory: `cp -r presets/scaffold my-preset`
2. Edit `preset.yml` — set your preset's ID, name, description, and templates
3. Add or modify templates in `templates/`
4. Test locally: `kiss preset add --dev ./my-preset`
5. Verify resolution: `kiss preset resolve spec-template`
6. Remove when done testing: `kiss preset remove my-preset`

## Manifest Reference (`preset.yml`)

Required fields:

- `schema_version` — always `"1.0"`
- `preset.id` — lowercase alphanumeric with hyphens
- `preset.name` — human-readable name
- `preset.version` — semantic version (e.g. `1.0.0`)
- `preset.description` — brief description
- `requires.kiss_version` — version constraint (e.g. `>=0.1.0`)
- `provides.templates` — list of templates with `type`, `name`, and `file`

## Template Types

- **template** — Document scaffolds (spec-template.md, plan-template.md, task-template.md, etc.)
- **command** — AI agent workflow prompts (e.g. kiss.specify, kiss.plan)
- **script** — Custom scripts (reserved for future use)

## Publishing

See the [Preset Publishing Guide](../PUBLISHING.md) for details on submitting to the catalog.

## License

MIT
