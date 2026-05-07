#!/bin/bash
# 08-wrapper.sh - hook-wrapper.sh dispatch and exit-code propagation

WRAPPER="$SYNTARIS_ROOT/.claude/hooks/hook-wrapper.sh"

if [[ ! -f "$WRAPPER" ]]; then
  assert_file_exists "08.0 hook-wrapper.sh present" "$WRAPPER"
  return
fi

# 08.1 - Wrapper invokes session-start when hook is project-local
PROJ=$(setup_test_project)
mkdir -p "$PROJ/.claude/hooks"
cp "$SYNTARIS_ROOT/.claude/hooks/session-start.sh" "$PROJ/.claude/hooks/session-start.sh"
printf "### ERR-001: A\n### ERR-002: B\n" > "$PROJ/ERRORS.md"
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$WRAPPER" session-start >/dev/null 2>&1
EXIT=$?
assert_exit_code "08.1a Wrapper exits 0 on success" "0" "$EXIT"
R=$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)
assert_eq "08.1b Wrapper actually invoked the hook" "2" "$R"
rm -rf "$PROJ"

# 08.2 - Missing hook exits 0 (graceful, non-blocking)
PROJ=$(setup_test_project)
echo '{"event":"X"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$WRAPPER" nonexistent-hook >/dev/null 2>&1
EXIT=$?
assert_exit_code "08.2 Missing hook exits 0 (non-blocking)" "0" "$EXIT"
rm -rf "$PROJ"

# 08.3 - Wrapper propagates exit 2 (blocking) from block-dangerous
PROJ=$(setup_test_project)
mkdir -p "$PROJ/.claude/hooks"
cp "$SYNTARIS_ROOT/.claude/hooks/block-dangerous.sh" "$PROJ/.claude/hooks/block-dangerous.sh"
PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}'
echo "$PAYLOAD" | CLAUDE_PROJECT_DIR="$PROJ" bash "$WRAPPER" block-dangerous >/dev/null 2>&1
assert_exit_code "08.3 Wrapper propagates exit 2 from blocking hook" "2" "$?"
rm -rf "$PROJ"

# 08.4 - No args exits gracefully
bash "$WRAPPER" >/dev/null 2>&1
assert_exit_code "08.4 Wrapper with no args exits 0 (graceful)" "0" "$?"
