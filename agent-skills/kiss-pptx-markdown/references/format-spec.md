# pptx-markdown format specification

This document describes the exact Markdown dialect that `pptx_to_md.py` emits and `md_to_pptx.py` consumes. It is readable by humans, parseable as standard Markdown, and deterministic enough to round-trip.

## File layout

A deck is represented by three sibling artifacts:

```text
deck.md            # the Markdown source
deck.assets/       # images and embedded media
deck.meta.json     # high-fidelity sidecar (positions, theme, charts)
```

The Markdown file is the source of truth for content. The sidecar carries everything the Markdown cannot express losslessly. The assets folder holds referenced media. All three share the same basename.

## Document frontmatter

YAML frontmatter captures deck-level properties.

```yaml
---
title: Deck Title
author: Author Name
created: 2026-04-22T10:15:00Z
modified: 2026-04-22T14:02:00Z
slide_size: {width: 13.333, height: 7.5, unit: in}
template: original.pptx       # optional: path used as the rebuild template
pptx_meta: deck.meta.json     # optional: sidecar path, default is <basename>.meta.json
---
```

## Slide blocks

Each slide is wrapped in paired HTML comments. Parsers must match them exactly.

```text
<!-- slide:start layout="Layout Name" id="<int>" [background="#RRGGBB"] -->
  ...slide content...
<!-- notes:start -->
  ...speaker notes (required, non-empty)...
<!-- notes:end -->
<!-- slide:end -->
```

Attributes on `slide:start`:

- `layout` (required): name of a layout on the template deck. Names are case-sensitive. If missing from the template at rebuild time, `md_to_pptx.py` falls back to the first layout that exposes a title placeholder.
- `id` (required): stable integer identifier for the slide. Used to correlate with `meta.json`. Ids do not need to be contiguous or in order.
- `background` (optional): `#RRGGBB` solid fill override; omit to inherit from the master.
- `hidden` (optional): `true` to mark the slide as hidden in PowerPoint.

## Content mapping

Inside a slide block, standard Markdown maps to placeholders and shapes as follows.

### Title and subtitle

```markdown
# Quarterly Review           -> the title placeholder
## Strong growth in Q3       -> the subtitle placeholder (if present)
```

Only the first `#` and first `##` under a slide block are treated as placeholders. Subsequent headings become regular text in the body.

### Body content

Paragraphs, lists, blockquotes, and tables go into the first body/content placeholder. Example:

```markdown
- Revenue up 18%
- Net retention 114%
- Launched 2 new modules

> "This is the strongest quarter we've shipped."
> — CEO
```

Nested lists are supported up to 3 levels; deeper nesting is flattened on rebuild.

### Images

Use standard Markdown image syntax with Pandoc-style attribute blocks for positioning:

```markdown
![Alt text](deck.assets/chart.png){#shape-7 .chart width=6in height=3.5in x=3.5in y=1.8in}
```

Supported attributes:

- `#id` — stable shape id, must match a shape entry in `meta.json`.
- `.class` — free-form classification (e.g., `.chart`, `.icon`, `.photo`), preserved for round-trip.
- `width`, `height`, `x`, `y` — with units `in`, `cm`, or `pt`. Required for exact positioning; omitted values inherit from `meta.json` if present.

If the image has no attribute block, it is inserted into the body placeholder at its natural size.

### Tables

Standard GFM tables render as native PowerPoint tables:

```markdown
| Metric    | Q2   | Q3   |
|-----------|------|------|
| Revenue   | $4.1M | $4.8M |
| Customers | 1,220 | 1,430 |
```

Styling (cell fills, borders) is taken from the layout's table style. Per-cell overrides live in `meta.json` under the shape id.

### Code blocks and fenced content

Fenced code blocks render as monospaced text in a new text box:

````markdown
```python
def hello():
    return "world"
```
````

### Shapes not expressible in Markdown

SmartArt, grouped shapes, custom geometries, and charts with live data are represented by a placeholder line:

```markdown
<!-- shape id=12 kind=chart ref=meta.json#shapes.12 -->
```

Edit the corresponding entry in `meta.json` to modify these shapes. The line itself must remain in place; removing it removes the shape on rebuild.

## Speaker notes

Notes are required on every slide. Wrap them in a `notes` block:

```markdown
<!-- notes:start -->
Open with the headline number. Pause after the chart.
<!-- notes:end -->
```

Notes support standard Markdown (paragraphs, lists). On rebuild they are written to the slide's notes placeholder with basic formatting preserved.

## Sidecar `meta.json` structure

```json
{
  "slide_size_emu": {"cx": 12192000, "cy": 6858000},
  "template_path": "original.pptx",
  "core_properties": {
    "title": "...", "author": "...", "created": "...", "modified": "..."
  },
  "slides": {
    "1": {
      "layout_name": "Title Slide",
      "background": null,
      "hidden": false,
      "shapes": {
        "shape-7": {
          "kind": "picture",
          "left_emu": 3200400, "top_emu": 1645920,
          "cx_emu": 5486400, "cy_emu": 3200400,
          "rotation": 0,
          "asset": "deck.assets/chart-rev-q3.png"
        },
        "12": {
          "kind": "chart",
          "chart_xml": "ppt/charts/chart1.xml",
          "data": { "...": "..." }
        }
      }
    }
  }
}
```

All EMU (English Metric Units) values follow OOXML: 914400 EMU = 1 inch. The rebuild prefers EMU values from `meta.json` over the `width`/`height`/`x`/`y` attributes in the Markdown — the attributes are there for human readability and to let small hand edits take effect when `meta.json` entries are absent.

## Round-trip determinism

The exporter emits:

- Slides in document order.
- Shapes in z-order (back-to-front).
- Stable `shape-<n>` ids derived from shape index on first export; these ids are preserved across subsequent exports if `meta.json` is present.
- Canonical YAML (sorted keys, 2-space indent, no trailing spaces).

This makes `git diff` useful on the `.md` files and lets the round-trip check rely on byte-level equality of the re-exported Markdown.
