#!/bin/bash
# 11-pattern-extraction.sh - extract-patterns.sh tests (v0.5.0+)

EXTRACTOR="$SYNTARIS_ROOT/.claude/lib/extract-patterns.sh"

if [[ ! -f "$EXTRACTOR" ]]; then
  assert_file_exists "11.0 extract-patterns.sh present" "$EXTRACTOR"
  return
fi

# 11.1 - Insufficient data exits 2 (clean signal, not failure)
PROJ=$(setup_test_project)
cat > "$PROJ/MEMORY_CORRECTIONS.md" <<'EOF'
ESTIMATION: gate=v0.1.0 estimated=2h actual=2.0h variance=+0% source=timelog errors_open=0 errors_close=0 date=2026-04-01T10:00:00Z
ESTIMATION: gate=v0.2.0 estimated=4h actual=4.0h variance=+0% source=timelog errors_open=0 errors_close=0 date=2026-04-08T10:00:00Z
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
assert_exit_code "11.1 Fewer than 5 entries exits 2" "2" "$?"
rm -rf "$PROJ"

# 11.2 - Missing MEMORY_CORRECTIONS.md exits 1
PROJ=$(setup_test_project)
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
assert_exit_code "11.2 Missing MEMORY_CORRECTIONS.md exits 1" "1" "$?"
rm -rf "$PROJ"

# 11.3 - 6 entries with consistent +28% variance => project-systemic pattern detected
PROJ=$(setup_test_project)
cat > "$PROJ/MEMORY_CORRECTIONS.md" <<'EOF'
ESTIMATION: gate=v0.1.0 estimated=2h actual=2.40h variance=+20% source=timelog errors_open=0 errors_close=2 date=2026-04-01T10:00:00Z
ESTIMATION: gate=v0.2.0 estimated=4h actual=5.20h variance=+30% source=timelog errors_open=2 errors_close=4 date=2026-04-08T10:00:00Z
ESTIMATION: gate=v0.3.0 estimated=3h actual=3.90h variance=+30% source=git errors_open=1 errors_close=1 date=2026-04-15T10:00:00Z
ESTIMATION: gate=v0.4.0 estimated=6h actual=7.80h variance=+30% source=git errors_open=3 errors_close=5 date=2026-04-22T10:00:00Z
ESTIMATION: gate=v0.5.0 estimated=5h actual=6.50h variance=+30% source=timelog errors_open=2 errors_close=3 date=2026-04-29T10:00:00Z
ESTIMATION: gate=v0.6.0 estimated=4h actual=5.20h variance=+30% source=timelog errors_open=1 errors_close=1 date=2026-05-06T10:00:00Z
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
assert_file_exists "11.3a Proposed patterns file written" "$PROJ/.syntaris/proposed-patterns.md"
TOTAL=$((TOTAL+1))
if grep -q "Project-level systemic estimation bias" "$PROJ/.syntaris/proposed-patterns.md" 2>/dev/null; then
  echo "  [PASS] 11.3b Project-systemic pattern detected"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 11.3b Project-systemic pattern not detected"
  FAIL=$((FAIL+1))
  FAILURES+=("11.3b project-systemic")
fi
TOTAL=$((TOTAL+1))
if grep -q "Confidence: MEDIUM" "$PROJ/.syntaris/proposed-patterns.md" 2>/dev/null; then
  echo "  [PASS] 11.3c MEDIUM confidence at 6 data points"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 11.3c MEDIUM confidence not assigned"
  FAIL=$((FAIL+1))
  FAILURES+=("11.3c MEDIUM confidence")
fi
rm -rf "$PROJ"

# 11.4 - Idempotent: re-run with same input produces same proposals
PROJ=$(setup_test_project)
cat > "$PROJ/MEMORY_CORRECTIONS.md" <<'EOF'
ESTIMATION: gate=v0.1.0 estimated=2h actual=2.40h variance=+20% source=timelog errors_open=0 errors_close=2 date=2026-04-01T10:00:00Z
ESTIMATION: gate=v0.2.0 estimated=4h actual=5.20h variance=+30% source=timelog errors_open=2 errors_close=4 date=2026-04-08T10:00:00Z
ESTIMATION: gate=v0.3.0 estimated=3h actual=3.90h variance=+30% source=git errors_open=1 errors_close=1 date=2026-04-15T10:00:00Z
ESTIMATION: gate=v0.4.0 estimated=6h actual=7.80h variance=+30% source=git errors_open=3 errors_close=5 date=2026-04-22T10:00:00Z
ESTIMATION: gate=v0.5.0 estimated=5h actual=6.50h variance=+30% source=timelog errors_open=2 errors_close=3 date=2026-04-29T10:00:00Z
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
H1=$(grep -c "^### PAT-" "$PROJ/.syntaris/proposed-patterns.md")
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
H2=$(grep -c "^### PAT-" "$PROJ/.syntaris/proposed-patterns.md")
assert_eq "11.4 Idempotent: same proposal count on re-run" "$H1" "$H2"
rm -rf "$PROJ"

# 11.5 - PAT numbering continues from MEMORY_SEMANTIC.md max
PROJ=$(setup_test_project)
cat > "$PROJ/MEMORY_SEMANTIC.md" <<'EOF'
## PATTERNS

### PAT-005: Existing pattern
Confidence: HIGH
EOF
cat > "$PROJ/MEMORY_CORRECTIONS.md" <<'EOF'
ESTIMATION: gate=v0.1.0 estimated=2h actual=2.40h variance=+20% source=timelog errors_open=0 errors_close=2 date=2026-04-01T10:00:00Z
ESTIMATION: gate=v0.2.0 estimated=4h actual=5.20h variance=+30% source=timelog errors_open=2 errors_close=4 date=2026-04-08T10:00:00Z
ESTIMATION: gate=v0.3.0 estimated=3h actual=3.90h variance=+30% source=git errors_open=1 errors_close=1 date=2026-04-15T10:00:00Z
ESTIMATION: gate=v0.4.0 estimated=6h actual=7.80h variance=+30% source=git errors_open=3 errors_close=5 date=2026-04-22T10:00:00Z
ESTIMATION: gate=v0.5.0 estimated=5h actual=6.50h variance=+30% source=timelog errors_open=2 errors_close=3 date=2026-04-29T10:00:00Z
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
TOTAL=$((TOTAL+1))
if grep -q "^### PAT-006:" "$PROJ/.syntaris/proposed-patterns.md" 2>/dev/null; then
  echo "  [PASS] 11.5 New pattern IDs continue from MEMORY_SEMANTIC max"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 11.5 PAT numbering does not continue from existing"
  FAIL=$((FAIL+1))
  FAILURES+=("11.5 PAT numbering")
fi
rm -rf "$PROJ"

# 11.6 - HIGH confidence at 7+ data points
PROJ=$(setup_test_project)
cat > "$PROJ/MEMORY_CORRECTIONS.md" <<'EOF'
ESTIMATION: gate=v0.1.0 estimated=2h actual=2.40h variance=+20% source=timelog errors_open=0 errors_close=2 date=2026-04-01T10:00:00Z
ESTIMATION: gate=v0.2.0 estimated=4h actual=5.20h variance=+30% source=timelog errors_open=2 errors_close=4 date=2026-04-08T10:00:00Z
ESTIMATION: gate=v0.3.0 estimated=3h actual=3.90h variance=+30% source=git errors_open=1 errors_close=1 date=2026-04-15T10:00:00Z
ESTIMATION: gate=v0.4.0 estimated=6h actual=7.80h variance=+30% source=git errors_open=3 errors_close=5 date=2026-04-22T10:00:00Z
ESTIMATION: gate=v0.5.0 estimated=5h actual=6.50h variance=+30% source=timelog errors_open=2 errors_close=3 date=2026-04-29T10:00:00Z
ESTIMATION: gate=v0.6.0 estimated=4h actual=5.20h variance=+30% source=timelog errors_open=1 errors_close=1 date=2026-05-06T10:00:00Z
ESTIMATION: gate=v0.7.0 estimated=3h actual=3.90h variance=+30% source=timelog errors_open=2 errors_close=2 date=2026-05-13T10:00:00Z
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
TOTAL=$((TOTAL+1))
if grep -q "^Confidence: HIGH" "$PROJ/.syntaris/proposed-patterns.md" 2>/dev/null; then
  echo "  [PASS] 11.6 HIGH confidence at 7 data points"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 11.6 HIGH confidence not assigned at 7+ points"
  FAIL=$((FAIL+1))
  FAILURES+=("11.6 HIGH confidence")
fi
rm -rf "$PROJ"
