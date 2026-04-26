"""UI components for kiss CLI."""

import readchar
import typer
from rich.console import Console
from rich.live import Live
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from rich.align import Align
from typer.core import TyperGroup

# Constants
BANNER = """
██╗  ██╗██╗███████╗███████╗      ██╗   ██╗
██║ ██╔╝██║██╔════╝██╔════╝      ██║   ██║
█████╔╝ ██║███████╗███████╗█████╗██║   ██║
██╔═██╗ ██║╚════██║╚════██║╚════╝██║   ██║
██║  ██╗██║███████║███████║      ╚██████╔╝
╚═╝  ╚═╝╚═╝╚══════╝╚══════╝       ╚═════╝
"""

TAGLINE = "KISS-U: Drive Quality Together with Reusable AI Components"

console = Console(highlight=False)


class BannerGroup(TyperGroup):
    """Custom group that shows banner before help."""

    def format_help(self, ctx, formatter):
        # Show banner before help
        show_banner()
        super().format_help(ctx, formatter)


def get_key():
    """Get a single keypress in a cross-platform way using readchar."""
    key = readchar.readkey()

    if key == readchar.key.UP or key == readchar.key.CTRL_P:
        return 'up'
    if key == readchar.key.DOWN or key == readchar.key.CTRL_N:
        return 'down'

    if key == readchar.key.ENTER:
        return 'enter'

    if key == readchar.key.ESC:
        return 'escape'

    if key == readchar.key.CTRL_C:
        raise KeyboardInterrupt

    return key


def select_with_arrows(options: dict, prompt_text: str = "Select an option", default_key: str = None) -> str:
    """
    Interactive selection using arrow keys with Rich Live display.

    Args:
        options: Dict with keys as option keys and values as descriptions
        prompt_text: Text to show above the options
        default_key: Default option key to start with

    Returns:
        Selected option key
    """
    option_keys = list(options.keys())
    if default_key and default_key in option_keys:
        selected_index = option_keys.index(default_key)
    else:
        selected_index = 0

    selected_key = None

    def create_selection_panel():
        """Create the selection panel with current selection highlighted."""
        table = Table.grid(padding=(0, 2))
        table.add_column(style="cyan", justify="left", width=3)
        table.add_column(style="white", justify="left")

        for i, key in enumerate(option_keys):
            if i == selected_index:
                table.add_row("▶", f"[cyan]{key}[/cyan] [dim]({options[key]})[/dim]")
            else:
                table.add_row(" ", f"[cyan]{key}[/cyan] [dim]({options[key]})[/dim]")

        table.add_row("", "")
        table.add_row("", "[dim]Use ↑/↓ to navigate, Enter to select, Esc to cancel[/dim]")

        return Panel(
            table,
            title=f"[bold]{prompt_text}[/bold]",
            border_style="cyan",
            padding=(1, 2)
        )

    console.print()

    def run_selection_loop():
        nonlocal selected_key, selected_index
        with Live(create_selection_panel(), console=console, transient=True, auto_refresh=False) as live:
            while True:
                try:
                    key = get_key()
                    if key == 'up':
                        selected_index = (selected_index - 1) % len(option_keys)
                    elif key == 'down':
                        selected_index = (selected_index + 1) % len(option_keys)
                    elif key == 'enter':
                        selected_key = option_keys[selected_index]
                        break
                    elif key == 'escape':
                        console.print("\n[yellow]Selection cancelled[/yellow]")
                        raise typer.Exit(1)

                    live.update(create_selection_panel(), refresh=True)

                except KeyboardInterrupt:
                    console.print("\n[yellow]Selection cancelled[/yellow]")
                    raise typer.Exit(1)

    run_selection_loop()

    if selected_key is None:
        console.print("\n[red]Selection failed.[/red]")
        raise typer.Exit(1)

    return selected_key


def multi_select_integrations(options: dict, prompt_text: str = "Select AI providers", defaults: set = None) -> list[str]:
    """
    Interactive multi-selection using arrow keys and space bar with Rich Live display.

    Args:
        options: Dict with keys as option keys and values as descriptions
        prompt_text: Text to show above the options
        defaults: Set of option keys that should be pre-selected

    Returns:
        List of selected option keys
    """
    if defaults is None:
        defaults = set()

    option_keys = list(options.keys())
    selected_indices = set()

    # Pre-select defaults
    for i, key in enumerate(option_keys):
        if key in defaults:
            selected_indices.add(i)

    cursor_index = 0

    def create_selection_panel():
        """Create the selection panel with checkboxes and current cursor position."""
        table = Table.grid(padding=(0, 2))
        table.add_column(style="cyan", justify="left", width=4)
        table.add_column(style="white", justify="left")

        for i, key in enumerate(option_keys):
            is_selected = i in selected_indices
            is_cursor = i == cursor_index

            # Checkbox symbol
            checkbox = "[green]●[/green]" if is_selected else "○"

            # Cursor indicator
            cursor_symbol = "▶ " if is_cursor else "  "

            # Key and description
            key_text = f"[cyan]{key}[/cyan]" if is_cursor else key
            desc_text = f" [dim]({options[key]})[/dim]"

            table.add_row(f"{cursor_symbol}{checkbox}", key_text + desc_text)

        table.add_row("", "")
        table.add_row("", "[dim]↑/↓ navigate | Space toggle | Enter confirm | Esc cancel[/dim]")

        return Panel(
            table,
            title=f"[bold]{prompt_text}[/bold]",
            border_style="cyan",
            padding=(1, 2)
        )

    console.print()

    def run_selection_loop():
        nonlocal cursor_index
        with Live(create_selection_panel(), console=console, transient=True, auto_refresh=False) as live:
            while True:
                try:
                    key = get_key()
                    if key == 'up':
                        cursor_index = (cursor_index - 1) % len(option_keys)
                    elif key == 'down':
                        cursor_index = (cursor_index + 1) % len(option_keys)
                    elif key == ' ':  # Space bar to toggle
                        if cursor_index in selected_indices:
                            selected_indices.discard(cursor_index)
                        else:
                            selected_indices.add(cursor_index)
                    elif key == 'enter':
                        # Must have at least one selection
                        if not selected_indices:
                            # Show error message and continue
                            console.print("[yellow]Please select at least one provider[/yellow]")
                            continue
                        break
                    elif key == 'escape':
                        console.print("\n[yellow]Selection cancelled[/yellow]")
                        raise typer.Exit(1)

                    live.update(create_selection_panel(), refresh=True)

                except KeyboardInterrupt:
                    console.print("\n[yellow]Selection cancelled[/yellow]")
                    raise typer.Exit(1)

    run_selection_loop()

    # Return selected keys in original order
    selected_keys = [option_keys[i] for i in sorted(selected_indices)]
    return selected_keys


def show_banner():
    """Display the ASCII art banner."""
    banner_lines = BANNER.strip().split('\n')
    colors = ["green", "green", "green", "green", "green", "bright_white"]

    styled_banner = Text()
    for i, line in enumerate(banner_lines):
        color = colors[i % len(colors)]
        styled_banner.append(line + "\n", style=color)

    console.print(Align.center(styled_banner))
    console.print(Align.center(Text(TAGLINE, style="italic bright_yellow")))
    console.print()


def _version_callback(value: bool):
    """Callback for the --version flag."""
    if value:
        from kiss_cli.version import get_kiss_version
        console.print(f"kiss {get_kiss_version()}")
        raise typer.Exit()
