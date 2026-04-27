# Source-to-Target Field Mapping: {project}

**Date:** {date}
**Migration strategy:** {strategy}

## Legend

| Symbol | Meaning |
|---|---|
| ✓ | Direct mapping (same name/type) |
| T | Transformation required |
| D | Default value applied (no source field) |
| ! | Unmapped — DMDEBT raised |

---

## Mapping table

<!-- One section per target entity.
     Transformation rule examples:
       CONCAT(first_name, ' ', last_name)
       CASE WHEN status = 1 THEN 'active' ELSE 'inactive' END
       COALESCE(email, 'unknown@placeholder.invalid')
       TO_TIMESTAMP(created_at, 'DD/MM/YYYY')
-->

{mapping_sections}

---

## Unmapped target fields (DMDEBT)

| Target entity | Target field | Reason | Action |
|---|---|---|---|
| <!-- entity --> | <!-- field --> | <!-- reason --> | <!-- action or DMDEBT ref --> |
