#!/bin/bash
# enforce-tests.sh
# Syntaris v0.5.2: Block new implementation writes when tests are failing
# Runs as PreToolUse hook with matcher "Write|Edit|MultiEdit"
# Per Anthropic hook spec: input arrives as JSON on stdin, exit 2 blocks with
# stderr feedback to Claude.

INPUT=$(cat)

if [ -z "$INPUT" ]; then
  exit 0
fi

# Parse input
if command -v jq >/dev/null 2>&1; then
  TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
  FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty' 2>/dev/null)
else
  TOOL_NAME=$(printf '%s' "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  FILE_PATH=$(printf '%s' "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
fi

# Only enforce on file-writing tools
case "$TOOL_NAME" in
  Write|Edit|MultiEdit) ;;
  *) exit 0 ;;
esac

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Skip enforcement on test files themselves (Claude is allowed to write tests)
case "$FILE_PATH" in
  *test* | *spec* | *__tests__* | *test_*.py | *_test.py | *.test.ts | *.test.tsx | *.spec.ts | *.spec.tsx) exit 0 ;;
esac

# Skip enforcement on non-source files
case "$FILE_PATH" in
  *.md | *.json | *.yaml | *.yml | *.toml | *.txt | *.lock | *.env | *.env.* | *.gitignore) exit 0 ;;
esac

# Detect test suite presence
HAS_PYTEST=""
HAS_VITEST=""
if [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] || [ -f "apps/api/pyproject.toml" ]; then
  HAS_PYTEST="1"
fi
if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] || [ -f "apps/web/vitest.config.ts" ]; then
  HAS_VITEST="1"
fi

# Pre-test-suite phase: nothing to enforce
if [ -z "$HAS_PYTEST" ] && [ -z "$HAS_VITEST" ]; then
  exit 0
fi

# Check for a marker file to avoid running full test suite on every single edit.
# The marker is updated whenever tests pass; if it's fresh (under 60s old),
# trust it and skip re-running.
MARKER_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
MARKER_FILE="$MARKER_DIR/tests-passing-marker"
mkdir -p "$MARKER_DIR" 2>/dev/null

if [ -f "$MARKER_FILE" ]; then
  # If marker is less than 60 seconds old, trust it
  MARKER_AGE=$(($(date +%s) - $(stat -c%Y "$MARKER_FILE" 2>/dev/null || stat -f%m "$MARKER_FILE" 2>/dev/null || echo 0)))
  if [ "$MARKER_AGE" -lt 60 ] 2>/dev/null; then
    exit 0
  fi
fi

# Run test suites and update marker
BACKEND_STATUS="unknown"
FRONTEND_STATUS="unknown"

if [ -n "$HAS_PYTEST" ]; then
  if (cd apps/api 2>/dev/null && python -m pytest --tb=no -q --timeout=30 > /tmp/bp-v11-pytest.log 2>&1); then
    BACKEND_STATUS="pass"
  else
    BACKEND_STATUS="fail"
  fi
fi

if [ -n "$HAS_VITEST" ]; then
  if (cd apps/web 2>/dev/null && pnpm test --run > /tmp/bp-v11-vitest.log 2>&1); then
    FRONTEND_STATUS="pass"
  else
    FRONTEND_STATUS="fail"
  fi
fi

if [ "$BACKEND_STATUS" = "fail" ] || [ "$FRONTEND_STATUS" = "fail" ]; then
  echo "Heads up: tests are currently failing. Fix them before writing new implementation files - that's the test-before-code rule." >&2
  echo "Backend: $BACKEND_STATUS | Frontend: $FRONTEND_STATUS" >&2
  echo "Logs: /tmp/bp-v11-pytest.log, /tmp/bp-v11-vitest.log" >&2
  echo "You may write or edit test files. Non-test source writes are blocked until tests pass." >&2
  exit 2
fi

# Tests pass: touch the marker so subsequent edits skip the expensive check
touch "$MARKER_FILE" 2>/dev/null
exit 0
