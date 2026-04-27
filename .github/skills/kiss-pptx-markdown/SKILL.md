---
name: "kiss-pptx-markdown"
description: "Translate between PowerPoint (.pptx) files and Markdown with high-fidelity round-trip. Use this skill whenever the user wants to convert a deck to Markdown, edit a deck as Markdown, regenerate a .pptx from Markdown, diff/review slide content as text, or version-control a presentation. Triggers: 'convert slides to markdown', 'edit this deck in markdown', 'pptx to md', 'md to pptx', 'round-trip my presentation', 'export slides as text', 'rebuild this pptx from markdown', or anytime a .pptx and a .md file both appear in the task. Not a replacement for the base pptx skill when the user is creating a visually rich deck from scratch — use that skill for new designs, and use this one for round-trip translation."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-pptx-markdown/kiss-pptx-markdown.md"
---


# pptx-markdown

Translate between `.pptx` and an extended Markdown format.

## Inputs

- A `.pptx` file (for export to Markdown) **or** a `.md` file produced
  by this skill (for rebuild to `.pptx`).
- Optional sidecar `<name>.meta.json` and template `.pptx` produced on
  the prior export — required for high-fidelity rebuild.
- Optional environment variables for auto mode: `KISS_PPTX_OP`,
  `KISS_PPTX_INPUT`, `KISS_PPTX_OUTPUT`, `KISS_PPTX_NO_META`,
  `KISS_PPTX_TEMPLATE`.

## Outputs

- On export (`to-md`): `<name>.md`, `<name>.assets/` (extracted slide
  media), `<name>.template.pptx`, and `<name>.meta.json` next to the
  input unless `--no-meta` is passed.
- On rebuild (`to-pptx`): the destination `.pptx` reconstructed from
  the Markdown + sidecar + template.
- On round-trip check: a diff of the original Markdown against
  Markdown re-extracted from the rebuilt `.pptx`.
- On `list-layouts`: a printout of slide layouts available in a
  `.pptx` template.

## Context Update

Does not mutate `.kiss/context.yml`. Operates on user-supplied file
paths only.

## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty). If the
input clearly states the operation and file (e.g. "convert deck.pptx
to markdown"), skip questions that are already answered.

## Mode behaviour

**Interactive** (default — `KISS_AGENT_MODE` unset or `interactive`):
Ask one question at a time. Offer lettered options. Always recommend a
default and state why. After gathering answers, show the exact command
and ask for confirmation before instructing the user to run it.

**Auto** (`KISS_AGENT_MODE=auto` or user says "in auto mode"):
Read answer keys from the environment (see table below). Apply defaults
for any missing key and log each default as a decision of kind
`default-applied`. Do not ask questions; output the command immediately.

## Auto mode answer keys

| Key | Meaning | Default |
|---|---|---|
| `KISS_PPTX_OP` | `to-md` / `to-pptx` / `roundtrip` / `list-layouts` | `to-md` |
| `KISS_PPTX_INPUT` | Input file path | *(required — ask if missing)* |
| `KISS_PPTX_OUTPUT` | Output file path | Derived from input name |
| `KISS_PPTX_NO_META` | `true` / `false` — skip sidecar (lossy) | `false` |
| `KISS_PPTX_TEMPLATE` | Template `.pptx` path for rebuild | From sidecar if present |

## Interactive workflow

1. **Detect intent** from `$ARGUMENTS`. If operation and input file
   are already clear, jump to step 5.

2. **Ask operation:**
   - A) Export `.pptx` → Markdown (default)
   - B) Rebuild `.pptx` from Markdown
   - C) Round-trip check (export, rebuild, diff)
   - D) List slide layouts in a `.pptx`

3. **Ask input file path** (the `.pptx` for A/C/D; the `.md` for B).

4. **Ask output file path** — propose the derived default
   (e.g. `deck.md` for `deck.pptx`) and let the user accept or
   override. (Not needed for D.)

5. **Ask about the key option** for the chosen operation:
   - A) Skip sidecar / lossy export? (`--no-meta`) Default: no.
   - B) Use a specific template deck? (`--template`) Default: from sidecar.
   - C/D) No extra options.

6. **Show the full command** and ask for confirmation before running.

## When to use

- User wants to edit deck text in a text editor and regenerate the `.pptx`.
- User wants to diff or version-control slide content as plain text.
- User wants to extract slide text + notes and later rebuild the deck.
- User asks to "convert this .pptx to markdown" or "build a pptx from this markdown".

If the user is *authoring a new presentation* from scratch and cares primarily about visual design, prefer the base `pptx` skill. Use this skill only when the Markdown representation is itself a goal.

## Quick reference

| Task | Command |
|------|---------|
| Deck to Markdown | `python scripts/pptx_to_md.py input.pptx output.md` |
| Markdown to deck | `python scripts/md_to_pptx.py input.md output.pptx` |
| Round-trip check | `python scripts/roundtrip_check.py input.pptx` |
| Inspect layouts | `python scripts/pptx_to_md.py --list-layouts input.pptx` |

The `python …` invocations work identically on macOS, Linux, and Windows — forward slashes in script paths are accepted by Python on all three platforms. The platform difference is only in *setup* (creating the venv) and *activation* (see below).

## Setup (cross-platform)

The scripts auto-prefer a project-local `./.venv` in your current working directory. Run the bootstrap helper once per workspace:

**macOS / Linux (bash):**

```bash
cd /path/to/your/workspace          # where your .pptx lives
bash <skill-dir>/scripts/bash/setup_env.sh
```

**Windows (PowerShell):**

```powershell
cd C:\path\to\your\workspace        # where your .pptx lives
pwsh <skill-dir>\scripts\powershell\setup_env.ps1
```

The helper creates `./.venv` next to your files (not inside the skill folder) and `pip install`s `python-pptx` and `PyYAML` from `scripts/requirements.txt`. Subsequent script runs are then automatic — each script detects the venv and re-execs under it.

If the venv is missing when you run a script, you get a clear setup hint and the script exits. If you really want to run against the system Python, pass `--system-python` on the command line:

```bash
python scripts/pptx_to_md.py input.pptx output.md --system-python
```

(On Windows / PowerShell, the same flag works: `python scripts\pptx_to_md.py input.pptx output.md --system-python`.)

## Round-trip workflow

1. **Export** the deck to Markdown. The script writes:
   - `<name>.md` — the editable Markdown file.
   - `<name>.assets/` — images and embedded media referenced by the Markdown.
   - `<name>.meta.json` — high-fidelity metadata (theme, master slides, exact shape positions, chart data) that Markdown can't represent natively.
2. **Edit** the `.md` file. Any edits to text, bullets, tables, notes, or images propagate to the rebuild.
3. **Rebuild** to `.pptx`. The script reads the Markdown, reattaches assets, and re-applies metadata from the sidecar.

The sidecar `.meta.json` is what makes high-fidelity round-trip possible. Keep it next to the `.md` file. If it is missing, the rebuild falls back to a fresh deck using a built-in template — the content will be correct but custom layouts, master theming, and precise positioning will be lost.

## Markdown format

Full spec in `references/format-spec.md`. The short version:

```markdown
---
title: Q3 Review
author: Claude
pptx_meta: deck.meta.json
slide_size: {width: 13.333, height: 7.5, unit: in}
---

<!-- slide:start layout="Title Slide" id="1" -->
# Q3 Review
## A strong quarter

<!-- notes:start -->
Open with the headline number. Remember to thank the team.
<!-- notes:end -->
<!-- slide:end -->

<!-- slide:start layout="Title and Content" id="2" -->
# Highlights

- Revenue up 18%
- Churn down to 2.1%
- Launched two new modules

![Quarterly revenue chart](deck.assets/chart-rev-q3.png){#shape-7 .chart width=6in height=3.5in x=3.5in y=1.8in}

<!-- notes:start -->
The chart is the point of this slide. Pause for 3 seconds before clicking through.
<!-- notes:end -->
<!-- slide:end -->
```

Key conventions:

- Each slide is wrapped in `<!-- slide:start ... -->` / `<!-- slide:end -->`. The `layout` attribute must match a layout name in the source deck (or a default template).
- `<!-- notes:start -->` / `<!-- notes:end -->` mark speaker notes. **Every slide must have speaker notes.** If the source has none, write a short, useful note — do not leave the block empty.
- Headings (`#`, `##`) map to the slide's title/subtitle placeholders when the layout exposes them.
- Lists, paragraphs, and tables go into the body content placeholder.
- Images use standard Markdown `![alt](path)` syntax with an optional `{#id .class width=... height=... x=... y=...}` attribute block for exact positioning (Pandoc-style attributes).
- Any content that doesn't fit cleanly (e.g., SmartArt, grouped shapes, charts with live data) is stored in `deck.meta.json` and referenced by shape id.

## Visual design rule

All visual design (fonts, colors, backgrounds, logos) lives in the **Master Slide** of the source template. When rebuilding from Markdown, do not apply slide-level styling overrides — inherit from the master. If the user wants new branding, update the master template and re-export, don't patch individual slides.

## Script usage

### `pptx_to_md.py`

macOS / Linux (bash):

```bash
python scripts/pptx_to_md.py deck.pptx deck.md
python scripts/pptx_to_md.py deck.pptx deck.md --assets-dir custom-assets
python scripts/pptx_to_md.py deck.pptx --list-layouts    # Print layout names and exit
python scripts/pptx_to_md.py deck.pptx deck.md --no-meta # Skip sidecar (lossy export)
```

Windows (PowerShell):

```powershell
python scripts\pptx_to_md.py deck.pptx deck.md
python scripts\pptx_to_md.py deck.pptx deck.md --assets-dir custom-assets
python scripts\pptx_to_md.py deck.pptx --list-layouts
python scripts\pptx_to_md.py deck.pptx deck.md --no-meta
```

Output files:

- `deck.md`
- `deck.assets/` (images, embedded media)
- `deck.meta.json` (unless `--no-meta`)

### `md_to_pptx.py`

macOS / Linux (bash):

```bash
python scripts/md_to_pptx.py deck.md deck.pptx
python scripts/md_to_pptx.py deck.md deck.pptx --template original.pptx
python scripts/md_to_pptx.py deck.md deck.pptx --meta deck.meta.json
```

Windows (PowerShell):

```powershell
python scripts\md_to_pptx.py deck.md deck.pptx
python scripts\md_to_pptx.py deck.md deck.pptx --template original.pptx
python scripts\md_to_pptx.py deck.md deck.pptx --meta deck.meta.json
```

By default the script looks for `<name>.meta.json` beside `<name>.md` and uses the original deck as the template if referenced there. Pass `--template` to force a specific template (the source `.pptx` is the best template — it carries master slides, layouts, and theme).

### `roundtrip_check.py`

Exports a deck to Markdown, rebuilds it, then diffs the two `.pptx` files on text + structure. Returns nonzero on mismatch. Use it in QA.

macOS / Linux (bash):

```bash
python scripts/roundtrip_check.py deck.pptx
```

Windows (PowerShell):

```powershell
python scripts\roundtrip_check.py deck.pptx
```

## Known limitations

- Charts are preserved only if the rebuild uses the original as a template (the chart XML is copied from the template's chart parts via `deck.meta.json`). Edits to chart *data* in the `.md` are not reflected — edit in PowerPoint or via the base `pptx` skill for chart data changes.
- SmartArt is round-tripped as a static image plus metadata. Text inside SmartArt can be edited via the `meta.json` shape entry.
- Animations and transitions are preserved via the template but not surfaced in Markdown.
- Exact font metrics may shift if the rebuild environment lacks the original fonts.

## QA

After any rebuild, run the verification loop from the base `pptx` skill (convert to images with LibreOffice + `pdftoppm`, visually inspect). This skill only guarantees structural fidelity; visual correctness still needs a human or subagent pass.

## Dependencies

Python deps are installed automatically by `setup_env.sh` / `setup_env.ps1` into the project-local `./.venv`. The list is in `scripts/requirements.txt`:

- `python-pptx`
- `PyYAML`

If you want to install them manually instead of using the bootstrap helper:

macOS / Linux (bash) — into a venv:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r <skill-dir>/scripts/requirements.txt
```

Windows (PowerShell) — into a venv:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r <skill-dir>\scripts\requirements.txt
```

System dependencies (optional):

- LibreOffice (`soffice`) for visual QA. The scripts find it on PATH; if it is not on PATH the helper also checks the macOS app bundle (`/Applications/LibreOffice.app/Contents/MacOS/soffice`) and the standard Windows install dirs (`C:\Program Files\LibreOffice\program\soffice.exe` and the x86 variant).
