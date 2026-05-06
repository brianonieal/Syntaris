# EXAMPLES.md - Python CLI patterns

## PATTERN 1: Click command with options and subcommands

```python
import click

@click.group()
@click.version_option()
def cli():
    """My tool description."""
    pass

@cli.command()
@click.argument("name")
@click.option("--count", "-c", default=1, help="Number of times to greet")
def greet(name: str, count: int) -> None:
    """Greet NAME (count times)."""
    for _ in range(count):
        click.echo(f"Hello, {name}!")

if __name__ == "__main__":
    cli()
```

## PATTERN 2: Progress with Rich

```python
from rich.progress import Progress

def process_files(paths: list[str]) -> None:
    with Progress() as progress:
        task = progress.add_task("Processing", total=len(paths))
        for path in paths:
            do_work(path)
            progress.advance(task)
```

## PATTERN 3: Test with CliRunner

```python
from click.testing import CliRunner
from my_tool.cli import cli

def test_greet_default():
    runner = CliRunner()
    result = runner.invoke(cli, ["greet", "World"])
    assert result.exit_code == 0
    assert "Hello, World!" in result.output

def test_greet_with_count():
    runner = CliRunner()
    result = runner.invoke(cli, ["greet", "World", "--count", "3"])
    assert result.exit_code == 0
    assert result.output.count("Hello, World!") == 3
```

## ANTI-PATTERN: Bare argparse

```python
# Don't do this in new code
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("name")
args = parser.parse_args()
print(f"Hello, {args.name}")
```

Use Click instead. Click handles subcommands, type coercion, help text, and testing more cleanly.
