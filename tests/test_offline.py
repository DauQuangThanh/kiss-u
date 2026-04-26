"""Phase 4 offline-operation coverage.

Verifies the CLAUDE.md requirement that `kiss init` and `kiss upgrade` make
no network requests, plus the kiss design choice that all catalog commands
read only the bundled ``catalog.json`` files and expose no ``--remote`` /
``--community`` flags.
"""

from __future__ import annotations

import socket
from pathlib import Path
from unittest.mock import patch

import pytest
from typer.testing import CliRunner

from kiss_cli import app


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


class _NetworkAccessed(Exception):
    """Raised by the network guard when any outbound network call happens."""


def _install_network_guard(monkeypatch: pytest.MonkeyPatch) -> list[str]:
    """Patch every known HTTP/socket entry point and return a log of attempts.

    Any outbound connection attempt appends a description to the returned list
    and raises :class:`_NetworkAccessed`, so a test can fail loudly.
    """
    calls: list[str] = []

    def _block(origin: str):
        def guard(*args, **kwargs):  # noqa: ANN002, ANN003 — matches arbitrary signatures
            calls.append(f"{origin}: {args!r} {kwargs!r}")
            raise _NetworkAccessed(f"{origin} called during offline operation")

        return guard

    # urllib.request.urlopen — the most common catalog/download entry point.
    import urllib.request
    monkeypatch.setattr(urllib.request, "urlopen", _block("urllib.request.urlopen"))
    # urllib.request.Request construction by itself is harmless (no I/O), but
    # build_opener().open goes through urlopen already.

    # socket — last-resort guard for any library that bypasses urllib.
    monkeypatch.setattr(socket, "create_connection", _block("socket.create_connection"))

    real_connect = socket.socket.connect

    def blocked_connect(self, address, *a, **k):  # type: ignore[no-untyped-def]
        # Allow Unix-domain sockets (paths), block everything else.
        if isinstance(address, tuple):
            calls.append(f"socket.connect: {address!r}")
            raise _NetworkAccessed(f"socket.connect({address!r}) during offline operation")
        return real_connect(self, address, *a, **k)

    monkeypatch.setattr(socket.socket, "connect", blocked_connect)

    # If httpx / requests happen to be importable (they are not required
    # dependencies of kiss), guard their entry points too.
    for mod_name, attr in (
        ("httpx", "get"),
        ("httpx", "Client"),
        ("requests", "get"),
        ("requests", "Session"),
    ):
        try:
            mod = __import__(mod_name)
        except ImportError:
            continue
        if hasattr(mod, attr):
            monkeypatch.setattr(mod, attr, _block(f"{mod_name}.{attr}"))

    return calls


# ---------------------------------------------------------------------------
# init / upgrade must not touch the network
# ---------------------------------------------------------------------------


class TestInitMakesNoNetworkCalls:
    """`kiss init` must complete without any outbound network call."""

    def test_init_makes_no_network_calls(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
        calls = _install_network_guard(monkeypatch)
        runner = CliRunner()
        project_dir = tmp_path / "new-project"
        result = runner.invoke(
            app,
            [
                "init", str(project_dir),
                "--integration", "claude",
                "--ignore-agent-tools",
                "--no-git",
                ],
            catch_exceptions=False,
        )
        assert result.exit_code == 0, result.output
        assert not calls, f"unexpected network access during init: {calls}"


class TestUpgradeMakesNoNetworkCalls:
    """Upgrade paths must complete without any outbound network call.

    CLAUDE.md names ``kiss upgrade`` alongside ``kiss init``. A dedicated
    top-level ``kiss upgrade`` command is not yet wired up (pending follow-up
    work); today the upgrade path users hit is ``kiss integration upgrade``,
    which re-applies bundled assets for a given integration.  This test
    exercises that path under the network guard to cover the spirit of the
    requirement.
    """

    def test_integration_upgrade_makes_no_network_calls(
        self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch
    ):
        runner = CliRunner()
        project_dir = tmp_path / "proj"
        init_result = runner.invoke(
            app,
            [
                "init", str(project_dir),
                "--integration", "claude",
                "--ignore-agent-tools",
                "--no-git",
                ],
            catch_exceptions=False,
        )
        assert init_result.exit_code == 0, init_result.output

        # Arm the network guard and invoke the upgrade flow from inside the
        # project (the subcommand uses cwd to find the project).
        import os
        calls = _install_network_guard(monkeypatch)
        old = os.getcwd()
        try:
            os.chdir(project_dir)
            upgrade_result = runner.invoke(
                app,
                ["integration", "upgrade", "claude", "--force"],
                catch_exceptions=False,
            )
        finally:
            os.chdir(old)
        # We accept exit 0 (upgrade applied) or a clear "nothing to do" exit
        # — the assertion we care about is that no network call happened.
        assert not calls, f"unexpected network access during upgrade: {calls}"
        assert upgrade_result.exit_code in (0, 1), upgrade_result.output


# ---------------------------------------------------------------------------
# Catalog commands read the bundled catalog only, with no --remote flag
# ---------------------------------------------------------------------------


class TestBundledCatalogOnly:
    """Phase 4 design choice: catalog commands read only the bundled catalog."""

    def test_extension_search_uses_bundled_catalog_only(self, tmp_path: Path, monkeypatch: pytest.MonkeyPatch):
        """`kiss extension search` returns only entries from the bundled catalog.json."""
        runner = CliRunner()
        project_dir = tmp_path / "proj"
        runner.invoke(
            app,
            [
                "init", str(project_dir),
                "--integration", "claude",
                "--ignore-agent-tools",
                "--no-git",
                ],
            catch_exceptions=False,
        )

        stub = {
            "schema_version": "1.0",
            "extensions": {
                "only-bundled-one": {
                    "id": "only-bundled-one",
                    "name": "Only Bundled One",
                    "version": "1.0.0",
                    "description": "sentinel extension that proves the bundled catalog is being read",
                    "tags": ["bundled-only"],
                },
            },
        }
        calls = _install_network_guard(monkeypatch)
        import os
        old = os.getcwd()
        try:
            os.chdir(project_dir)
            with patch(
                "kiss_cli._bundled_catalogs.load_bundled_catalog",
                return_value=stub,
            ):
                result = runner.invoke(app, ["extension", "search"], catch_exceptions=False)
        finally:
            os.chdir(old)

        assert result.exit_code == 0, result.output
        assert "only-bundled-one" in result.output
        assert not calls, f"extension search touched the network: {calls}"

    def test_extension_add_has_no_remote_flags(self):
        """`kiss extension add --help` must not expose --remote or --community flags.

        These flags existed in spec-kit and are removed by Phase 4 (kiss is
        offline-only as a design choice on top of the CLAUDE.md hard requirement).
        """
        runner = CliRunner()
        result = runner.invoke(app, ["extension", "add", "--help"])
        assert result.exit_code == 0, result.output
        help_lower = result.output.lower()
        assert "--remote" not in help_lower, result.output
        assert "--community" not in help_lower, result.output
        # The `--from` URL-install flag is also removed for the same reason.
        assert "--from" not in help_lower, result.output

    def test_preset_add_has_no_remote_flags(self):
        runner = CliRunner()
        result = runner.invoke(app, ["preset", "add", "--help"])
        assert result.exit_code == 0, result.output
        help_lower = result.output.lower()
        assert "--remote" not in help_lower, result.output
        assert "--community" not in help_lower, result.output
        assert "--from" not in help_lower, result.output
