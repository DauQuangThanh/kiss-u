"""Tests for dispatch_command timeout enforcement (WP-5)."""

import subprocess
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest


class TestDispatchTimeout:
    """Timeout behavior of IntegrationBase.dispatch_command."""

    def _make_integration(self):
        """Create a minimal integration instance for testing."""
        from kiss_cli.integrations.base import IntegrationBase

        class FakeIntegration(IntegrationBase):
            key = "fake"
            config = {"name": "Fake"}
            context_file = "FAKE.md"

            def setup(self, *a, **kw):
                pass

            def teardown(self, *a, **kw):
                pass

            def build_exec_args(self, prompt, **kw):
                return ["sleep", "999"]

        return FakeIntegration()

    def test_streaming_timeout_kills_process(self):
        """T038: Streaming dispatch that exceeds timeout returns exit 124."""
        integration = self._make_integration()

        with patch("subprocess.Popen") as mock_popen:
            mock_proc = MagicMock()
            mock_proc.wait.side_effect = subprocess.TimeoutExpired(
                cmd="sleep", timeout=1
            )
            mock_proc.terminate = MagicMock()
            mock_proc.kill = MagicMock()
            # After kill, wait succeeds
            mock_proc.wait.side_effect = [
                subprocess.TimeoutExpired(cmd="sleep", timeout=1),
                None,
            ]
            mock_popen.return_value = mock_proc

            result = integration.dispatch_command(
                "test", timeout=1, stream=True
            )

        assert result["exit_code"] == 124
        mock_proc.terminate.assert_called_once()

    def test_streaming_within_timeout_succeeds(self):
        """T039: Streaming dispatch within timeout returns normal exit."""
        integration = self._make_integration()

        with patch("subprocess.Popen") as mock_popen:
            mock_proc = MagicMock()
            mock_proc.wait.return_value = None
            mock_proc.returncode = 0
            mock_popen.return_value = mock_proc

            result = integration.dispatch_command(
                "test", timeout=600, stream=True
            )

        assert result["exit_code"] == 0

    def test_sigterm_grace_period(self):
        """T040: Process responds to SIGTERM within 5s → clean shutdown."""
        integration = self._make_integration()

        with patch("subprocess.Popen") as mock_popen:
            mock_proc = MagicMock()
            # First wait: timeout (triggers kill flow)
            # Second wait (after terminate): succeeds (process exited on SIGTERM)
            mock_proc.wait.side_effect = [
                subprocess.TimeoutExpired(cmd="sleep", timeout=1),
                None,  # terminate() worked within 5s
            ]
            mock_proc.returncode = -15  # SIGTERM
            mock_popen.return_value = mock_proc

            result = integration.dispatch_command(
                "test", timeout=1, stream=True
            )

        assert result["exit_code"] == 124
        mock_proc.terminate.assert_called_once()
        # kill should NOT be called if terminate worked
        mock_proc.kill.assert_not_called()

    def test_timeout_prints_error_message(self, capsys):
        """T041: Timeout prints message to stderr."""
        integration = self._make_integration()

        with patch("subprocess.Popen") as mock_popen:
            mock_proc = MagicMock()
            mock_proc.wait.side_effect = [
                subprocess.TimeoutExpired(cmd="sleep", timeout=5),
                None,
            ]
            mock_popen.return_value = mock_proc

            integration.dispatch_command("mycommand", timeout=5, stream=True)

        captured = capsys.readouterr()
        assert "timed out after 5s" in captured.err
        assert "mycommand" in captured.err
