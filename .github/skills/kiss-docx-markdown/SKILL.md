---
name: "kiss-docx-markdown"
description: "Translate between Word (.docx) files and Markdown with high-fidelity round-trip. Use this skill whenever the user wants to convert a Word document to Markdown, edit a .docx as text, regenerate a .docx from Markdown, diff/review Word content in git, or keep a canonical text version of a document alongside the .docx. Triggers: 'docx to markdown', 'word to md', 'convert this Word doc to markdown', 'rebuild this docx from markdown', 'edit my report in markdown', 'extract word text with formatting', 'round-trip my Word doc'. Preserves headings, lists, tables, images, footnotes, comments, tracked changes, and document styles via pandoc plus a sidecar metadata file. Not a replacement for the base docx skill when the user is authoring a new Word document from scratch — use that skill for new content, and use this one for round-trip translation."
compatibility: "Requires kiss project structure with .kiss/ directory"
metadata:
  author: "github-kiss"
  source: "agent-skills/kiss-docx-markdown/kiss-docx-markdown.md"
---


# docx-markdown

Round-trip translation between `.docx` and Markdown.

## User Input

```text
$ARGUMENTS
```

Consider the user input before proceeding (if not empty). If the
input clearly states the operation and file (e.g. "convert report.docx
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
| `KISS_DOCX_OP` | `to-md` / `to-docx` / `roundtrip` | `to-md` |
| `KISS_DOCX_INPUT` | Input file path | *(required — ask if missing)* |
| `KISS_DOCX_OUTPUT` | Output file path | Derived from input name |
| `KISS_DOCX_ACCEPT_CHANGES` | `true` / `false` — accept tracked changes before export | `false` |
| `KISS_DOCX_NO_META` | `true` / `false` — skip sidecar (lossy) | `false` |

## Interactive workflow

1. **Detect intent** from `$ARGUMENTS`. If operation and input file
   are already clear, jump to step 5.

2. **Ask operation:**
   - A) Export `.docx` → Markdown (default)
   - B) Rebuild `.docx` from Markdown
   - C) Round-trip check (export, rebuild, diff)

3. **Ask input file path** (the `.docx` for A/C; the `.md` for B).

4. **Ask output file path** — propose the derived default
   (e.g. `report.md` for `report.docx`) and let the user accept or
   override.

5. **Ask about the key option** for the chosen operation:
   - A) Accept tracked changes first? (`--accept-changes`) Default: no.
   - B) Override reference doc? (`--reference-doc`) Default: use sidecar.
   - C) No extra options.

6. **Show the full command** and ask for confirmation before running. Built on `pandoc`, with a sidecar metadata file for anything pandoc can't represent losslessly (comments, custom styles, core properties, tracked-change authorship).

## When to use

- User wants to edit a Word document's content as Markdown and regenerate the `.docx`.
- User wants text-friendly diffs for a Word document in version control.
- User wants to extract a `.docx` to Markdown with images, tables, and comments intact.
- User asks to "convert this docx to md" or "rebuild this Word doc from markdown".

For authoring a brand-new Word document with complex styling, use the base `docx` skill. This skill is focused on faithful round-trip, not visual design.

## Quick reference

| Task | Command |
|------|---------|
| docx to Markdown | `python scripts/docx_to_md.py input.docx output.md` |
| Markdown to docx | `python scripts/md_to_docx.py input.md output.docx` |
| Round-trip check | `python scripts/roundtrip_check.py input.docx` |
| Convert `.doc` first | `soffice --headless --convert-to docx input.doc` (macOS / Linux) — see Setup for the Windows form |

The `python …` invocations work identically on macOS, Linux, and Windows — forward slashes in script paths are accepted by Python on all three platforms. The platform difference is only in *setup* and in invoking `soffice` directly.

## Setup (cross-platform)

The scripts auto-prefer a project-local `./.venv` in your current working directory. Run the bootstrap helper once per workspace:

**macOS / Linux (bash):**

```bash
cd /path/to/your/workspace            # where your .docx lives
bash <skill-dir>/scripts/bash/setup_env.sh
```

**Windows (PowerShell):**

```powershell
cd C:\path\to\your\workspace          # where your .docx lives
pwsh <skill-dir>\scripts\powershell\setup_env.ps1
```

The helper creates `./.venv` next to your files (not inside the skill folder) and `pip install`s the deps from `scripts/requirements.txt`. Subsequent script runs are then automatic — each script detects the venv and re-execs under it.

If the venv is missing when you run a script, you get a clear setup hint and the script exits. Pass `--system-python` on the command line to force the current interpreter:

```bash
# macOS / Linux
python scripts/docx_to_md.py input.docx output.md --system-python
```

```powershell
# Windows
python scripts\docx_to_md.py input.docx output.md --system-python
```

`pandoc` is a separate system dependency (not pip-installable). Install via your package manager:

```bash
# macOS
brew install pandoc

# Debian / Ubuntu
sudo apt-get install pandoc
```

```powershell
# Windows (Chocolatey)
choco install pandoc
```

Or download from [pandoc.org/installing.html](https://pandoc.org/installing.html).

If you also need `soffice` (LibreOffice — used for `--accept-changes` and `.doc` → `.docx`), the docx scripts find it on PATH and additionally fall back to:

- macOS: `/Applications/LibreOffice.app/Contents/MacOS/soffice`
- Windows: `C:\Program Files\LibreOffice\program\soffice.exe` (and the x86 variant)
- Linux: `/usr/bin/soffice`, `/usr/local/bin/soffice`, `/snap/bin/libreoffice`

To convert a `.doc` to `.docx` directly:

```bash
soffice --headless --convert-to docx input.doc
```

```powershell
& "C:\Program Files\LibreOffice\program\soffice.exe" --headless --convert-to docx input.doc
```

## Round-trip workflow

1. **Export** the Word document. The script runs pandoc and writes:
   - `<name>.md` — the Markdown source (pandoc GFM+extensions).
   - `<name>.assets/` — extracted images and media.
   - `<name>.reference.docx` — a copy of the original, used as pandoc's reference doc on rebuild to preserve styles.
   - `<name>.meta.json` — core properties, custom styles, comment threads, tracked-change authors, and raw XML for sections pandoc doesn't round-trip cleanly.
2. **Edit** the `.md` file. Standard Markdown, plus pandoc extensions (fenced divs, attribute blocks, footnotes). Comments and tracked changes are represented as Markdown inline annotations — see the format spec.
3. **Rebuild** to `.docx`. The script runs pandoc with the reference doc, then post-processes the output to reattach metadata from the sidecar.

The sidecar is what makes this high-fidelity. Keep all four artifacts together. If the sidecar is lost, the rebuild is still correct content-wise but loses comments and some style customizations.

## Markdown format

Full spec in `references/format-spec.md`. Highlights:

```markdown
---
title: Project Brief
author: Claude
reference_doc: brief.reference.docx
docx_meta: brief.meta.json
---

# Background

The project aims to ship a new onboarding flow by end of Q3.^[Source: roadmap v4.2]

## Scope

We will support:

- Self-serve sign-up with email verification
- SSO via Okta and Google Workspace
- A guided setup wizard with checkpoints

[This section needs sign-off from Legal.]{.comment author="Claude" date="2026-04-22"}

| Milestone | Target date | Owner |
| --- | --- | --- |
| Design review | 2026-05-02 | Priya |
| Engineering kickoff | 2026-05-09 | Jin |

![Flow diagram](brief.assets/flow.png){#fig-flow width=6in}

::: {.tracked-insertion author="Claude" date="2026-04-22"}
Added note: we also need to update the billing docs.
:::

::: {.tracked-deletion author="Claude" date="2026-04-22"}
Deprecated paragraph about the old signup.
:::
```

Conventions:

- YAML frontmatter carries document-level metadata (title, author, pointers to sidecar + reference doc).
- Pandoc-style footnotes with `^[...]`.
- Comments use a span with the `.comment` class: `[comment text]{.comment author="..." date="..."}`.
- Tracked changes use fenced divs with classes `.tracked-insertion` / `.tracked-deletion`.
- Pandoc-style attribute blocks on images let you pin width/height.

## Script usage

### `docx_to_md.py`

macOS / Linux (bash):

```bash
python scripts/docx_to_md.py report.docx report.md
python scripts/docx_to_md.py report.docx report.md --assets-dir media
python scripts/docx_to_md.py report.docx report.md --accept-changes
python scripts/docx_to_md.py report.docx report.md --no-meta
```

Windows (PowerShell):

```powershell
python scripts\docx_to_md.py report.docx report.md
python scripts\docx_to_md.py report.docx report.md --assets-dir media
python scripts\docx_to_md.py report.docx report.md --accept-changes
python scripts\docx_to_md.py report.docx report.md --no-meta
```

Options:

- `--assets-dir` — override the media folder (default: `<name>.assets`).
- `--accept-changes` — accept all tracked changes before converting (runs LibreOffice headlessly).
- `--no-meta` — skip the sidecar (lossy export).

### `md_to_docx.py`

macOS / Linux (bash):

```bash
python scripts/md_to_docx.py report.md report.docx
python scripts/md_to_docx.py report.md report.docx --reference-doc original.docx
python scripts/md_to_docx.py report.md report.docx --meta report.meta.json
```

Windows (PowerShell):

```powershell
python scripts\md_to_docx.py report.md report.docx
python scripts\md_to_docx.py report.md report.docx --reference-doc original.docx
python scripts\md_to_docx.py report.md report.docx --meta report.meta.json
```

Options:

- `--reference-doc` — override the reference doc used by pandoc for styles.
- `--meta` — override the sidecar location.
- `--skip-post-process` — skip re-injection of comments / tracked changes (useful for debugging).

### `roundtrip_check.py`

Exports, rebuilds, re-exports, and diffs the two Markdown files.

macOS / Linux (bash):

```bash
python scripts/roundtrip_check.py report.docx
```

Windows (PowerShell):

```powershell
python scripts\roundtrip_check.py report.docx
```

## Known limitations

- Complex legacy fields (MergeFields, linked content, macros) pass through only if they live in the reference doc.
- Equation content is preserved as OMath XML in the sidecar; in Markdown it appears as `<!-- equation id=N -->` placeholders.
- Tab stops, custom list numbering, and page-size overrides rely on the reference doc. Edit the reference doc (not the Markdown) to change them.
- Columns and section breaks are preserved via `::: {.section columns=2 break="page"}` fenced divs.

## Dependencies

Python deps are installed automatically by `setup_env.sh` / `setup_env.ps1` into the project-local `./.venv`. The list is in `scripts/requirements.txt`:

- `python-docx`
- `lxml`
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

System dependencies:

- `pandoc` (>= 2.18) — required for the docx ↔ md conversion. Install via `brew`, `apt`, `choco`, or [pandoc.org](https://pandoc.org/installing.html).
- LibreOffice (`soffice`) — optional, required only for `--accept-changes` and for `.doc` → `.docx` conversion. The scripts also look in standard install locations on macOS / Linux / Windows even when not on PATH.

## Composition with the base docx skill

If the user wants *visual* changes (heading styles, table themes, page size), update the reference doc using the base `docx` skill, then re-run the rebuild. This skill handles content translation; the base skill handles authoring.
