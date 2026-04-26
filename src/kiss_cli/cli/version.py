"""Version command implementation."""

import platform
from rich.table import Table
from rich.panel import Panel

from kiss_cli.ui import console, show_banner
from kiss_cli.version import get_kiss_version
from . import app


@app.command()
def version():
    """Display version and system information."""
    show_banner()

    cli_version = get_kiss_version()

    info_table = Table(show_header=False, box=None, padding=(0, 2))
    info_table.add_column("Key", style="cyan", justify="right")
    info_table.add_column("Value", style="white")

    info_table.add_row("CLI Version", cli_version)
    info_table.add_row("", "")
    info_table.add_row("Python", platform.python_version())
    info_table.add_row("Platform", platform.system())
    info_table.add_row("Architecture", platform.machine())
    info_table.add_row("OS Version", platform.version())

    panel = Panel(
        info_table,
        title="[bold cyan]kiss Information[/bold cyan]",
        border_style="cyan",
        padding=(1, 2)
    )

    console.print(panel)
    console.print()
