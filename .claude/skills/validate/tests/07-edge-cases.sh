#!/bin/bash
# 07-edge-cases.sh - stress, special chars, garbage input, backwards compat

SESSION_HOOK="$SYNTARIS_ROOT/.claude/hooks/session-start.sh"
CAL_HOOK="$SYNTARIS_ROOT/.claude/hooks/gate-close-calibration.sh"

# 07.1 - 200 errors stress
PROJ=$(setup_test_project)
echo "# ERRORS.md" > "$PROJ/ERRORS.md"
for i in $(seq 1 200); do printf "### ERR-%03d: Error\n" $i >> "$PROJ/ERRORS.md"; done
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$SESSION_HOOK" >/dev/null 2>&1
assert_eq "07.1 200 errors stress" "200" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$PROJ"

# 07.2 - Unicode in error titles
PROJ=$(setup_test_project)
cat > "$PROJ/ERRORS.md" <<'EOF'
# ERRORS.md
### ERR-001: Japanese title
### ERR-002: ñoño edge case
### ERR-003: emoji bug in title
### ERR-004: math symbols
### ERR-005: Cyrillic Privet
EOF
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$SESSION_HOOK" >/dev/null 2>&1
assert_eq "07.2 Unicode/special chars in titles" "5" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$PROJ"

# 07.3 - Path with spaces
BASE=$(mktemp -d)
PROJ="$BASE/project with spaces"
mkdir -p "$PROJ"
cat > "$PROJ/CONTRACT.md" <<'EOF'
PROJECT_NAME: SpacesApp
PROJECT_VERSION: v0.1.0
CLIENT_TYPE: PERSONAL
EOF
printf "### ERR-001: A\n### ERR-002: B\n" > "$PROJ/ERRORS.md"
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$SESSION_HOOK" >/dev/null 2>&1
assert_eq "07.3 Path with spaces" "2" "$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)"
rm -rf "$BASE"

# 07.4 - Garbage in count file is sanitized (digits only kept)
PROJ=$(setup_test_project)
mkdir -p "$PROJ/.syntaris"
printf '\x00\xff garbage \x01 99 abc\n' > "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 2h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 2.0 | Y | n |
EOF
echo "### ERR-001: One" > "$PROJ/ERRORS.md"
CLAUDE_PROJECT_DIR="$PROJ" bash "$CAL_HOOK" "v0.1.0" >/dev/null 2>&1
EXIT=$?
assert_exit_code "07.4a Garbage count file does not crash hook" "0" "$EXIT"
EST=$(grep "^ESTIMATION:" "$PROJ/MEMORY_CORRECTIONS.md" 2>/dev/null)
TOTAL=$((TOTAL+1))
if echo "$EST" | grep -qE "errors_open=[0-9]+"; then
  echo "  [PASS] 07.4b errors_open is numeric after garbage input"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 07.4b errors_open not numeric: $EST"
  FAIL=$((FAIL+1))
  FAILURES+=("07.4b errors_open numeric")
fi
rm -rf "$PROJ"

# 07.5 - Backwards compat: old MEMORY_CORRECTIONS.md without errors_open/close
PROJ=$(setup_test_project)
mkdir -p "$PROJ/.syntaris"
printf '1' > "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/MEMORY_CORRECTIONS.md" <<'EOF'
# MEMORY_CORRECTIONS.md
# Syntaris | Calibration data and reflexion entries

## REFLEXION LOG

ESTIMATION: gate=v0.0.1 estimated=1h actual=1.20h variance=+20% source=timelog date=2026-04-01T10:00:00Z

## PATTERNS

- Pattern: underestimate migrations
EOF
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 2h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 2.0 | Y | n |
EOF
echo "### ERR-001: One" > "$PROJ/ERRORS.md"
CLAUDE_PROJECT_DIR="$PROJ" bash "$CAL_HOOK" "v0.1.0" >/dev/null 2>&1
NEW_FORMAT=$(grep -c "errors_open" "$PROJ/MEMORY_CORRECTIONS.md") || true
NEW_FORMAT="${NEW_FORMAT:-0}"
OLD_PRESERVED=$(grep -c "gate=v0.0.1" "$PROJ/MEMORY_CORRECTIONS.md") || true
OLD_PRESERVED="${OLD_PRESERVED:-0}"
PATTERNS=$(grep -c "^## PATTERNS" "$PROJ/MEMORY_CORRECTIONS.md") || true
PATTERNS="${PATTERNS:-0}"
assert_eq "07.5a Old entry preserved" "1" "$OLD_PRESERVED"
assert_eq "07.5b New entry added with new format" "1" "$NEW_FORMAT"
assert_eq "07.5c PATTERNS section preserved" "1" "$PATTERNS"
rm -rf "$PROJ"

# 07.6 - Concurrent session-start (race condition tolerance)
PROJ=$(setup_test_project)
echo "# ERRORS.md" > "$PROJ/ERRORS.md"
for i in $(seq 1 10); do printf "### ERR-%03d: Error\n" $i >> "$PROJ/ERRORS.md"; done
for i in 1 2 3 4 5; do
  echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$SESSION_HOOK" >/dev/null 2>&1 &
done
wait
R=$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)
# Final value should still be 10 - all writers see the same input
assert_eq "07.6 Concurrent writes settle to 10" "10" "$R"
rm -rf "$PROJ"
