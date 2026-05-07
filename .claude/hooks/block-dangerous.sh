#!/bin/bash
# block-dangerous.sh
# Syntaris v0.5.3: Block dangerous bash commands before execution
# Runs as PreToolUse hook with matcher "Bash"
# Per Anthropic hook spec: input arrives as JSON on stdin, exit 2 blocks with
# stderr feedback to Claude.

# Read JSON input from stdin
INPUT=$(cat)

if [ -z "$INPUT" ]; then
  exit 0
fi

# Parse with jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
  TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
else
  TOOL_NAME=$(printf '%s' "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  COMMAND=$(printf '%s' "$INPUT" | grep -o '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi

if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

if [ -z "$COMMAND" ]; then
  exit 0
fi

# Block destructive database operations
if printf '%s' "$COMMAND" | grep -qiE "DROP TABLE|DROP DATABASE|DELETE FROM .* WHERE 1=1|TRUNCATE TABLE"; then
  echo "Blocked: destructive database command. If intentional, run it manually outside Claude Code." >&2
  echo "Command: $COMMAND" >&2
  echo "If intentional, run manually outside Claude Code." >&2
  exit 2
fi

# Block recursive force delete of root, current dir, home, or glob
if printf '%s' "$COMMAND" | grep -qE "rm[[:space:]]+(-[a-zA-Z]*r[a-zA-Z]*f|-[a-zA-Z]*f[a-zA-Z]*r)[[:space:]]+(/|\./|\*|~)"; then
  echo "Blocked: rm -rf is a system-destructive command. If intentional, run it manually outside Claude Code." >&2
  echo "Command: $COMMAND" >&2
  echo "If intentional, run manually outside Claude Code." >&2
  exit 2
fi

# Block force push to main/master
if printf '%s' "$COMMAND" | grep -qE "git[[:space:]]+push[[:space:]]+(-[a-zA-Z]*f|--force)[[:space:]]+.*\b(main|master)\b"; then
  echo "Blocked: force push to protected branch. If intentional, run it manually outside Claude Code." >&2
  echo "Command: $COMMAND" >&2
  exit 2
fi

# Block direct psql/pg_dump against production
if printf '%s' "$COMMAND" | grep -qiE "(psql|pg_dump)[[:space:]]+.*production"; then
  echo "Blocked: direct production database access. Use migrations or the app backend instead." >&2
  echo "Use a database MCP server for database operations." >&2
  exit 2
fi

exit 0
