"""Command step — dispatches a kiss command to an integration CLI."""

from __future__ import annotations

import shutil
from pathlib import Path
from typing import Any

from kiss_cli.workflows.base import StepBase, StepContext, StepResult, StepStatus
from kiss_cli.workflows.expressions import evaluate_expression


class CommandStep(StepBase):
    """Default step type — invokes a kiss command via the integration CLI.

    The command files (skills, markdown, TOML) are already installed in
    the integration's directory on disk.  This step tells the CLI to
    execute the command by name (e.g. ``/kiss.specify`` or
    ``/kiss-specify``) rather than reading the file contents.

    .. note::

        CLI output is streamed to the terminal for live progress.
        ``output.exit_code`` is always captured and can be referenced
        by later steps (e.g. ``{{ steps.kiss.output.exit_code }}``).
        Full ``stdout``/``stderr`` capture is a planned enhancement.
    """

    type_key = "command"

    def execute(self, config: dict[str, Any], context: StepContext) -> StepResult:
        command = config.get("command", "")
        input_data = config.get("input", {})

        # Resolve expressions in input
        resolved_input: dict[str, Any] = {}
        for key, value in input_data.items():
            resolved_input[key] = evaluate_expression(value, context)

        # Resolve integration (step → workflow default → project default)
        integration = config.get("integration") or context.default_integration
        if integration and isinstance(integration, str) and "{{" in integration:
            integration = evaluate_expression(integration, context)

        # Resolve model
        model = config.get("model") or context.default_model
        if model and isinstance(model, str) and "{{" in model:
            model = evaluate_expression(model, context)

        # Merge options (workflow defaults ← step overrides)
        options = dict(context.default_options)
        step_options = config.get("options", {})
        if step_options:
            options.update(step_options)

        # Attempt CLI dispatch
        args_str = str(resolved_input.get("args", ""))
        timeout = config.get("timeout", 600)
        dispatch_result = self._try_dispatch(
            command, integration, model, args_str, context, timeout=timeout
        )

        output: dict[str, Any] = {
            "command": command,
            "integration": integration,
            "model": model,
            "options": options,
            "input": resolved_input,
        }

        if dispatch_result is not None:
            output["exit_code"] = dispatch_result["exit_code"]
            output["stdout"] = dispatch_result["stdout"]
            output["stderr"] = dispatch_result["stderr"]
            output["dispatched"] = True
            if dispatch_result["exit_code"] != 0:
                return StepResult(
                    status=StepStatus.FAILED,
                    output=output,
                    error=dispatch_result["stderr"] or f"Command exited with code {dispatch_result['exit_code']}",
                )
            return StepResult(
                status=StepStatus.COMPLETED,
                output=output,
            )
        else:
            output["exit_code"] = 1
            output["dispatched"] = False
            return StepResult(
                status=StepStatus.FAILED,
                output=output,
                error=(
                    f"Cannot dispatch command {command!r}: "
                    f"integration {integration!r} CLI not found or not installed. "
                    f"Install the CLI tool or check 'kiss integration list'."
                ),
            )

    @staticmethod
    def _try_dispatch(
        command: str,
        integration_key: str | None,
        model: str | None,
        args: str,
        context: StepContext,
        timeout: int = 600,
    ) -> dict[str, Any] | None:
        """Invoke *command* by name through the integration CLI.

        The integration's ``dispatch_command`` builds the native
        slash-command invocation (e.g. ``/kiss.specify`` for
        markdown agents, ``/kiss-specify`` for skills agents),
        then executes the CLI non-interactively.

        Returns the dispatch result dict, or ``None`` if dispatch is
        not possible (integration not found, CLI not installed, or
        dispatch not supported).
        """
        if not integration_key:
            return None

        try:
            from kiss_cli.integrations import get_integration
        except ImportError:
            return None

        impl = get_integration(integration_key)
        if impl is None:
            return None

        # Check if the integration supports CLI dispatch
        if impl.build_exec_args("test") is None:
            return None

        # Check if the CLI tool is actually installed
        if not shutil.which(impl.key):
            return None

        project_root = Path(context.project_root) if context.project_root else None

        try:
            return impl.dispatch_command(
                command,
                args=args,
                project_root=project_root,
                model=model,
                timeout=timeout,
            )
        except (NotImplementedError, OSError):
            return None

    def validate(self, config: dict[str, Any]) -> list[str]:
        errors = super().validate(config)
        if "command" not in config:
            errors.append(
                f"Command step {config.get('id', '?')!r} is missing 'command' field."
            )
        if "timeout" in config:
            t = config["timeout"]
            if not isinstance(t, int) or t <= 0:
                errors.append(
                    f"Command step {config.get('id', '?')!r}: timeout must be a positive integer, got {t!r}."
                )
        return errors
