#!/bin/bash
# 03-gate-close.sh - gate-close-calibration ESTIMATION line tests

HOOK="$SYNTARIS_ROOT/.claude/hooks/gate-close-calibration.sh"

if [[ ! -f "$HOOK" ]]; then
  assert_file_exists "03.0 gate-close-calibration.sh present" "$HOOK"
  return
fi

setup_cal_project() {
  local dir
  dir=$(setup_test_project)
  mkdir -p "$dir/.syntaris"
  echo "$dir"
}

# 03.1 - Basic ESTIMATION line with error delta
PROJ=$(setup_cal_project)
printf '2' > "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| Version | Feature | Hours |
| v0.1.0 | Scaffold | 2h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Setup | 1.5 | Y | n |
| 2026-05-02 | v0.1.0 | Config | 0.5 | Y | n |
EOF
printf "### ERR-001: A\n### ERR-002: B\n### ERR-003: C\n" > "$PROJ/ERRORS.md"
CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" "v0.1.0" >/dev/null 2>&1
EST=$(grep "^ESTIMATION:" "$PROJ/MEMORY_CORRECTIONS.md" 2>/dev/null)
assert_contains "03.1a errors_open=2"   "errors_open=2"   "$EST"
assert_contains "03.1b errors_close=3"  "errors_close=3"  "$EST"
assert_contains "03.1c gate=v0.1.0"     "gate=v0.1.0"     "$EST"
assert_contains "03.1d source=timelog"  "source=timelog"  "$EST"
assert_contains "03.1e actual=2.00"     "actual=2.00"     "$EST"
rm -rf "$PROJ"

# 03.2 - No snapshot file => errors_open=0
PROJ=$(setup_cal_project)
rm -f "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Scaffold | 2h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 2.0 | Y | n |
EOF
printf "### ERR-001: One\n" > "$PROJ/ERRORS.md"
CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" "v0.1.0" >/dev/null 2>&1
EST=$(grep "^ESTIMATION:" "$PROJ/MEMORY_CORRECTIONS.md" 2>/dev/null)
assert_contains "03.2a No snapshot => errors_open=0" "errors_open=0" "$EST"
assert_contains "03.2b errors_close=1" "errors_close=1" "$EST"
rm -rf "$PROJ"

# 03.3 - Idempotent (re-run produces 1 line per gate)
PROJ=$(setup_cal_project)
printf '1' > "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 4h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 4.0 | Y | n |
EOF
printf "### ERR-001: One\n### ERR-002: Two\n" > "$PROJ/ERRORS.md"
CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" "v0.1.0" >/dev/null 2>&1
echo "### ERR-003: Three" >> "$PROJ/ERRORS.md"
CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" "v0.1.0" >/dev/null 2>&1
LINES=$(grep -c "^ESTIMATION: gate=v0.1.0" "$PROJ/MEMORY_CORRECTIONS.md" 2>/dev/null) || true
LINES="${LINES:-0}"
assert_eq "03.3a Idempotent: 1 line per gate" "1" "$LINES"
EST=$(grep "^ESTIMATION:" "$PROJ/MEMORY_CORRECTIONS.md" 2>/dev/null)
assert_contains "03.3b Updated errors_close=3" "errors_close=3" "$EST"
rm -rf "$PROJ"

# 03.4 - Variance > 30% triggers heads-up
PROJ=$(setup_cal_project)
printf '0' > "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 2h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 5.0 | Y | n |
EOF
OUTPUT=$(CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" "v0.1.0" 2>&1)
assert_contains "03.4 Variance heads-up fires at +150%" "Heads up" "$OUTPUT"
rm -rf "$PROJ"

# 03.5 - Range estimate uses midpoint
PROJ=$(setup_cal_project)
printf '0' > "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 2-4h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 3.0 | Y | n |
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" "v0.1.0" >/dev/null 2>&1
EST=$(grep "^ESTIMATION:" "$PROJ/MEMORY_CORRECTIONS.md" 2>/dev/null)
assert_contains "03.5 Range midpoint estimated=3.00" "estimated=3.00" "$EST"
rm -rf "$PROJ"

# 03.6 - Missing VERSION_ROADMAP.md exits 1
PROJ=$(setup_cal_project)
CLAUDE_PROJECT_DIR="$PROJ" bash "$HOOK" "v0.1.0" >/dev/null 2>&1
assert_exit_code "03.6 Missing roadmap exits 1" "1" "$?"
rm -rf "$PROJ"

# 03.7 - No args exits 2
bash "$HOOK" >/dev/null 2>&1
assert_exit_code "03.7 No args exits 2" "2" "$?"
