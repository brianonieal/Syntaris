#!/bin/bash
# 02-session-start.sh - session-start.sh error count snapshot tests

HOOK="$SYNTARIS_ROOT/.claude/hooks/session-start.sh"

if [[ ! -f "$HOOK" ]]; then
  assert_file_exists "02.0 session-start.sh present" "$HOOK"
  return
fi

# 02.1 - Count 3 ERR- entries
PROJ=$(setup_test_project)
cat > "$PROJ/ERRORS.md" <<'EOF'
# ERRORS.md
### ERR-001: Database timeout
### ERR-002: Auth redirect loop
### ERR-003: CSS flicker
EOF
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" >/dev/null 2>&1
assert_eq "02.1 Count 3 ERR- entries" "3" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$PROJ"

# 02.2 - Count 0 ERR- entries
PROJ=$(setup_test_project)
cat > "$PROJ/ERRORS.md" <<'EOF'
# ERRORS.md
[no errors yet]
EOF
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" >/dev/null 2>&1
assert_eq "02.2 Count 0 ERR- entries" "0" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$PROJ"

# 02.3 - No ERRORS.md => count 0
PROJ=$(setup_test_project)
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" >/dev/null 2>&1
assert_eq "02.3 No ERRORS.md => count 0" "0" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$PROJ"

# 02.4 - Mixed heading formats (###, ##, bare)
PROJ=$(setup_test_project)
cat > "$PROJ/ERRORS.md" <<'EOF'
# ERRORS.md
### ERR-001: triple hash
## ERR-002: double hash
ERR-003: bare line
mentions ERR-999 inline should NOT count
EOF
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" >/dev/null 2>&1
assert_eq "02.4 Mixed formats: 3 counted" "3" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$PROJ"

# 02.5 - Idempotent overwrite
PROJ=$(setup_test_project)
printf "### ERR-001: First\n### ERR-002: Second\n" > "$PROJ/ERRORS.md"
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" >/dev/null 2>&1
R1=$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)
echo "### ERR-003: Third" >> "$PROJ/ERRORS.md"
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" >/dev/null 2>&1
R2=$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)
assert_eq "02.5a First run = 2" "2" "$R1"
assert_eq "02.5b Second run = 3" "3" "$R2"
rm -rf "$PROJ"

# 02.6 - No CONTRACT.md => no snapshot file written
PROJ=$(mktemp -d)
echo "### ERR-001: ignored" > "$PROJ/ERRORS.md"
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" >/dev/null 2>&1
assert_file_not_exists "02.6 No CONTRACT.md => no snapshot" "$PROJ/.syntaris/errors-at-gate-open.count"
rm -rf "$PROJ"

# 02.7 - Valid JSON output preserved
PROJ=$(setup_test_project)
OUTPUT=$(echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" 2>/dev/null)
TOTAL=$((TOTAL+1))
if echo "$OUTPUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  echo "  [PASS] 02.7 SessionStart emits valid JSON"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 02.7 SessionStart JSON output invalid: '$OUTPUT'"
  FAIL=$((FAIL+1))
  FAILURES+=("02.7 SessionStart JSON")
fi
rm -rf "$PROJ"

# 02.8 - 50 errors stress
PROJ=$(setup_test_project)
echo "# ERRORS.md" > "$PROJ/ERRORS.md"
for i in $(seq 1 50); do printf "### ERR-%03d: Error\n" $i >> "$PROJ/ERRORS.md"; done
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" >/dev/null 2>&1
assert_eq "02.8 50 errors stress" "50" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$PROJ"
