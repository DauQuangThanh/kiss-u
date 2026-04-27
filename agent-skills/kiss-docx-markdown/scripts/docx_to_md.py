#!/usr/bin/env python3
"""Convert .docx to extended Markdown + assets + reference-doc + meta.json.

Usage:
    python docx_to_md.py input.docx output.md [--assets-dir DIR]
                                               [--accept-changes]
                                               [--no-meta]

Requires pandoc on PATH. See ../references/format-spec.md for format.
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


def have_pandoc() -> bool:
    return shutil.which("pandoc") is not None


def find_soffice() -> str | None:
    """Locate LibreOffice's ``soffice`` executable across macOS, Linux, and Windows.

    Falls back to common install locations that are not always added to PATH
    (notably the macOS ``.app`` bundle and the standard Windows install dirs).
    """
    found = shutil.which("soffice") or shutil.which("libreoffice")
    if found:
        return found
    candidates: list[str] = []
    if sys.platform == "darwin":
        candidates += [
            "/Applications/LibreOffice.app/Contents/MacOS/soffice",
        ]
    elif sys.platform.startswith("win"):
        candidates += [
            r"C:\Program Files\LibreOffice\program\soffice.exe",
            r"C:\Program Files (x86)\LibreOffice\program\soffice.exe",
        ]
    else:
        candidates += [
            "/usr/bin/soffice",
            "/usr/local/bin/soffice",
            "/snap/bin/libreoffice",
        ]
    for c in candidates:
        if Path(c).exists():
            return c
    return None


def have_soffice() -> bool:
    return find_soffice() is not None


def accept_changes_inplace(src: Path) -> Path:
    """Use LibreOffice macro to accept all tracked changes. Returns new path."""
    soffice = find_soffice()
    if not soffice:
        sys.exit("LibreOffice (soffice) is required for --accept-changes")
    with tempfile.TemporaryDirectory() as tmp:
        tmpd = Path(tmp)
        staged = tmpd / src.name
        shutil.copy(src, staged)
        macro = (
            'macro:///Standard.Module1.AcceptAllChanges("' + str(staged) + '")'
        )
        # Simpler approach: run a headless conversion which keeps tracked changes intact.
        # Caller can instead use the `accept_changes.py` script from the base docx skill if
        # available. We write a bare-bones macro file here for convenience.
        subprocess.run(
            [
                soffice,
                "--headless",
                "--norestore",
                "--nocrashreport",
                "--nolockcheck",
                macro,
            ],
            check=False,
        )
        return staged


def run_pandoc_to_md(src: Path, dest: Path, assets_dir: Path) -> None:
    assets_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        "pandoc",
        "--from=docx+styles",
        f"--to={PANDOC_EXT}",
        "--wrap=none",
        f"--extract-media={assets_dir}",
        "--track-changes=all",
        str(src),
        "-o",
        str(dest),
    ]
    # Prefer ATX headings; option name changed across pandoc versions.
    for opt in ("--markdown-headings=atx", "--atx-headers"):
        trial = cmd[:1] + [opt] + cmd[1:]
        try:
            r = subprocess.run(trial, capture_output=True, text=True)
            if r.returncode == 0:
                print("$", " ".join(trial))
                return
        except Exception:
            pass
    print("$", " ".join(cmd))
    subprocess.run(cmd, check=True)


def extract_meta(src: Path) -> dict:
    doc = Document(str(src))
    core = doc.core_properties
    meta: dict = {
        "core_properties": {
            "title": core.title or "",
            "subject": core.subject or "",
            "author": core.author or "",
            "last_modified_by": core.last_modified_by or "",
            "created": core.created.isoformat() if core.created else "",
            "modified": core.modified.isoformat() if core.modified else "",
            "keywords": [k.strip() for k in (core.keywords or "").split(",") if k.strip()],
            "category": core.category or "",
            "revision": core.revision or 0,
        },
        "styles": {
            "paragraph_styles": sorted({
                p.style.name for p in doc.paragraphs if p.style and p.style.name
            }),
        },
        "comments": extract_comments(src),
        "tracked_changes": extract_tracked_changes(src),
    }
    return meta


def extract_comments(src: Path) -> list[dict]:
    """Read word/comments.xml and word/commentsExtended.xml from the docx zip."""
    import zipfile
    from xml.etree import ElementTree as ET

    ns = {
        "w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main",
        "w15": "http://schemas.microsoft.com/office/word/2012/wordml",
    }
    comments: list[dict] = []
    with zipfile.ZipFile(src) as zf:
        if "word/comments.xml" not in zf.namelist():
            return comments
        tree = ET.fromstring(zf.read("word/comments.xml"))
        parents: dict[str, str] = {}
        if "word/commentsExtended.xml" in zf.namelist():
            ext_tree = ET.fromstring(zf.read("word/commentsExtended.xml"))
            for ce in ext_tree.findall(".//w15:commentEx", ns):
                pid = ce.get("{%s}paraIdParent" % ns["w15"])
                own = ce.get("{%s}paraId" % ns["w15"])
                if pid and own:
                    parents[own] = pid
        for c in tree.findall("w:comment", ns):
            cid = c.get("{%s}id" % ns["w"])
            author = c.get("{%s}author" % ns["w"]) or ""
            initials = c.get("{%s}initials" % ns["w"]) or ""
            date = c.get("{%s}date" % ns["w"]) or ""
            text = " ".join(t.text or "" for t in c.iter("{%s}t" % ns["w"]))
            raw = ET.tostring(c, encoding="unicode")
            comments.append(
                {
                    "id": cid,
                    "author": author,
                    "initials": initials,
                    "date": date,
                    "text": text.strip(),
                    "raw_xml": raw,
                }
            )
    return comments


def extract_tracked_changes(src: Path) -> list[dict]:
    import zipfile
    from xml.etree import ElementTree as ET

    ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
    changes: list[dict] = []
    with zipfile.ZipFile(src) as zf:
        if "word/document.xml" not in zf.namelist():
            return changes
        tree = ET.fromstring(zf.read("word/document.xml"))
        for kind, tag in (("insertion", "ins"), ("deletion", "del")):
            for el in tree.iter("{%s}%s" % (ns["w"], tag)):
                changes.append(
                    {
                        "id": el.get("{%s}id" % ns["w"]) or "",
                        "kind": kind,
                        "author": el.get("{%s}author" % ns["w"]) or "",
                        "date": el.get("{%s}date" % ns["w"]) or "",
                    }
                )
    return changes


# Styles whose custom-style divs pandoc emits but which are semantically
# the default (bullet/numbered/body) — stripping them keeps the markdown
# readable and round-trip stable, because pandoc re-infers them on rebuild
# from the markdown structure itself.
_DEFAULT_CUSTOM_STYLES = {
    "Body Text",
    "Normal",
    "Default Paragraph Font",
    "List Bullet",
    "List Bullet 2",
    "List Bullet 3",
    "List Number",
    "List Number 2",
    "List Number 3",
    "List Paragraph",
    "Compact",
    "First Paragraph",
}


def _strip_default_custom_style_divs(text: str) -> str:
    """Remove pandoc's `::: {custom-style="X"} ... :::` wrappers when X is a
    default style that carries no extra semantics. Handles both top-level
    and list-item-nested wrappers.
    """
    import re

    # Pattern A: list-item wrapped fence, e.g.
    #   -   ::: {custom-style="List Bullet"}
    #       Self-serve sign-up
    #       :::
    # Collapse to:
    #   -   Self-serve sign-up
    list_fence_re = re.compile(
        r'(?m)^(?P<indent>\s*)(?P<marker>-|\d+\.)(?P<sp>\s+):::\s+\{custom-style="(?P<style>[^"]+)"\}\s*\n'
        r'(?P<body>(?:^(?P=indent)    [^\n]*\n)+)'
        r'^(?P=indent)    :::\s*\n'
    )

    def replace_list_fence(m: re.Match) -> str:
        style = m.group("style")
        if style not in _DEFAULT_CUSTOM_STYLES:
            return m.group(0)
        indent = m.group("indent")
        marker = m.group("marker")
        sp = m.group("sp")
        body_indent = indent + "    "
        body_lines = m.group("body").splitlines()
        # Strip the 4-space inner indent.
        dedented = [
            ln[len(body_indent):] if ln.startswith(body_indent) else ln
            for ln in body_lines
        ]
        if not dedented:
            return f"{indent}{marker}{sp}\n"
        first, *rest = dedented
        out = f"{indent}{marker}{sp}{first}\n"
        for r in rest:
            out += f"{body_indent}{r}\n"
        return out

    text = list_fence_re.sub(replace_list_fence, text)

    # Pattern B: top-level fence, e.g.
    #   ::: {custom-style="Body Text"}
    #   The project aims to ship onboarding by Q3.
    #   :::
    top_fence_re = re.compile(
        r'(?m)^(?P<indent>\s*):::\s+\{custom-style="(?P<style>[^"]+)"\}\s*\n'
        r'(?P<body>(?:(?!^(?P=indent):::\s*$)[^\n]*\n)*?)'
        r'^(?P=indent):::\s*\n'
    )

    def replace_top_fence(m: re.Match) -> str:
        style = m.group("style")
        if style not in _DEFAULT_CUSTOM_STYLES:
            return m.group(0)
        return m.group("body")

    text = top_fence_re.sub(replace_top_fence, text)
    return text


def _ensure_block_separation(text: str) -> str:
    """Ensure block-level elements (tables, headings, lists) have a blank line
    before them. Stripping custom-style divs can remove the wrapper that used
    to serve as that separator, so we re-insert blank lines where needed to
    keep pandoc round-tripping structure correctly.
    """
    import re

    lines = text.split("\n")
    out: list[str] = []
    for i, ln in enumerate(lines):
        is_table = ln.lstrip().startswith("|") and "|" in ln.lstrip()[1:]
        is_heading = re.match(r"^#{1,6}\s", ln) is not None
        if (is_table or is_heading) and out and out[-1] != "":
            prev = out[-1]
            # Don't insert a blank line between two table rows.
            if is_table and prev.lstrip().startswith("|"):
                pass
            else:
                out.append("")
        out.append(ln)
    return "\n".join(out)


def normalize_markdown(text: str) -> str:
    # Strip noisy default-style divs first.
    text = _strip_default_custom_style_divs(text)
    # Ensure tables/headings have a blank line before them.
    text = _ensure_block_separation(text)
    # LF line endings, no trailing whitespace.
    lines = [ln.rstrip() for ln in text.splitlines()]
    out = "\n".join(lines).rstrip() + "\n"
    # Collapse runs of 3+ blank lines into 2.
    import re
    out = re.sub(r"\n{3,}", "\n\n", out)
    return out


def inject_frontmatter(md_text: str, fm: dict) -> str:
    body = md_text
    if body.startswith("---\n"):
        end = body.find("\n---", 4)
        if end != -1:
            body = body[end + 4 :].lstrip("\n")
    header = "---\n" + yaml.safe_dump(fm, sort_keys=True, default_flow_style=False).rstrip() + "\n---\n\n"
    return header + body


def main() -> None:
    ap = argparse.ArgumentParser(description="Convert .docx to extended Markdown.")
    ap.add_argument("input", type=Path)
    ap.add_argument("output", type=Path)
    ap.add_argument("--assets-dir", type=Path, default=None)
    ap.add_argument("--accept-changes", action="store_true")
    ap.add_argument("--no-meta", action="store_true")
    args = ap.parse_args()

    if not have_pandoc():
        sys.exit("pandoc is required. Install from https://pandoc.org/installing.html")

    src = args.input.resolve()
    dest = args.output.resolve()
    basename = dest.stem
    assets_dir = (args.assets_dir or dest.parent / f"{basename}.assets").resolve()
    ref_path = dest.parent / f"{basename}.reference.docx"
    meta_path = dest.parent / f"{basename}.meta.json"

    if args.accept_changes:
        src = accept_changes_inplace(src)

    run_pandoc_to_md(src, dest, assets_dir)

    # Save a reference doc (a copy of the original) for later rebuilds.
    shutil.copy(args.input, ref_path)

    md_text = dest.read_text(encoding="utf-8")
    md_text = normalize_markdown(md_text)

    fm: dict = {}
    if not args.no_meta:
        meta = extract_meta(args.input)
        meta_path.write_text(json.dumps(meta, indent=2, sort_keys=True), encoding="utf-8")
        cp = meta["core_properties"]
        fm = {
            "title": cp.get("title", ""),
            "author": cp.get("author", ""),
            "created": cp.get("created", ""),
            "modified": cp.get("modified", ""),
            "reference_doc": ref_path.name,
            "docx_meta": meta_path.name,
        }
    else:
        fm = {"reference_doc": ref_path.name}
    md_text = inject_frontmatter(md_text, fm)
    dest.write_text(md_text, encoding="utf-8")

    print(f"Wrote {dest}")
    print(f"  assets        -> {assets_dir}")
    print(f"  reference doc -> {ref_path}")
    if not args.no_meta:
        print(f"  meta          -> {meta_path}")


if __name__ == "__main__":
    main()
