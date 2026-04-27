#!/usr/bin/env python3
"""Round-trip sanity check: xlsx -> md -> xlsx -> md, diff the two markdowns."""
from __future__ import annotations

import sys
from pathlib import Path

# Run the venv bootstrap BEFORE any third-party imports. Re-execing under the
# venv ensures the subprocess calls below also use the venv's Python.
if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).parent))
    from venv_bootstrap import ensure_env  # noqa: E402
    ensure_env(__file__, skill_name="kiss-xlsx-markdown")

import argparse  # noqa: E402
import difflib  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402


def run(cmd: list[str]) -> None:
    print("$", " ".join(cmd))
    subprocess.run(cmd, check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("xlsx", type=Path)
    args = ap.parse_args()
    script_dir = Path(__file__).parent
    with tempfile.TemporaryDirectory() as tmp:
        tmpd = Path(tmp)
        md1 = tmpd / "wb.md"
        xlsx2 = tmpd / "wb2.xlsx"
        md2 = tmpd / "wb2.md"
        run([sys.executable, str(script_dir / "xlsx_to_md.py"), str(args.xlsx), str(md1)])
        run([sys.executable, str(script_dir / "md_to_xlsx.py"), str(md1), str(xlsx2),
             "--template", str(args.xlsx)])
        run([sys.executable, str(script_dir / "xlsx_to_md.py"), str(xlsx2), str(md2)])
        a = md1.read_text(encoding="utf-8").splitlines()
        b = md2.read_text(encoding="utf-8").splitlines()
        diff = list(difflib.unified_diff(a, b, fromfile="first-export", tofile="second-export", lineterm=""))
        if diff:
            print("\n".join(diff))
            sys.exit(1)
        print("Round-trip identical.")


if __name__ == "__main__":
    main()
