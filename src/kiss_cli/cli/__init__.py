"""CLI subpackage for kiss commands.

This module creates and configures the main Typer app,
delegating to submodules and command groups from the parent package.
"""

import sys
import typer
from kiss_cli.ui import BannerGroup, show_banner, Align

# Create the main Typer app
app = typer.Typer(
    name="kiss",
    help="Setup tool for kiss spec-driven development projects",
    add_completion=False,
    invoke_without_command=True,
    cls=BannerGroup,
)


@app.callback()
def callback(
    ctx: typer.Context,
    show_version: bool = typer.Option(False, "--version", "-V", callback=lambda v: __import__('kiss_cli.ui', fromlist=['_version_callback'])._version_callback(v), is_eager=True, help="Show version and exit."),
):
    """Show banner when no subcommand is provided."""
    if ctx.invoked_subcommand is None and "--help" not in sys.argv and "-h" not in sys.argv:
        show_banner()
        from rich.console import Console
        console = Console(highlight=False)
        console.print(Align.center("[dim]Run 'kiss --help' for usage information[/dim]"))
        console.print()


# Import command submodules. These must be imported AFTER `app`
# is defined so decorators fire at import time.
#
# Order notes:
# - `version`, `check` — utility commands on the main app
# - `init`, `integration`, `preset`, `extension`, `workflow` — Phase-6 extracted
#   command groups. They import package-level constants from kiss_cli
#   (AGENT_CONFIG), so they must be imported AFTER
#   kiss_cli/__init__.py has evaluated those constants. The main package
#   `__init__.py` imports this cli package *after* defining them, so by the
#   time Python re-enters this module to run the lines below,
#   `from kiss_cli import AGENT_CONFIG` will resolve.
from . import version     # noqa: F401, E402
from . import check       # noqa: F401, E402
from . import init        # noqa: F401, E402
from . import integration # noqa: F401, E402
from . import preset      # noqa: F401, E402
from . import extension   # noqa: F401, E402
from . import workflow    # noqa: F401, E402
