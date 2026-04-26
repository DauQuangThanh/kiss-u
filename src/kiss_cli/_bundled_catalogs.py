"""Helpers for reading the bundled-only catalog JSON files.

kiss is fully offline (Phase 4): the installed package ships with one
``catalog.json`` per asset kind (presets / extensions / workflows / integrations),
and those files are the only catalogs the CLI ever reads.  There is no
``--remote`` flag, no community catalog, and no network fetch of any kind.

This module centralises the lookup so every catalog module reads from the
same well-known locations:

* wheel install → ``kiss_cli/core_pack/<kind>/catalog.json``
* source-checkout / editable install → repo-root ``<kind>/catalog.json``
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, Literal

CatalogKind = Literal["presets", "extensions", "workflows", "integrations"]

# Sentinel URL surfaced to code that still expects a "url" field on catalog
# entries.  Never dereferenced as a real URL — kiss is offline.
BUNDLED_CATALOG_URL = "bundled://kiss"


def _locate_bundled_catalog_file(kind: CatalogKind) -> Path | None:
    """Return the filesystem path to the bundled catalog.json for *kind*, or None.

    Checks the wheel-install location first (``kiss_cli/core_pack/<kind>/catalog.json``),
    then the source-checkout location (``<repo-root>/<kind>/catalog.json``).
    """
    # Wheel install: core_pack is a sibling directory of this file
    wheel_candidate = Path(__file__).parent / "core_pack" / kind / "catalog.json"
    if wheel_candidate.is_file():
        return wheel_candidate

    # Source-checkout / editable install: <repo-root>/<kind>/catalog.json
    repo_root = Path(__file__).parent.parent.parent
    source_candidate = repo_root / kind / "catalog.json"
    if source_candidate.is_file():
        return source_candidate

    return None


def load_bundled_catalog(kind: CatalogKind) -> Dict[str, Any]:
    """Load and parse the bundled catalog.json for *kind*.

    Returns an empty skeleton (``{"schema_version": "1.0", "<kind>": {}}``) when
    the bundled file is missing, so downstream search/list operations degrade
    gracefully rather than raising.
    """
    path = _locate_bundled_catalog_file(kind)
    if path is None:
        # Key name inside the JSON differs by kind (e.g. "presets", "extensions"),
        # so we return a skeleton that downstream code can iterate as empty.
        return {"schema_version": "1.0", kind: {}}
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return {"schema_version": "1.0", kind: {}}
