#!/bin/bash
# strip-coauthor.sh
# Strips Co-Authored-By: Claude trailers from all git commits
# Runs as PreToolUse hook on every action
# Blueprint v11

HOOK_DIR="$(git rev-parse --git-dir 2>/dev/null)/hooks"
if [ -z "$HOOK_DIR" ] || [ ! -d "$(git rev-parse --git-dir 2>/dev/null)" ]; then
  exit 0
fi

COMMIT_MSG_HOOK="$HOOK_DIR/commit-msg"

# Install commit-msg hook if not already installed
if [ ! -f "$COMMIT_MSG_HOOK" ] || ! grep -q "Co-Authored-By" "$COMMIT_MSG_HOOK" 2>/dev/null; then
  cat > "$COMMIT_MSG_HOOK" << 'HOOK'
#!/bin/bash
# Blueprint v11: Strip Co-Authored-By trailers from commits
# Prevents Vercel deployment blocks on Hobby plan
COMMIT_FILE="$1"
if [ -f "$COMMIT_FILE" ]; then
  # Remove any Co-Authored-By lines (Anthropic or otherwise)
  grep -v "^Co-Authored-By:" "$COMMIT_FILE" | \
  grep -v "^co-authored-by:" | \
  grep -v "noreply@anthropic.com" > "$COMMIT_FILE.tmp"
  mv "$COMMIT_FILE.tmp" "$COMMIT_FILE"
fi
exit 0
HOOK
  chmod +x "$COMMIT_MSG_HOOK"
fi

exit 0
