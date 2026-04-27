#!/usr/bin/env python3
"""Cross-platform virtual-environment bootstrap helper for kiss-* skills.

Each kiss-* skill (kiss-pptx-markdown / kiss-docx-markdown / kiss-xlsx-markdown)
prefers to run inside a project-local ``.venv`` so it does not pollute the
user's system Python install.

Convention: ``./.venv`` lives in the user's *current working directory*
(typically the workspace where the .pptx / .docx / .xlsx files live), not in
the skill directory. This matches the standard Python-project pattern and is
what ``setup_env.sh`` / ``setup_env.ps1`` create.

Usage from a script (call before any third-party imports):

    if __name__ == "__main__":
        from pathlib import Path
        import sys
        sys.path.insert(0, str(Path(__file__).parent))
        from venv_bootstrap import ensure_env
        ensure_env(__file__, skill_name="kiss-xlsx-markdown")

Behaviour:

- If ``./.venv/<bin>/python`` exists and we are *not* already running with
  it, re-execute the calling script using that interpreter. The user's
  args are forwarded; the original process exits with the child's status.
- If ``./.venv`` does not exist:
    * pass ``--system-python`` on the command line to fall back to the
      current interpreter (the flag is consumed before argparse sees it),
    * otherwise print a clear setup hint (bash + PowerShell) and exit 2.

The helper handles macOS, Linux, and Windows path conventions in a single
implementation.
"""
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


SYSTEM_PYTHON_FLAG = "--system-python"


def _venv_python_in_cwd() -> Path | None:
    """Return ./.venv's python if it exists, else None.

    Looks at the user's current working directory (Path.cwd()), NOT the
    script's directory. The convention is that ``.venv`` lives next to the
    user's working files.
    """
    venv_dir = Path.cwd() / ".venv"
    if not venv_dir.is_dir():
        return None
    if sys.platform.startswith("win"):
        candidate = venv_dir / "Scripts" / "python.exe"
    else:
        candidate = venv_dir / "bin" / "python"
    return candidate if candidate.is_file() else None


def _is_running_with(target: Path) -> bool:
    """True if sys.executable resolves to the same file as ``target``."""
    try:
        return Path(sys.executable).resolve() == target.resolve()
    except OSError:
        return False


def _setup_hint(skill_name: str) -> str:
    return (
        f"\n[{skill_name}] No virtual environment found at ./.venv\n"
        f"  (current dir: {Path.cwd()})\n\n"
        "These scripts prefer to run inside a project-local venv so they do\n"
        "not pollute your system Python install.\n\n"
        "Set one up by running the bootstrap helper for this skill:\n\n"
        "  macOS / Linux (bash):\n"
        "    bash <skill-dir>/scripts/bash/setup_env.sh\n\n"
        "  Windows (PowerShell):\n"
        "    pwsh <skill-dir>\\scripts\\powershell\\setup_env.ps1\n\n"
        "Then re-run your command. The .venv will be created in the current\n"
        "working directory.\n\n"
        f"If you really want to run against the system Python, pass {SYSTEM_PYTHON_FLAG}.\n"
    )


def ensure_env(caller_path: str, skill_name: str = "kiss-* skill") -> None:
    """Re-exec into ./.venv if available, or warn if not.

    Call this near the top of a script's ``__main__`` block, before importing
    any third-party dependencies (otherwise an ImportError on the system
    Python could fire even when a perfectly good venv exists).

    Strips ``--system-python`` from ``sys.argv`` after handling so downstream
    argparse calls do not see it.
    """
    use_system = SYSTEM_PYTHON_FLAG in sys.argv
    if use_system:
        sys.argv.remove(SYSTEM_PYTHON_FLAG)

    venv_py = _venv_python_in_cwd()
    if venv_py is not None and not _is_running_with(venv_py):
        # Re-execute under the venv's Python. subprocess.run + sys.exit
        # works the same way on POSIX and Windows, unlike os.execv.
        cmd = [str(venv_py), caller_path, *sys.argv[1:]]
        completed = subprocess.run(cmd)
        sys.exit(completed.returncode)

    if venv_py is None and not use_system:
        sys.stderr.write(_setup_hint(skill_name))
        sys.exit(2)
    # Either we are already in the venv, or the user opted into system Python.
    return None


__all__ = ["ensure_env", "SYSTEM_PYTHON_FLAG"]
