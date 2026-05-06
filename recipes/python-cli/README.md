# Recipe: python-cli

For building Python command-line tools. Single file or package, no web UI.

## Stack

- Python 3.11+
- Click for CLI argument parsing
- pytest for testing
- Optional: SQLite for state, Rich for formatted output

## When to use

- A standalone script you'll run from terminal
- A tool that operates on local files or remote APIs
- Something a single developer can install via `pip install` or `pipx`

## When NOT to use

- Web apps (use `web-app-starter`)
- Long-running services (use `api-starter`)
- Tools that need a database server (use a more comprehensive recipe)

## Time to v1.0.0

For a tightly-scoped CLI (5-10 commands), expect 4-6 hours of focused work across 2-3 gates: CONFIRMED → ROADMAP APPROVED → GO.
