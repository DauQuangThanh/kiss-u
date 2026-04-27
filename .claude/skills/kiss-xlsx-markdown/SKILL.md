---
name: "kiss-xlsx-markdown"
description: "Translate between Excel (.xlsx) files and Markdown with high-fidelity round-trip. Use this skill whenever the user wants to convert a spreadsheet to Markdown, review or diff a workbook as text, edit cell values or formulas in Markdown and regenerate the .xlsx, or keep a canonical text version of a workbook alongside the .xlsx. Triggers: 'xlsx to markdown', 'excel to md', 'convert this workbook to markdown', 'edit this spreadsheet as text', 'rebuild this xlsx from markdown', 'export spreadsheet as markdown tables', 'round-trip my excel file'. Preserves sheets, formulas, merged cells, number formats, fills, fonts, column widths, freeze panes, named ranges, data validations, and charts via a sidecar meta.json. Not a replacement for the base xlsx skill when building a complex financial model from scratch — use that skill for new models, and use this one for round-trip translation."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-xlsx-markdown/kiss-xlsx-markdown.md"
user-invocable: true
disable-model-invocation: false
---


# xlsx-markdown

Round-trip translation between `.xlsx` and Markdown.

## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty). If the
input clearly states the operation and file (e.g. "convert model.xlsx
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
| `KISS_XLSX_OP` | `to-md` / `to-xlsx` / `roundtrip` / `recalc` | `to-md` |
| `KISS_XLSX_INPUT` | Input file path | *(required — ask if missing)* |
| `KISS_XLSX_OUTPUT` | Output file path | Derived from input name |
| `KISS_XLSX_VALUES_ONLY` | `true` / `false` — show cached values instead of formulas | `false` |
| `KISS_XLSX_NO_META` | `true` / `false` — skip sidecar (lossy) | `false` |
| `KISS_XLSX_RECALC` | `true` / `false` — recalculate formulas after rebuild | `false` |

## Interactive workflow

1. **Detect intent** from `$ARGUMENTS`. If operation and input file
   are already clear, jump to step 5.

2. **Ask operation:**
   - A) Export `.xlsx` → Markdown (default)
   - B) Rebuild `.xlsx` from Markdown
   - C) Round-trip check (export, rebuild, diff)
   - D) Recalculate formulas in an existing `.xlsx`

3. **Ask input file path** (the `.xlsx` for A/C/D; the `.md` for B).

4. **Ask output file path** — propose the derived default
   (e.g. `model.md` for `model.xlsx`) and let the user accept or
   override. (Not needed for D.)

5. **Ask about the key option** for the chosen operation:
   - A) Show cached values instead of formulas? (`--values-only`) Default: no.
   - B) Recalculate formulas after rebuild? (`--recalc`) Default: no.
   - C/D) No extra options.

6. **Show the full command** and ask for confirmation before running.

## When to use

- User wants to edit cell values or formulas as text and rebuild the `.xlsx`.
- User wants a text-friendly diff of a spreadsheet in git.
- User asks to "export this Excel to markdown" or "rebuild this workbook from markdown".
- User wants to review a workbook's contents without opening Excel.

For authoring a complex financial model or chart-heavy workbook from scratch, use the base `xlsx` skill.

## Quick reference

| Task | Command |
|------|---------|
| xlsx to Markdown | `python scripts/xlsx_to_md.py input.xlsx output.md` |
| Markdown to xlsx | `python scripts/md_to_xlsx.py input.md output.xlsx` |
| Recalculate formulas | `python scripts/recalc.py output.xlsx` |
| Round-trip check | `python scripts/roundtrip_check.py input.xlsx` |

The `python …` invocations work identically on macOS, Linux, and Windows — forward slashes in script paths are accepted by Python on all three platforms. The platform difference is only in *setup* (creating the venv) and *activation*.

## Setup (cross-platform)

The scripts auto-prefer a project-local `./.venv` in your current working directory. Run the bootstrap helper once per workspace:

**macOS / Linux (bash):**

```bash
cd /path/to/your/workspace          # where your .xlsx lives
bash <skill-dir>/scripts/bash/setup_env.sh
```

**Windows (PowerShell):**

```powershell
cd C:\path\to\your\workspace        # where your .xlsx lives
pwsh <skill-dir>\scripts\powershell\setup_env.ps1
```

The helper creates `./.venv` next to your files (not inside the skill folder) and `pip install`s `openpyxl` and `PyYAML` from `scripts/requirements.txt`. Subsequent script runs are then automatic — each script detects the venv and re-execs under it.

If the venv is missing when you run a script, you get a clear setup hint and the script exits. Pass `--system-python` on the command line to force the current interpreter:

```bash
# macOS / Linux
python scripts/xlsx_to_md.py input.xlsx output.md --system-python
```

```powershell
# Windows
python scripts\xlsx_to_md.py input.xlsx output.md --system-python
```

LibreOffice (`soffice`) is an optional system dependency, used only for `--recalc`. The scripts find it on PATH and additionally fall back to:

- macOS: `/Applications/LibreOffice.app/Contents/MacOS/soffice`
- Windows: `C:\Program Files\LibreOffice\program\soffice.exe` (and the x86 variant)
- Linux: `/usr/bin/soffice`, `/usr/local/bin/soffice`, `/snap/bin/libreoffice`

## Round-trip workflow

1. **Export** the workbook. The script writes:
   - `<name>.md` — the editable Markdown with one section per sheet.
   - `<name>.assets/` — embedded images and chart snapshots.
   - `<name>.meta.json` — per-cell formatting, merges, column widths, data validation, named ranges, chart XML.
2. **Edit** the `.md`. Change cell values, rewrite formulas, add rows, reorder sheets. Edits to formatting should go in `meta.json`.
3. **Rebuild** to `.xlsx`. The script reads the Markdown, applies the sidecar metadata, and optionally recalculates formulas via LibreOffice so cached values are fresh.

## Markdown format

Full spec in `references/format-spec.md`. Highlights:

```markdown
---
title: Q3 Forecast
author: Claude
xlsx_meta: forecast.meta.json
sheets_order: [Assumptions, Forecast, Summary]
---

<!-- sheet:start name="Assumptions" id="1" hidden="false" -->
```yaml meta
tab_color: "#1E2761"
freeze_panes: "B2"
column_widths: {A: 24, B: 14, C: 14, D: 14}
```

| Assumption | 2024 | 2025 | 2026 |
| --- | --- | --- | --- |
| Growth rate | 15.0% | 18.0% | 20.0% |
| Gross margin | 62.0% | 63.0% | 64.0% |
| Headcount | 120 | 150 | 180 |

<!-- sheet:end -->

<!-- sheet:start name="Forecast" id="2" -->
```yaml meta
freeze_panes: "B2"
merged_cells: ["A1:D1"]
```

| Forecast ($K) | 2024 | 2025 | 2026 |
| --- | --- | --- | --- |
| Revenue | 10,000 | `=B2*(1+Assumptions!B2)` | `=C2*(1+Assumptions!C2)` |
| COGS | `=B2*(1-Assumptions!B3)` | `=C2*(1-Assumptions!C3)` | `=D2*(1-Assumptions!D3)` |
| Gross profit | `=B2-B3` | `=C2-C3` | `=D2-D3` |

<!-- sheet:end -->
```markdown

Formulas are written as backticked inline code starting with `=`. Values are written plain. Number formats (currency, %, etc.) live in the sidecar.

## Script usage

### `xlsx_to_md.py`

macOS / Linux (bash):

```bash
python scripts/xlsx_to_md.py model.xlsx model.md
python scripts/xlsx_to_md.py model.xlsx model.md --assets-dir media
python scripts/xlsx_to_md.py model.xlsx model.md --no-meta      # lossy text dump
python scripts/xlsx_to_md.py model.xlsx model.md --values-only  # show cached values, not formulas
```

Windows (PowerShell):

```powershell
python scripts\xlsx_to_md.py model.xlsx model.md
python scripts\xlsx_to_md.py model.xlsx model.md --assets-dir media
python scripts\xlsx_to_md.py model.xlsx model.md --no-meta
python scripts\xlsx_to_md.py model.xlsx model.md --values-only
```

Options:

- `--assets-dir` — override the media folder (default: `<name>.assets`).
- `--no-meta` — skip the sidecar.
- `--values-only` — emit cached formula results instead of the formula text. Useful for read-only reviews.

### `md_to_xlsx.py`

macOS / Linux (bash):

```bash
python scripts/md_to_xlsx.py model.md model.xlsx
python scripts/md_to_xlsx.py model.md model.xlsx --meta model.meta.json
python scripts/md_to_xlsx.py model.md model.xlsx --template original.xlsx
python scripts/md_to_xlsx.py model.md model.xlsx --recalc
```

Windows (PowerShell):

```powershell
python scripts\md_to_xlsx.py model.md model.xlsx
python scripts\md_to_xlsx.py model.md model.xlsx --meta model.meta.json
python scripts\md_to_xlsx.py model.md model.xlsx --template original.xlsx
python scripts\md_to_xlsx.py model.md model.xlsx --recalc
```

Options:

- `--meta` — override the sidecar location.
- `--template` — start from an existing `.xlsx` (preserves charts, named ranges, and protected sheets exactly).
- `--recalc` — run `recalc.py` after writing to force LibreOffice to recalculate formulas.

### `recalc.py`

Lightweight wrapper that invokes LibreOffice to recalculate formulas and scan for errors. Returns JSON like the base `xlsx` skill's recalc.

macOS / Linux (bash):

```bash
python scripts/recalc.py model.xlsx
```

Windows (PowerShell):

```powershell
python scripts\recalc.py model.xlsx
```

## Conventions the skill enforces on rebuild

The Markdown representation doesn't encode the financial-modeling conventions the base `xlsx` skill requires (blue inputs, black formulas, etc.). Those live in the sidecar. If you edit a formula, its text color in the sidecar stays black; if you add a new hardcoded input, add a cell-style entry in `meta.json` under that sheet/cell if you want it highlighted in blue. The rebuild does not auto-color cells.

## Known limitations

- VBA/macros in `.xlsm` files are not round-tripped via Markdown; use `--template` with the macro-enabled file.
- Pivot tables are stored in the sidecar; data changes under a pivot's source range require a `recalc` pass and (in Excel) a pivot refresh. Use the base `xlsx` skill to author pivots from scratch.
- Charts are copied from the template. Edits to chart data go through the underlying data range, not the chart XML.
- Extremely wide sheets (hundreds of columns) produce unwieldy Markdown tables. Consider splitting the sheet or using `--values-only` for reviews.

## Dependencies

Python deps are installed automatically by `setup_env.sh` / `setup_env.ps1` into the project-local `./.venv`. The list is in `scripts/requirements.txt`:

- `openpyxl`
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

- LibreOffice (`soffice`) — required only for `--recalc` and as a side-effect in `--template`-driven recalculation. The scripts find it on PATH and additionally fall back to standard install paths on macOS / Linux / Windows.

## Composition with the base xlsx skill

For new workbooks, formula-heavy models, or reformatting work, use the base `xlsx` skill. Use this skill when the Markdown representation itself is the deliverable or the intermediate format for edits.
