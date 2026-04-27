#!/usr/bin/env python3
"""Round-trip sanity check: pptx -> md -> pptx, compare text + structure.

Exits non-zero if the re-exported Markdown differs from the first export.
Useful in CI or as a QA step after edits.
"""
from __future__ import annotations

import sys
from pathlib import Path

# Run the venv bootstrap BEFORE any third-party imports. If ./.venv exists in
# the user's cwd, this re-execs the script under that interpreter; if not, it
# prints setup instructions unless --system-python was passed. Re-execing
# under the venv ensures the subprocess calls below also use the venv's Python.
if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).parent))
    from venv_bootstrap import ensure_env  # noqa: E402
    ensure_env(__file__, skill_name="kiss-pptx-markdown")

import argparse  # noqa: E402
import difflib  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402


def run(cmd: list[str]) -> None:
    print("$", " ".join(cmd))
    r = subprocess.run(cmd, check=False)
    if r.returncode != 0:
        sys.exit(r.returncode)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("pptx", type=Path)
    args = ap.parse_args()

    script_dir = Path(__file__).parent
    with tempfile.TemporaryDirectory() as tmp:
        tmpd = Path(tmp)
        md1 = tmpd / "deck.md"
        pptx2 = tmpd / "deck2.pptx"
        md2 = tmpd / "deck2.md"

        run([sys.executable, str(script_dir / "pptx_to_md.py"), str(args.pptx), str(md1)])
        run([sys.executable, str(script_dir / "md_to_pptx.py"), str(md1), str(pptx2),
             "--template", str(args.pptx)])
        run([sys.executable, str(script_dir / "pptx_to_md.py"), str(pptx2), str(md2)])

        a = md1.read_text(encoding="utf-8").splitlines()
        b = md2.read_text(encoding="utf-8").splitlines()
        diff = list(difflib.unified_diff(a, b, fromfile="first-export", tofile="second-export", lineterm=""))
        if diff:
            print("\n".join(diff))
            sys.exit(1)
        print("Round-trip identical (text + structure).")


if __name__ == "__main__":
    main()
