# CODING_RULES.md - Python CLI

## LANGUAGE RULES

- Python 3.11+ exclusively (use the walrus operator, structural pattern matching, type hints freely)
- Type hints on every public function and method
- ruff clean (E, F, I, N, W rule sets minimum) before commit
- mypy strict mode where practical

## CLI RULES

- Use Click for argument parsing. No bare argparse for new code.
- Every command has a `--help` description and at least one example in the docstring.
- Long-running operations show progress (Rich's `Progress` or `Console`).
- Errors are printed to stderr, not stdout. Use `click.echo(err=True)` or `sys.stderr`.
- Exit codes: 0 for success, 1 for user error, 2 for internal error, follow Unix conventions.

## TESTING RULES

- Every command has at least one test using `click.testing.CliRunner`.
- Tests cover the happy path, one error path, and one edge case.
- Coverage target: 70% (CLIs typically have integration tests rather than unit tests).

## PACKAGING RULES

- `pyproject.toml` over `setup.py`. Use `uv` or `hatch` for builds.
- The CLI entry point lives in `pyproject.toml` `[project.scripts]`.
- Version bumps follow semver. Bump version in `pyproject.toml` AND in `__init__.py` together.
