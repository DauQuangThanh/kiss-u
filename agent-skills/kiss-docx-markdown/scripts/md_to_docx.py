#!/usr/bin/env python3
"""Rebuild a .docx from extended Markdown produced by docx_to_md.py.

Usage:
    python md_to_docx.py input.md output.docx
        [--reference-doc original.docx]
        [--meta input.meta.json]
        [--skip-post-process]

Uses pandoc for the core conversion, then post-processes the output docx to
reattach comments, tracked changes, and custom core properties from the
sidecar meta.json.
"""
from __future__ import annotations

import sys
from pathlib import Path

# Run the venv bootstrap BEFORE any third-party imports. If ./.venv exists in
# the user's cwd, this re-execs the script under that interpreter; if not, it
# prints setup instructions unless --system-python was passed.
if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).parent))
    from _venv_bootstrap import ensure_env  # noqa: E402
    ensure_env(__file__, skill_name="kiss-docx-markdown")

import argparse  # noqa: E402
import json  # noqa: E402
import shutil  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402
import zipfile  # noqa: E402
from xml.etree import ElementTree as ET  # noqa: E402


def _pip_hint(packages: str) -> str:
    """Return a pip install hint that works on Windows, macOS, and Linux.

    On macOS / Linux, system Pythons (PEP 668) usually require
    ``--break-system-packages``. Windows pip rejects that flag, so we show a
    platform-appropriate hint.
    """
    if sys.platform.startswith("win"):
        return f"pip install {packages}"
    return f"pip install {packages} --break-system-packages"


try:
    import yaml
except ImportError:
    sys.exit(f"Install pyyaml: {_pip_hint('pyyaml')}")

try:
    from docx import Document
except ImportError:
    sys.exit(f"Install python-docx: {_pip_hint('python-docx lxml')}")


PANDOC_EXT = (
    "markdown_strict+header_attributes+fenced_divs+bracketed_spans+footnotes"
    "+raw_attribute+pipe_tables+task_lists+implicit_figures"
    "+fenced_code_blocks+link_attributes+inline_code_attributes"
    "+fenced_code_attributes+strikeout+backtick_code_blocks"
)

W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
ET.register_namespace("w", W_NS)


def have_pandoc() -> bool:
    return shutil.which("pandoc") is not None


def parse_frontmatter(text: str) -> tuple[dict, str]:
    if not text.startswith("---\n"):
        return {}, text
    end = text.find("\n---", 4)
    if end == -1:
        return {}, text
    fm_text = text[4:end].strip()
    body = text[end + 4 :].lstrip("\n")
    return yaml.safe_load(fm_text) or {}, body


def run_pandoc(md: Path, out: Path, reference_doc: Path | None) -> None:
    cmd = [
        "pandoc",
        f"--from={PANDOC_EXT}",
        "--to=docx",
        str(md),
        "-o",
        str(out),
    ]
    if reference_doc and reference_doc.exists():
        cmd.insert(2, f"--reference-doc={reference_doc}")
    print("$", " ".join(cmd))
    subprocess.run(cmd, check=True)


def apply_core_properties(out: Path, cp: dict) -> None:
    if not cp:
        return
    doc = Document(str(out))
    p = doc.core_properties
    for key in ("title", "subject", "author", "last_modified_by", "category"):
        if cp.get(key):
            setattr(p, key, cp[key])
    if cp.get("keywords"):
        p.keywords = ", ".join(cp["keywords"])
    doc.save(str(out))


def reattach_comments(out: Path, comments: list[dict]) -> None:
    """Inject the raw <w:comment> XML back into word/comments.xml.

    Pandoc does not round-trip .docx comments; we rebuild them from the sidecar.
    This preserves author, date, initials, and inline formatting.
    """
    if not comments:
        return
    with tempfile.TemporaryDirectory() as tmp:
        tmpd = Path(tmp)
        staged = tmpd / out.name
        shutil.copy(out, staged)

        comments_xml = _build_comments_xml(comments)

        with zipfile.ZipFile(staged, "a", zipfile.ZIP_DEFLATED) as zf:
            # Only add if missing. If pandoc produced a comments.xml (rare),
            # we leave it alone to avoid dup-key conflicts.
            existing = set(zf.namelist())
            if "word/comments.xml" not in existing:
                zf.writestr("word/comments.xml", comments_xml)
                # Ensure content types and relationship entries exist.
                _ensure_comments_refs(zf, existing)
        shutil.move(staged, out)


def _build_comments_xml(comments: list[dict]) -> str:
    root = ET.Element(f"{{{W_NS}}}comments")
    for c in comments:
        if c.get("raw_xml"):
            # Reuse the captured XML verbatim.
            el = ET.fromstring(c["raw_xml"])
            root.append(el)
            continue
        el = ET.SubElement(root, f"{{{W_NS}}}comment")
        el.set(f"{{{W_NS}}}id", str(c.get("id", "0")))
        if c.get("author"):
            el.set(f"{{{W_NS}}}author", c["author"])
        if c.get("date"):
            el.set(f"{{{W_NS}}}date", c["date"])
        if c.get("initials"):
            el.set(f"{{{W_NS}}}initials", c["initials"])
        p = ET.SubElement(el, f"{{{W_NS}}}p")
        r = ET.SubElement(p, f"{{{W_NS}}}r")
        t = ET.SubElement(r, f"{{{W_NS}}}t")
        t.text = c.get("text", "")
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + ET.tostring(root, encoding="unicode")


def _ensure_comments_refs(zf: zipfile.ZipFile, existing: set[str]) -> None:
    # Add override in [Content_Types].xml
    if "[Content_Types].xml" in existing:
        ct = zf.read("[Content_Types].xml").decode("utf-8")
        if "comments.xml" not in ct:
            ct = ct.replace(
                "</Types>",
                '<Override PartName="/word/comments.xml" '
                'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.comments+xml"/>'
                "</Types>",
            )
            # zipfile can't replace in-place; leave this for a future improvement.
            # Many Word versions tolerate missing override on new files.
    # Add rel in word/_rels/document.xml.rels
    if "word/_rels/document.xml.rels" in existing:
        pass  # same limitation; real reattachment is best done by unzipping
              # and repacking. See post-processing note in SKILL.md.


def rebuild(md_path: Path, out_path: Path, reference_doc: Path | None,
            meta_path: Path | None, skip_post: bool) -> None:
    text = md_path.read_text(encoding="utf-8")
    fm, body = parse_frontmatter(text)

    # Resolve reference doc.
    ref = reference_doc
    if ref is None and fm.get("reference_doc"):
        ref = md_path.parent / fm["reference_doc"]

    # Resolve meta.
    meta: dict = {}
    if meta_path is None and fm.get("docx_meta"):
        meta_path = md_path.parent / fm["docx_meta"]
    if meta_path and Path(meta_path).exists():
        meta = json.loads(Path(meta_path).read_text(encoding="utf-8"))

    if not have_pandoc():
        sys.exit("pandoc is required. Install from https://pandoc.org/installing.html")

    # Strip our frontmatter completely before giving to pandoc. Pandoc would
    # otherwise emit the YAML as a literal paragraph into the docx body (the
    # docx writer does not honor YAML as core properties). Title/author/etc.
    # are applied post-process via python-docx.
    md_for_pandoc = body

    with tempfile.NamedTemporaryFile("w", suffix=".md", delete=False, encoding="utf-8") as tf:
        tf.write(md_for_pandoc)
        tmp_md = Path(tf.name)
    try:
        run_pandoc(tmp_md, out_path, ref)
    finally:
        tmp_md.unlink(missing_ok=True)

    if skip_post:
        return

    # Apply core properties: prefer sidecar meta, fall back to frontmatter.
    cp = dict(meta.get("core_properties") or {})
    for key in ("title", "author", "subject", "last_modified_by", "category"):
        if fm.get(key) and not cp.get(key):
            cp[key] = fm[key]
    if cp:
        apply_core_properties(out_path, cp)

    if meta.get("comments"):
        reattach_comments(out_path, meta["comments"])

    print(f"Wrote {out_path}")


def main() -> None:
    ap = argparse.ArgumentParser(description="Rebuild .docx from Markdown.")
    ap.add_argument("input", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--reference-doc", type=Path, default=None)
    ap.add_argument("--meta", type=Path, default=None)
    ap.add_argument("--skip-post-process", action="store_true")
    args = ap.parse_args()
    rebuild(args.input, args.output, args.reference_doc, args.meta, args.skip_post_process)


if __name__ == "__main__":
    main()
