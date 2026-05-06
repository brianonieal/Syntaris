#!/bin/bash
# session-start.sh
# Syntaris: Inject Syntaris mode context at session start
# Runs as SessionStart hook
# Per Anthropic docs: stdout from SessionStart becomes additionalContext for Claude

INPUT=$(cat)

if [ -z "$INPUT" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Build context injection
CONTEXT=""

# Check if this is a Syntaris project (has CONTRACT.md)
if [ -f "$PROJECT_DIR/CONTRACT.md" ]; then
  PROJECT_NAME=$(grep "^PROJECT_NAME:" "$PROJECT_DIR/CONTRACT.md" 2>/dev/null | head -1 | sed 's/PROJECT_NAME:[[:space:]]*//')
  CURRENT_VERSION=$(grep "^PROJECT_VERSION:" "$PROJECT_DIR/CONTRACT.md" 2>/dev/null | head -1 | sed 's/PROJECT_VERSION:[[:space:]]*//')
  CLIENT_TYPE=$(grep "^CLIENT_TYPE:" "$PROJECT_DIR/CONTRACT.md" 2>/dev/null | head -1 | sed 's/CLIENT_TYPE:[[:space:]]*//')

  CONTEXT="You are operating under Syntaris methodology."
  CONTEXT="$CONTEXT Project: ${PROJECT_NAME:-unknown} at ${CURRENT_VERSION:-v0.0.0}."
  CONTEXT="$CONTEXT Client type: ${CLIENT_TYPE:-PERSONAL}."
  CONTEXT="$CONTEXT Hard rules: never write code before FRONTEND APPROVED,"
  CONTEXT="$CONTEXT never advance a gate without the exact approval word,"
  CONTEXT="$CONTEXT never skip the REFLEXION entry at gate close,"
  CONTEXT="$CONTEXT never let test count decrease between gates."
  CONTEXT="$CONTEXT Use /start to begin. Check ERRORS.md before diagnosing any error."

  # Check for unclosed stop events
  if [ -f "$PROJECT_DIR/MEMORY_EPISODIC.md" ]; then
    LAST_STOP=$(grep "STOP EVENT" "$PROJECT_DIR/MEMORY_EPISODIC.md" 2>/dev/null | tail -1)
    if [ -n "$LAST_STOP" ]; then
      CONTEXT="$CONTEXT WARNING: Unclosed STOP EVENT found. Read PLANS.md to resume."
    fi
  fi
fi

# Output as JSON per Anthropic SessionStart hook spec
# Format: {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}
if [ -n "$CONTEXT" ]; then
  ESCAPED=$(printf '%s' "$CONTEXT" | sed 's/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$ESCAPED"
fi

exit 0
