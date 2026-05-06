#!/bin/bash
# pre-compact.sh
# Syntaris: Save state before lossy auto-compaction
# Runs as PreCompact hook
# Auto-compaction fires at ~83.5% context and loses 70-80% of detail.
# This hook dumps critical state to PLANS.md and a backup file before that happens.

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Create backup directory
BACKUP_DIR="$PROJECT_DIR/.claude/backups"
mkdir -p "$BACKUP_DIR" 2>/dev/null

# Backup the current session transcript if accessible
SESSION_DIR="$HOME/.claude/sessions"
if [ -d "$SESSION_DIR" ]; then
  LATEST_SESSION=$(ls -t "$SESSION_DIR"/*.jsonl 2>/dev/null | head -1)
  if [ -n "$LATEST_SESSION" ]; then
    BACKUP_NAME="pre-compact-$(date +%Y%m%d-%H%M%S).jsonl"
    cp "$LATEST_SESSION" "$BACKUP_DIR/$BACKUP_NAME" 2>/dev/null
  fi
fi

# Append a compaction warning to PLANS.md
if [ -f "$PROJECT_DIR/PLANS.md" ]; then
  cat >> "$PROJECT_DIR/PLANS.md" << EOF

## AUTO-COMPACT WARNING: $TIMESTAMP
Context auto-compacted. 70-80% of detail was lost.
Session backup saved to: .claude/backups/
Resume with /start option 2 and read this file carefully.
Last git state: $(git log --oneline -1 2>/dev/null || echo "unknown")
Tests: $(cd "$PROJECT_DIR" && python -m pytest --tb=no -q 2>/dev/null | tail -1 || echo "unknown")
EOF
fi

echo "Syntaris: Pre-compaction backup saved to .claude/backups/" >&2
exit 0
