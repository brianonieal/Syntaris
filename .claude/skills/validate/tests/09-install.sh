#!/bin/bash
# 09-install.sh - install round-trip into a fake $HOME, verify CRLF stripped,
# hooks functional post-install, uninstall removes everything.
#
# Skipped if SKIP_INSTALL is set or install.sh is missing.

INSTALLER="$SYNTARIS_ROOT/install.sh"
UNINSTALLER="$SYNTARIS_ROOT/uninstall.sh"

if [[ ! -f "$INSTALLER" ]]; then
  echo "  [SKIP] install.sh not found at $INSTALLER"
  return
fi

FAKE_HOME=$(mktemp -d)

# 09.1 - install.sh runs cleanly
HOME="$FAKE_HOME" bash "$INSTALLER" --yes >/dev/null 2>&1
assert_exit_code "09.1 install.sh exits 0" "0" "$?"

# 09.2 - Expected install layout
assert_dir_exists  "09.2a skills dir installed"   "$FAKE_HOME/.claude/skills"
assert_dir_exists  "09.2b hooks dir installed"    "$FAKE_HOME/.claude/hooks"
assert_dir_exists  "09.2c agents dir installed"   "$FAKE_HOME/.claude/agents"
assert_file_exists "09.2d settings.json present"  "$FAKE_HOME/.claude/settings.json"

# 09.3 - settings.json is valid JSON
TOTAL=$((TOTAL+1))
SETTINGS_PATH="$FAKE_HOME/.claude/settings.json"
if command -v cygpath >/dev/null 2>&1; then
  SETTINGS_WIN=$(cygpath -w "$SETTINGS_PATH")
else
  SETTINGS_WIN="$SETTINGS_PATH"
fi
if python3 -c "import json; json.load(open(r'$SETTINGS_WIN'))" 2>/dev/null; then
  echo "  [PASS] 09.3 settings.json is valid JSON"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 09.3 settings.json invalid JSON"
  FAIL=$((FAIL+1))
  FAILURES+=("09.3 settings.json")
fi

# 09.4 - .sh hooks have NO CRLF after install
CRLF_HOOKS=0
for f in "$FAKE_HOME/.claude/hooks/"*.sh; do
  [[ -f "$f" ]] || continue
  if file "$f" 2>/dev/null | grep -q "CRLF"; then
    CRLF_HOOKS=$((CRLF_HOOKS+1))
  fi
done
assert_eq "09.4 No CRLF in installed .sh hooks" "0" "$CRLF_HOOKS"

# 09.5 - All .sh hooks pass bash -n after install
SYNTAX_FAIL=0
for f in "$FAKE_HOME/.claude/hooks/"*.sh; do
  [[ -f "$f" ]] || continue
  bash -n "$f" 2>/dev/null || SYNTAX_FAIL=$((SYNTAX_FAIL+1))
done
assert_eq "09.5 Installed .sh hooks pass bash -n" "0" "$SYNTAX_FAIL"

# 09.6 - Functional: installed session-start hook works
PROJ=$(setup_test_project)
printf "### ERR-001: A\n### ERR-002: B\n### ERR-003: C\n" > "$PROJ/ERRORS.md"
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$FAKE_HOME/.claude/hooks/session-start.sh" >/dev/null 2>&1
assert_eq "09.6 Installed session-start counts errors" "3" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$PROJ"

# 09.7 - uninstall.sh removes the install
if [[ -f "$UNINSTALLER" ]]; then
  HOME="$FAKE_HOME" bash "$UNINSTALLER" --yes >/dev/null 2>&1
  assert_exit_code "09.7a uninstall.sh exits 0" "0" "$?"
  TOTAL=$((TOTAL+1))
  if [[ ! -d "$FAKE_HOME/.claude/skills" && ! -d "$FAKE_HOME/.claude/hooks" && ! -d "$FAKE_HOME/.claude/agents" ]]; then
    echo "  [PASS] 09.7b uninstall removes skills/hooks/agents"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] 09.7b uninstall left artifacts behind"
    FAIL=$((FAIL+1))
    FAILURES+=("09.7b uninstall residue")
  fi
else
  echo "  [SKIP] uninstall.sh not found"
fi

rm -rf "$FAKE_HOME"
