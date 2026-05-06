#!/bin/bash
# writethru-episodic.sh
# Syntaris: Write-through to MEMORY_EPISODIC.md on session stop
# Runs as Stop hook. Fires when session ends or crashes.
# Preserves last-known state across sessions.

INPUT=$(cat)

# Prevent infinite loop: if this is a subsequent Stop invocation
# (stop_hook_active = true), allow stopping without re-running logic
if command -v jq >/dev/null 2>&1 && [ -n "$INPUT" ]; then
  STOP_ACTIVE=$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
  if [ "$STOP_ACTIVE" = "true" ]; then
    exit 0
  fi
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MEMORY_FILE="$PROJECT_DIR/MEMORY_EPISODIC.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ ! -f "$MEMORY_FILE" ]; then
  exit 0
fi

# Append stop event to episodic log
ACTIVE_GATE=$(grep "Active gate:\|Current gate:" "$PROJECT_DIR/SPEC.md" 2>/dev/null | head -1 || echo "Unknown")
LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "Unknown")

cat >> "$MEMORY_FILE" << EOF

## STOP EVENT: $TIMESTAMP
Session ended (crash or manual stop).
Gate in progress: $ACTIVE_GATE
Last git commit: $LAST_COMMIT
Resume: /start option 2
EOF

exit 0
