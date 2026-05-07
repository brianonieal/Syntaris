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

# v0.6.0: foundation files live in foundation/ by Syntaris convention.
# Older projects keep them at root. Try foundation/ first, fall back.
resolve_foundation_file() {
  local fname="$1"
  if [ -f "$PROJECT_DIR/foundation/$fname" ]; then
    echo "$PROJECT_DIR/foundation/$fname"
  elif [ -f "$PROJECT_DIR/$fname" ]; then
    echo "$PROJECT_DIR/$fname"
  else
    echo ""
  fi
}

CONTRACT_FILE=$(resolve_foundation_file "CONTRACT.md")
EPISODIC_FILE=$(resolve_foundation_file "MEMORY_EPISODIC.md")
ERRORS_FILE=$(resolve_foundation_file "ERRORS.md")

# Build context injection
CONTEXT=""

# Check if this is a Syntaris project (has CONTRACT.md)
if [ -n "$CONTRACT_FILE" ] && [ -f "$CONTRACT_FILE" ]; then
  PROJECT_NAME=$(grep "^PROJECT_NAME:" "$CONTRACT_FILE" 2>/dev/null | head -1 | sed 's/PROJECT_NAME:[[:space:]]*//')
  CURRENT_VERSION=$(grep "^PROJECT_VERSION:" "$CONTRACT_FILE" 2>/dev/null | head -1 | sed 's/PROJECT_VERSION:[[:space:]]*//')
  CLIENT_TYPE=$(grep "^CLIENT_TYPE:" "$CONTRACT_FILE" 2>/dev/null | head -1 | sed 's/CLIENT_TYPE:[[:space:]]*//')

  CONTEXT="You are operating under Syntaris methodology."
  CONTEXT="$CONTEXT Project: ${PROJECT_NAME:-unknown} at ${CURRENT_VERSION:-v0.0.0}."
  CONTEXT="$CONTEXT Client type: ${CLIENT_TYPE:-PERSONAL}."
  CONTEXT="$CONTEXT Hard rules: never write code before FRONTEND APPROVED,"
  CONTEXT="$CONTEXT never advance a gate without the exact approval word,"
  CONTEXT="$CONTEXT never skip the REFLEXION entry at gate close,"
  CONTEXT="$CONTEXT never let test count decrease between gates."
  CONTEXT="$CONTEXT Use /start to begin. Check ERRORS.md before diagnosing any error."

  # Check for unclosed stop events
  if [ -n "$EPISODIC_FILE" ] && [ -f "$EPISODIC_FILE" ]; then
    LAST_STOP=$(grep "STOP EVENT" "$EPISODIC_FILE" 2>/dev/null | tail -1)
    if [ -n "$LAST_STOP" ]; then
      CONTEXT="$CONTEXT WARNING: Unclosed STOP EVENT found. Read PLANS.md to resume."
    fi
  fi

  # Snapshot error count for diagnostic delta at gate close.
  # Counts ERR- entries in ERRORS.md and writes to .syntaris/errors-at-gate-open.count.
  # The gate-close-calibration hook reads this to compute the delta.
  if [ -n "$ERRORS_FILE" ] && [ -f "$ERRORS_FILE" ]; then
    # grep -c outputs the count but exits 1 when zero matches.
    # Capture separately to avoid || echo doubling the output.
    ERR_COUNT=$(grep -cE "^(###?\s+)?ERR-" "$ERRORS_FILE" 2>/dev/null) || true
    ERR_COUNT="${ERR_COUNT:-0}"
  else
    ERR_COUNT=0
  fi
  SYNTARIS_STATE="$PROJECT_DIR/.syntaris"
  mkdir -p "$SYNTARIS_STATE" 2>/dev/null
  printf '%s' "$ERR_COUNT" > "$SYNTARIS_STATE/errors-at-gate-open.count" 2>/dev/null
fi

# Output as JSON per Anthropic SessionStart hook spec
# Format: {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}
if [ -n "$CONTEXT" ]; then
  ESCAPED=$(printf '%s' "$CONTEXT" | sed 's/"/\\"/g')
  printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}' "$ESCAPED"
fi

exit 0
