#!/bin/bash
# context-check.sh
# Syntaris v0.5.0: Warn when context approaches dangerous fill level
# Runs as PostToolUse hook. Uses a turn-count proxy stored per session.
#
# The previous version used session-file size, which grows monotonically and
# does not reset on /clear. This version tracks turn count in a state file
# keyed by session_id. SessionStart hook (if installed) resets the counter
# on "clear" or "compact" matchers.

INPUT=$(cat)
if [ -z "$INPUT" ]; then
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "default"' 2>/dev/null)
else
  SESSION_ID=$(printf '%s' "$INPUT" | grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"\([^"]*\)"$/\1/')
  [ -z "$SESSION_ID" ] && SESSION_ID="default"
fi

STATE_DIR="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/state"
mkdir -p "$STATE_DIR" 2>/dev/null
COUNTER_FILE="$STATE_DIR/turns-$SESSION_ID.count"

# Increment counter
CURRENT=0
if [ -f "$COUNTER_FILE" ]; then
  CURRENT=$(cat "$COUNTER_FILE" 2>/dev/null || echo 0)
fi
CURRENT=$((CURRENT + 1))
echo "$CURRENT" > "$COUNTER_FILE"

# Thresholds (turns, rough proxy for context percentage)
# Calibration: Claude Code at ~80 tool calls uses ~40% of a 200k window in
# typical agentic workflows. Precedence for resolving the threshold:
#   1. Environment variable (CONTEXT_WARN_TURNS / CONTEXT_HARD_TURNS)
#   2. Values parsed from $CLAUDE_PROJECT_DIR/CONTEXT_BUDGET.md
#      (look for "WARN_TURNS: <n>" and "HARD_TURNS: <n>" lines)
#   3. Hardcoded defaults (80 / 120)

BUDGET_FILE="${CLAUDE_PROJECT_DIR:-.}/CONTEXT_BUDGET.md"
FILE_WARN=""
FILE_HARD=""
if [ -f "$BUDGET_FILE" ]; then
  FILE_WARN=$(grep -E '^WARN_TURNS:[[:space:]]*[0-9]+' "$BUDGET_FILE" 2>/dev/null \
              | head -1 | sed 's/^WARN_TURNS:[[:space:]]*\([0-9]*\).*/\1/')
  FILE_HARD=$(grep -E '^HARD_TURNS:[[:space:]]*[0-9]+' "$BUDGET_FILE" 2>/dev/null \
              | head -1 | sed 's/^HARD_TURNS:[[:space:]]*\([0-9]*\).*/\1/')
fi

WARN_TURNS="${CONTEXT_WARN_TURNS:-${FILE_WARN:-80}}"
HARD_TURNS="${CONTEXT_HARD_TURNS:-${FILE_HARD:-120}}"

# Sanity: make sure they're numeric and positive; fall back if not.
case "$WARN_TURNS" in ''|*[!0-9]*) WARN_TURNS=80 ;; esac
case "$HARD_TURNS" in ''|*[!0-9]*) HARD_TURNS=120 ;; esac
[ "$WARN_TURNS" -lt 1 ] && WARN_TURNS=80
[ "$HARD_TURNS" -lt 1 ] && HARD_TURNS=120

if [ "$CURRENT" -ge "$HARD_TURNS" ]; then
  echo "" >&2
  echo "Heads up: about ${CURRENT} turns this session (approaching context limit)" >&2
  echo "Worth saving state and resetting context now." >&2
  echo "  1. Dump current progress to PLANS.md" >&2
  echo "  2. Run /clear (not /compact -- /clear is lossless)" >&2
  echo "  3. Start fresh session with /start option 2" >&2
  echo "" >&2
elif [ "$CURRENT" -ge "$WARN_TURNS" ]; then
  # Only warn once per 10-turn interval to avoid spam. Anchor the modulo to
  # WARN_TURNS, not to zero, so the first warning fires exactly at WARN_TURNS
  # regardless of whether WARN_TURNS is a multiple of 10.
  REMAINDER=$(( (CURRENT - WARN_TURNS) % 10 ))
  if [ "$REMAINDER" -eq 0 ]; then
    echo "" >&2
    echo "Note: about ${CURRENT} turns this session" >&2
    echo "Good time to save state to PLANS.md. Run Claude Code's /context for exact usage." >&2
    echo "" >&2
  fi
fi

exit 0
