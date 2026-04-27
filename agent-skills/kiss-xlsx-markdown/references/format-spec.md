# xlsx-markdown format specification

A workbook is represented by three sibling artifacts:

```
model.md              # Markdown with one section per sheet
model.assets/         # images and chart snapshots
model.meta.json       # per-cell formatting, merges, validations, charts
```

## Workbook frontmatter

```yaml
---
title: Q3 Forecast
author: Claude
created: 2026-04-22T10:15:00Z
modified: 2026-04-22T14:02:00Z
sheets_order: [Assumptions, Forecast, Summary]
xlsx_meta: forecast.meta.json
defined_names:
  TaxRate: Assumptions!$B$5
  Horizon: Assumptions!$B$6
---
```

- `sheets_order` — authoritative order of sheets on rebuild.
- `defined_names` — workbook-scoped named ranges. Sheet-scoped names live in the sheet's `meta` block.

## Sheet block

Each sheet is wrapped in paired HTML comments:

```
<!-- sheet:start name="Forecast" id="2" hidden="false" -->
```yaml meta
... per-sheet metadata ...
```

| ... GFM table ... |

<!-- sheet:end -->
```

Attributes on `sheet:start`:
- `name` — sheet name (exact).
- `id` — stable integer id; preserved across round-trips.
- `hidden` — `true` | `false` | `veryhidden`.

### Per-sheet meta block

A fenced YAML block with the `meta` info string, placed directly under the `sheet:start` marker:

```yaml meta
tab_color: "#1E2761"
freeze_panes: B2
auto_filter: A1:D20
merged_cells: [A1:D1, B5:C5]
column_widths: {A: 24, B: 14, C: 14, D: 14}
row_heights: {1: 22, 5: 30}
defined_names:
  GrowthRate: $B$2
```

Any key not present here is either taken from the sidecar or left at defaults.

### Data table

Below the meta block, a standard GFM pipe table holds cell values.

- The first header row is the sheet's first row (row 1). If the source has no distinct header, the exporter still emits the row values as the header row.
- Cell text is emitted verbatim.
- Formulas are written as backticked inline code beginning with `=`: `` `=SUM(B2:B10)` ``.
- Numbers are written using the cell's display format when possible (e.g., `1,250`, `18.0%`, `$4,800`). The raw value + format string are in the sidecar.
- Dates are written in ISO 8601 (`2026-04-22`). The cell's display format is in the sidecar.
- Booleans are `TRUE` / `FALSE` (Excel convention).
- Errors are written as `#REF!`, `#DIV/0!`, etc.
- Empty cells are empty. To force a blank cell in the middle of a row, leave its pipe-separated slot blank (`| | |`).

Example:

```markdown
| Category | Q2 | Q3 |
| --- | --- | --- |
| Revenue | 4,100 | `=B2*(1+GrowthRate)` |
| Customers | 1,220 | 1,430 |
| Notes | | See appendix |
```

### Extended rows and columns

For sheets where the first row is not a logical header, prefix a GFM attribute caption so the importer skips the header assumption:

```markdown
| A | B | C |
| --- | --- | --- |
| Customer | Region | MRR |
| Acme | EMEA | 12,500 |

: {.raw start_row=1}
```

- `start_row` — the spreadsheet row number the first table row represents (default: 1).
- `.raw` — tells the importer to treat the first row as data, not a header.

## Sidecar `meta.json` structure

```json
{
  "core_properties": {
    "title": "...", "author": "...", "created": "...", "modified": "..."
  },
  "defined_names": {"TaxRate": "Assumptions!$B$5"},
  "sheets": {
    "Forecast": {
      "id": 2,
      "hidden": false,
      "tab_color": "1E2761",
      "freeze_panes": "B2",
      "merged_cells": ["A1:D1"],
      "column_widths": {"A": 24, "B": 14, "C": 14, "D": 14},
      "row_heights": {"1": 22, "5": 30},
      "cells": {
        "B2": {
          "number_format": "#,##0",
          "font": {"name": "Arial", "size": 11, "bold": false, "color": "000000"},
          "fill": {"patternType": "solid", "fgColor": "FFFFFF"},
          "border": {"top": "thin", "bottom": "thin", "left": "thin", "right": "thin"},
          "alignment": {"horizontal": "right", "vertical": "center"}
        }
      },
      "data_validations": [
        {"sqref": "B5:B20", "type": "list", "formula1": '"low,med,high"'}
      ],
      "images": [
        {"id": "img1", "anchor": "E2", "asset": "model.assets/logo.png", "width_px": 120, "height_px": 48}
      ],
      "charts": [
        {"id": "chart1", "kind": "bar", "anchor": "A15", "series": [
          {"name": "Revenue", "values": "Forecast!$B$2:$D$2", "categories": "Forecast!$B$1:$D$1"}
        ]}
      ]
    }
  }
}
```

Values in the sidecar are authoritative. The Markdown tables supply cell *content*; the sidecar supplies cell *style*.

## Precedence rules on rebuild

1. Markdown cell text wins for the cell's value / formula.
2. Sidecar `cells.{A1}` wins for style.
3. Frontmatter `sheets_order` wins over sidecar sheet order.
4. Frontmatter `defined_names` wins over sidecar workbook names.

If a cell exists in the sidecar but not in the Markdown (e.g., the row was deleted), the sidecar entry is dropped. This keeps the Markdown authoritative for content.

## Determinism

The exporter normalizes its output:
- Sheets emitted in workbook order.
- Column widths sorted by column letter.
- `cells` dict in the sidecar sorted by `(row, col)`.
- LF line endings, trailing-whitespace-stripped.

This keeps `git diff` useful.
