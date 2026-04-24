#!/bin/bash
# hook-wrapper.sh
# Blueprint v11: Unified hook invocation with cross-platform fallback and diagnostics.
#
# Usage:
#   bash hook-wrapper.sh <hook-name>
#
# Arguments:
#   <hook-name>  Hook script basename without extension (e.g. "enforce-tests")
#
# Behavior:
#   1. Tries $CLAUDE_PROJECT_DIR/.claude/hooks/<hook-name>.sh
#   2. Falls back to $HOME/.claude/hooks/<hook-name>.sh
#   3. Falls back to PowerShell .ps1 on Windows (if powershell.exe is available)
#   4. If none succeed, dumps the captured stderr to real stderr so Claude sees it.
#   5. Preserves exit 2 (blocking) from the first successful hook execution -
#      does NOT try fallbacks if the hook intentionally blocked.
#
# Diagnostic mode:
#   Set BLUEPRINT_DEBUG=1 to always surface stderr, even on successful runs.
#
# Error log path:
#   Per-session when $CLAUDE_SESSION_ID is set, otherwise a generic path.
#   Uses $TMPDIR (Unix) or $TEMP (Windows via Git Bash) for writability.

HOOK_NAME="$1"

if [ -z "$HOOK_NAME" ]; then
  echo "hook-wrapper.sh: missing hook name" >&2
  exit 0
fi

# Pick a writable temp dir. TMPDIR is POSIX, TEMP is what Git Bash maps on Windows.
TMP="${TMPDIR:-${TEMP:-/tmp}}"
SESSION_KEY="${CLAUDE_SESSION_ID:-default}"
ERR_LOG="$TMP/bp-hook-err-$SESSION_KEY.log"

# Ensure the log dir exists and the file is truncated for this invocation
mkdir -p "$TMP" 2>/dev/null
: > "$ERR_LOG" 2>/dev/null

# Read stdin once, feed it to whichever fallback path runs
STDIN_PAYLOAD=$(cat)

run_hook() {
  local script="$1"
  local runner="$2"  # "bash" or "powershell"

  if [ "$runner" = "bash" ]; then
    [ -f "$script" ] || return 127
    printf '%s' "$STDIN_PAYLOAD" | bash "$script" 2>"$ERR_LOG"
  else
    # PowerShell path - only reachable if powershell.exe exists in PATH
    printf '%s' "$STDIN_PAYLOAD" | powershell.exe -File "$script" 2>"$ERR_LOG"
  fi
  return $?
}

RESULT=127  # 127 = command-not-found sentinel

# Try 1: project-local hook
PROJ_HOOK="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/$HOOK_NAME.sh"
if [ -f "$PROJ_HOOK" ]; then
  run_hook "$PROJ_HOOK" bash
  RESULT=$?
fi

# Try 2: user-global hook (only if project hook didn't exist OR failed non-blockingly)
if [ "$RESULT" -ne 0 ] && [ "$RESULT" -ne 2 ]; then
  HOME_HOOK="$HOME/.claude/hooks/$HOOK_NAME.sh"
  if [ -f "$HOME_HOOK" ]; then
    run_hook "$HOME_HOOK" bash
    RESULT=$?
  fi
fi

# Try 3: PowerShell fallback on Windows
if [ "$RESULT" -ne 0 ] && [ "$RESULT" -ne 2 ] && command -v powershell.exe >/dev/null 2>&1; then
  # Build the Windows-style path for PowerShell
  if [ -n "$USERPROFILE" ]; then
    PS_HOOK="$USERPROFILE\\.claude\\hooks\\$HOOK_NAME.ps1"
    run_hook "$PS_HOOK" powershell
    RESULT=$?
  fi
fi

# Surface errors: always on exit 2 (blocking), always in debug mode,
# and when all fallbacks failed non-blockingly.
if [ "$RESULT" -eq 2 ]; then
  # Blocking exit: pipe captured stderr to real stderr so Claude sees the reason.
  [ -s "$ERR_LOG" ] && cat "$ERR_LOG" >&2
  exit 2
fi

if [ "${BLUEPRINT_DEBUG:-0}" = "1" ] || [ "$RESULT" = 127 ]; then
  # 127 = no hook was found on any path; tell the user.
  if [ "$RESULT" = 127 ]; then
    echo "BLUEPRINT v11: hook '$HOOK_NAME' not found on any fallback path" >&2
    echo "  Tried: \$CLAUDE_PROJECT_DIR/.claude/hooks/$HOOK_NAME.sh" >&2
    echo "         \$HOME/.claude/hooks/$HOOK_NAME.sh" >&2
    [ -n "$USERPROFILE" ] && echo "         \$USERPROFILE\\.claude\\hooks\\$HOOK_NAME.ps1" >&2
  fi
  [ -s "$ERR_LOG" ] && cat "$ERR_LOG" >&2
fi

# Missing hook is not a blocking failure - exit 0 so Claude's tool call proceeds.
exit 0
