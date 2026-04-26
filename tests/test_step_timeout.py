"""Tests for per-step timeout override in workflow steps (WP-1, WP-2, US-3)."""

import subprocess
from typing import Any
from unittest.mock import MagicMock, patch

import pytest

from kiss_cli.workflows.base import StepContext, StepStatus


def _make_context(tmp_path) -> StepContext:
    return StepContext(
        inputs={},
        default_integration="claude",
        project_root=str(tmp_path),
    )


# ---------------------------------------------------------------------------
# US-1: Command step timeout override
# ---------------------------------------------------------------------------


class TestCommandStepTimeout:
    """Tests for timeout field on command steps."""

    def test_custom_timeout_passed_to_dispatch(self, tmp_path):
        """T002: timeout: 1800 in config → dispatch_command gets timeout=1800."""
        from kiss_cli.workflows.steps.command import CommandStep

        step = CommandStep()
        ctx = _make_context(tmp_path)
        config = {
            "id": "test",
            "command": "kiss.implement",
            "timeout": 1800,
        }

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.wait.return_value = None

        with patch("kiss_cli.workflows.steps.command.shutil.which", return_value="/usr/local/bin/claude"), \
             patch("subprocess.Popen", return_value=mock_proc) as mock_popen:
            step.execute(config, ctx)

        # Verify dispatch_command was called — check Popen.wait got the timeout
        mock_proc.wait.assert_called_once_with(timeout=1800)

    def test_default_timeout_when_not_specified(self, tmp_path):
        """T003: No timeout in config → dispatch_command gets default 600."""
        from kiss_cli.workflows.steps.command import CommandStep

        step = CommandStep()
        ctx = _make_context(tmp_path)
        config = {
            "id": "test",
            "command": "kiss.specify",
        }

        mock_proc = MagicMock()
        mock_proc.returncode = 0
        mock_proc.wait.return_value = None

        with patch("kiss_cli.workflows.steps.command.shutil.which", return_value="/usr/local/bin/claude"), \
             patch("subprocess.Popen", return_value=mock_proc):
            step.execute(config, ctx)

        mock_proc.wait.assert_called_once_with(timeout=600)


# ---------------------------------------------------------------------------
# US-2: Shell step timeout override
# ---------------------------------------------------------------------------


class TestShellStepTimeout:
    """Tests for timeout field on shell steps."""

    def test_custom_timeout_passed_to_subprocess(self, tmp_path):
        """T005: timeout: 60 in config → subprocess.run gets timeout=60."""
        from kiss_cli.workflows.steps.shell import ShellStep

        step = ShellStep()
        ctx = _make_context(tmp_path)
        config = {"id": "lint", "run": "echo ok", "timeout": 60}

        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=0, stdout="ok", stderr="")
            step.execute(config, ctx)

        mock_run.assert_called_once()
        assert mock_run.call_args.kwargs.get("timeout") == 60

    def test_default_timeout_when_not_specified(self, tmp_path):
        """T006: No timeout in config → subprocess.run gets default 300."""
        from kiss_cli.workflows.steps.shell import ShellStep

        step = ShellStep()
        ctx = _make_context(tmp_path)
        config = {"id": "lint", "run": "echo ok"}

        with patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=0, stdout="ok", stderr="")
            step.execute(config, ctx)

        assert mock_run.call_args.kwargs.get("timeout") == 300

    def test_timeout_error_message_shows_actual_value(self, tmp_path):
        """T007: Timeout error message uses actual value, not hard-coded."""
        from kiss_cli.workflows.steps.shell import ShellStep

        step = ShellStep()
        ctx = _make_context(tmp_path)
        config = {"id": "slow", "run": "sleep 999", "timeout": 45}

        with patch("subprocess.run", side_effect=subprocess.TimeoutExpired(cmd="sleep", timeout=45)):
            result = step.execute(config, ctx)

        assert result.status == StepStatus.FAILED
        assert "45" in result.error


# ---------------------------------------------------------------------------
# US-3: Validation
# ---------------------------------------------------------------------------


class TestTimeoutValidation:
    """Tests for timeout validation on both step types."""

    def test_command_rejects_negative_timeout(self):
        """T010: timeout: -1 → validation error."""
        from kiss_cli.workflows.steps.command import CommandStep
        step = CommandStep()
        errors = step.validate({"id": "x", "command": "kiss.plan", "timeout": -1})
        assert any("timeout" in e.lower() for e in errors)

    def test_command_rejects_string_timeout(self):
        """T011: timeout: "fast" → validation error."""
        from kiss_cli.workflows.steps.command import CommandStep
        step = CommandStep()
        errors = step.validate({"id": "x", "command": "kiss.plan", "timeout": "fast"})
        assert any("timeout" in e.lower() for e in errors)

    def test_shell_rejects_zero_timeout(self):
        """T012: timeout: 0 → validation error."""
        from kiss_cli.workflows.steps.shell import ShellStep
        step = ShellStep()
        errors = step.validate({"id": "x", "run": "echo", "timeout": 0})
        assert any("timeout" in e.lower() for e in errors)

    def test_valid_timeout_accepted(self):
        """T013: timeout: 1800 → no validation error."""
        from kiss_cli.workflows.steps.command import CommandStep
        from kiss_cli.workflows.steps.shell import ShellStep

        cmd_errors = CommandStep().validate({"id": "x", "command": "kiss.plan", "timeout": 1800})
        sh_errors = ShellStep().validate({"id": "x", "run": "echo", "timeout": 1800})

        timeout_errors = [e for e in cmd_errors + sh_errors if "timeout" in e.lower()]
        assert timeout_errors == []
