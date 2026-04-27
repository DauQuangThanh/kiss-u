# docx-markdown format specification

Documents are represented by four sibling artifacts:

```text
report.md              # pandoc-flavored Markdown
report.assets/         # extracted images and media
report.reference.docx  # copy of the original, used for styles on rebuild
report.meta.json       # comments, tracked changes, core props, extras
```

The Markdown file is the source of truth for content. The reference doc supplies styles (fonts, colors, table themes, page size, margins, headers/footers). The sidecar carries everything that doesn't survive a pandoc round-trip cleanly.

## Markdown flavor

Output uses pandoc's `gfm+attributes+fenced_divs+bracketed_spans+footnotes+raw_attribute+pipe_tables+task_lists+implicit_figures` dialect. The exporter and importer are both invoked with the same flags so round-trip is stable.

## Frontmatter

```yaml
---
title: Project Brief
subtitle: Draft for legal review
author: Claude
created: 2026-04-22T10:15:00Z
modified: 2026-04-22T14:02:00Z
reference_doc: brief.reference.docx
docx_meta: brief.meta.json
---
```

Optional keys:

- `subject`, `keywords`, `category`, `description` — core properties mapped to docx.
- `language` — `en-US`, `vi-VN`, etc.

## Headings, paragraphs, lists, tables

Standard GFM. Heading levels 1–6 map to `Heading 1`…`Heading 6` in the reference doc. Task lists (`- [ ]`) render as Word's built-in checkbox bullets when the reference doc exposes that style.

## Images

```markdown
![Flow diagram](brief.assets/flow.png){#fig-flow width=6in height=3.2in}
```

Attribute block accepts `width`, `height` (in `in`, `cm`, `pt`), plus `#id` and `.class`. IDs are preserved in the `meta.json` and re-emitted on export.

## Footnotes

```markdown
This claim requires a source.^[See internal memo MKT-2026-031.]
```

Pandoc footnotes round-trip cleanly.

## Comments

Comments are Markdown spans with the `.comment` class:

```markdown
[This needs rewriting.]{.comment author="Claude" date="2026-04-22T09:12:00Z" id="c1"}
```

Attributes:

- `author` — required.
- `date` — required, ISO 8601.
- `id` — required for replies. If omitted on export the exporter assigns one.
- `reply_to` — optional; id of the parent comment.

The `meta.json` carries the exact `<w:comment>` XML so fonts, inline formatting, and mention tags (`@user`) survive the round-trip.

## Tracked changes

Fenced divs:

```markdown
::: {.tracked-insertion author="Claude" date="2026-04-22" id="i1"}
Added clause about data retention.
:::

::: {.tracked-deletion author="Claude" date="2026-04-22" id="d1"}
Deprecated clause about cookie consent.
:::
```

Single-word inline changes can also use a bracketed span:

```markdown
The term is [30]{.deletion author="Claude"}[60]{.insertion author="Claude"} days.
```

On rebuild the spans/divs are converted to `<w:ins>` / `<w:del>` blocks with the declared authorship. Use `--accept-changes` on export to produce a clean Markdown file without these spans.

## Sections, columns, page breaks

```markdown
::: {.section columns=2 break="page"}

Two-column section content goes here.

:::
```

Supported keys:

- `columns` — integer.
- `break` — `page` | `column` | `section_next` | `section_even` | `section_odd`.
- `orientation` — `portrait` | `landscape`.

For a standalone page break:

```markdown
::: {.pagebreak}
:::
```

## Tables

GFM pipe tables, with attribute blocks for ids and widths:

```markdown
| Milestone | Target date |
| --- | --- |
| Design review | 2026-05-02 |

: Project timeline {#tbl-timeline .timeline widths="3in,2in"}
```

- Caption syntax (pandoc): a line starting with `:` immediately below the table.
- `widths` sums to the content area width; pandoc distributes if the sum doesn't match.
- Complex tables (merged cells, row/column spans) are stored in the sidecar under the table's id; the Markdown table is a best-effort human-readable representation.

## Equations

Equations are preserved in the sidecar. In Markdown they appear as:

```markdown
<!-- equation id=eq1 -->
```

Edit the equation in Word or via the base `docx` skill.

## Sidecar `meta.json` structure

```json
{
  "core_properties": {
    "title": "...",
    "subject": "...",
    "author": "...",
    "last_modified_by": "...",
    "created": "2026-04-22T10:15:00Z",
    "modified": "2026-04-22T14:02:00Z",
    "keywords": ["onboarding", "launch"],
    "category": "PRD"
  },
  "styles": { "customStyles": ["Legal-Clause", "Callout-Blue"] },
  "comments": [
    {
      "id": "c1",
      "author": "Claude",
      "initials": "CL",
      "date": "2026-04-22T09:12:00Z",
      "text": "This needs rewriting.",
      "raw_xml": "<w:comment ...>...</w:comment>",
      "parent_id": null
    }
  ],
  "tracked_changes": [
    {
      "id": "i1",
      "kind": "insertion",
      "author": "Claude",
      "date": "2026-04-22T09:12:00Z"
    }
  ],
  "equations": [
    {"id": "eq1", "omath_xml": "<m:oMath>...</m:oMath>"}
  ],
  "tables": {
    "tbl-timeline": {
      "merged_cells": [[0, 1, 0, 2]],
      "row_heights": [0.4, 0.4, 0.4]
    }
  }
}
```

## Determinism and diffs

The exporter normalizes pandoc's output:

- LF line endings.
- No trailing whitespace.
- Sorted YAML keys.
- Tables aligned so that column separators line up by column width.

This keeps `git diff` useful.
