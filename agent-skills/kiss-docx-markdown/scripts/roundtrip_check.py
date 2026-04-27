#!/usr/bin/env python3
"""Round-trip sanity check: docx -> md -> docx -> md, diff the two markdowns."""
from __future__ import annotations

import sys
from pathlib import Path

# Run the venv bootstrap BEFORE any third-party imports. Re-execing under the
# venv ensures the subprocess calls below also use the venv's Python.
if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).parent))
    from _venv_bootstrap import ensure_env  # noqa: E402
    ensure_env(__file__, skill_name="kiss-docx-markdown")

import argparse  # noqa: E402
import difflib  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402


def run(cmd: list[str]) -> None:
    print("$", " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("docx", type=Path)
    args = ap.parse_args()

    script_dir = Path(__file__).parent
    with tempfile.TemporaryDirectory() as tmp:
        tmpd = Path(tmp)
        md1 = tmpd / "doc.md"
        docx2 = tmpd / "doc2.docx"
        md2 = tmpd / "doc2.md"

        run([sys.executable, str(script_dir / "docx_to_md.py"), str(args.docx), str(md1)])
        run([sys.executable, str(script_dir / "md_to_docx.py"), str(md1), str(docx2)])
        run([sys.executable, str(script_dir / "docx_to_md.py"), str(docx2), str(md2)])

        a = md1.read_text(encoding="utf-8").splitlines()
        b = md2.read_text(encoding="utf-8").splitlines()
        diff = list(difflib.unified_diff(
            a, b, fromfile="first-export", tofile="second-export", lineterm=""
        ))
        if diff:
            print("\n".join(diff))
            sys.exit(1)
        print("Round-trip identical.")


if __name__ == "__main__":
    main()
