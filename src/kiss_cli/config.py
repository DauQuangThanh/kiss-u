"""Init options configuration management for kiss projects."""

import json
from pathlib import Path
from typing import Any

INIT_OPTIONS_FILE = ".kiss/init-options.json"


def save_init_options(project_path: Path, options: dict[str, Any]) -> None:
    """Persist the CLI options used during ``kiss init``.

    Writes a small JSON file to ``.kiss/init-options.json`` so that
    later operations (e.g. preset install) can adapt their behaviour
    without scanning the filesystem.
    """
    dest = project_path / INIT_OPTIONS_FILE
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(json.dumps(options, indent=2, sort_keys=True), encoding="utf-8")


def load_init_options(project_path: Path) -> dict[str, Any]:
    """Load the init options previously saved by ``kiss init``.

    Returns an empty dict if the file does not exist or cannot be parsed.
    """
    path = project_path / INIT_OPTIONS_FILE
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return {}
