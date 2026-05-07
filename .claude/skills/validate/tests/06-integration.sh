#!/bin/bash
# 06-integration.sh - full cycle: session start -> work -> gate close

SESSION_HOOK="$SYNTARIS_ROOT/.claude/hooks/session-start.sh"
CAL_HOOK="$SYNTARIS_ROOT/.claude/hooks/gate-close-calibration.sh"

if [[ ! -f "$SESSION_HOOK" || ! -f "$CAL_HOOK" ]]; then
  assert_file_exists "06.0 session-start.sh present" "$SESSION_HOOK"
  assert_file_exists "06.0 gate-close-calibration.sh present" "$CAL_HOOK"
  return
fi

PROJ=$(mktemp -d)
cat > "$PROJ/CONTRACT.md" <<'EOF'
PROJECT_NAME: IntegrationTest
PROJECT_VERSION: v0.2.0
CLIENT_TYPE: PERSONAL
EOF
cat > "$PROJ/ERRORS.md" <<'EOF'
# ERRORS.md
### ERR-001: Connection pool exhausted under load
### ERR-002: Auth redirect loop on Safari
EOF
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| Version | Feature | Hours |
| v0.2.0 | Data Layer | 3-5h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.2.0 | Schema | 1.5 | Y | Models |
| 2026-05-01 | v0.2.0 | Migrations | 1.0 | Y | Alembic |
| 2026-05-02 | v0.2.0 | RLS | 2.0 | Y | Policies |
| 2026-05-02 | v0.2.0 | Tests | 1.5 | Y | 12 tests |
EOF

# Step 1: session start snapshots 2 errors
echo '{"event":"SessionStart"}' | CLAUDE_PROJECT_DIR="$PROJ" bash "$SESSION_HOOK" >/dev/null 2>&1
SNAPSHOT=$(cat "$PROJ/.syntaris/errors-at-gate-open.count" 2>/dev/null)
assert_eq "06.1 Session start snapshots 2 errors" "2" "$SNAPSHOT"

# Step 2: 2 new errors discovered during gate
cat >> "$PROJ/ERRORS.md" <<'EOF'
### ERR-003: N+1 query in dashboard endpoint
### ERR-004: UTC offset bug in timelog display
EOF

# Step 3: gate close
CLAUDE_PROJECT_DIR="$PROJ" bash "$CAL_HOOK" "v0.2.0" >/dev/null 2>&1
EST=$(grep "^ESTIMATION:" "$PROJ/MEMORY_CORRECTIONS.md" 2>/dev/null)
assert_contains "06.2 gate=v0.2.0"        "gate=v0.2.0"        "$EST"
assert_contains "06.3 estimated=4.00"     "estimated=4.00"     "$EST"
assert_contains "06.4 actual=6.00"        "actual=6.00"        "$EST"
assert_contains "06.5 source=timelog"     "source=timelog"     "$EST"
assert_contains "06.6 errors_open=2"      "errors_open=2"      "$EST"
assert_contains "06.7 errors_close=4"     "errors_close=4"     "$EST"
assert_contains "06.8 variance=+50%"      "variance=+50%"      "$EST"

# Step 4: MEMORY_CORRECTIONS.md format
TOTAL=$((TOTAL+1))
if grep -q "^## REFLEXION LOG" "$PROJ/MEMORY_CORRECTIONS.md"; then
  echo "  [PASS] 06.9 MEMORY_CORRECTIONS.md has REFLEXION LOG section"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 06.9 MEMORY_CORRECTIONS.md missing section header"
  FAIL=$((FAIL+1))
  FAILURES+=("06.9 REFLEXION LOG header")
fi

rm -rf "$PROJ"
