"""Version command and related functions."""

import importlib.metadata
from pathlib import Path


def get_kiss_version() -> str:
    """Get current kiss version."""
    try:
        return importlib.metadata.version("kiss")
    except importlib.metadata.PackageNotFoundError:
        # Fallback: try reading from pyproject.toml (development checkout).
        try:
            import tomllib
            pyproject_path = Path(__file__).parent.parent.parent / "pyproject.toml"
            if pyproject_path.exists():
                with open(pyproject_path, "rb") as f:
                    data = tomllib.load(f)
                    return data.get("project", {}).get("version", "unknown")
        except (OSError, tomllib.TOMLDecodeError):
            # Filesystem error or malformed pyproject.toml — fall through to "unknown".
            pass
    return "unknown"
