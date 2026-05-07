#!/bin/bash
# 14-foundation-paths.sh - foundation/ path resolution tests (v0.6.0+)
#
# Verifies that hooks and lib scripts find foundation files in
# foundation/<file>.md (preferred) or <file>.md at project root (legacy
# fallback). The v0.5.x bug looked at root only, missing actual
# Syntaris-convention foundation files.

CAL_HOOK="$SYNTARIS_ROOT/.claude/hooks/gate-close-calibration.sh"
EXTRACTOR="$SYNTARIS_ROOT/.claude/lib/extract-patterns.sh"

# 14.1 - Calibration hook finds MEMORY_CORRECTIONS.md in foundation/
PROJ=$(setup_test_project)
mkdir -p "$PROJ/foundation"
mkdir -p "$PROJ/.syntaris"
printf '0' > "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/foundation/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 2h |
EOF
cat > "$PROJ/foundation/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 2.0 | Y | n |
EOF
echo "### ERR-001: Test" > "$PROJ/foundation/ERRORS.md"
CLAUDE_PROJECT_DIR="$PROJ" bash "$CAL_HOOK" "v0.1.0" >/dev/null 2>&1
assert_file_exists "14.1 Calibration writes to foundation/MEMORY_CORRECTIONS.md" "$PROJ/foundation/MEMORY_CORRECTIONS.md"
rm -rf "$PROJ"

# 14.2 - Calibration hook finds files at project root (legacy)
PROJ=$(setup_test_project)
mkdir -p "$PROJ/.syntaris"
printf '0' > "$PROJ/.syntaris/errors-at-gate-open.count"
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 2h |
EOF
cat > "$PROJ/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 2.0 | Y | n |
EOF
echo "### ERR-001: Test" > "$PROJ/ERRORS.md"
CLAUDE_PROJECT_DIR="$PROJ" bash "$CAL_HOOK" "v0.1.0" >/dev/null 2>&1
# Should write to root since no foundation dir exists
assert_file_exists "14.2 Legacy: writes to root MEMORY_CORRECTIONS.md when no foundation/" "$PROJ/MEMORY_CORRECTIONS.md"
rm -rf "$PROJ"

# 14.3 - Foundation path is preferred when both exist
PROJ=$(setup_test_project)
mkdir -p "$PROJ/foundation"
mkdir -p "$PROJ/.syntaris"
printf '0' > "$PROJ/.syntaris/errors-at-gate-open.count"
# Place ROADMAP at root only - fall back behavior
cat > "$PROJ/foundation/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 3h |
EOF
cat > "$PROJ/VERSION_ROADMAP.md" <<'EOF'
| v0.1.0 | Feature | 99h |
EOF
cat > "$PROJ/foundation/TIMELOG.md" <<'EOF'
| Date | Gate | Task | Hours | Billable | Notes |
|------|------|------|-------|----------|-------|
| 2026-05-01 | v0.1.0 | Work | 3.0 | Y | n |
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$CAL_HOOK" "v0.1.0" >/dev/null 2>&1
EST=$(grep "^ESTIMATION:" "$PROJ/foundation/MEMORY_CORRECTIONS.md" 2>/dev/null)
# Should pick the foundation/ ROADMAP (3h) not the root one (99h)
assert_contains "14.3 foundation/ takes precedence over root" "estimated=3" "$EST"
rm -rf "$PROJ"

# 14.4 - Pattern extractor finds MEMORY_CORRECTIONS.md in foundation/
PROJ=$(setup_test_project)
mkdir -p "$PROJ/foundation"
cat > "$PROJ/foundation/MEMORY_CORRECTIONS.md" <<'EOF'
ESTIMATION: gate=v0.1.0 estimated=2h actual=2.40h variance=+20% source=timelog errors_open=0 errors_close=0 date=2026-04-01T10:00:00Z
ESTIMATION: gate=v0.2.0 estimated=4h actual=5.20h variance=+30% source=timelog errors_open=0 errors_close=0 date=2026-04-08T10:00:00Z
ESTIMATION: gate=v0.3.0 estimated=3h actual=3.90h variance=+30% source=timelog errors_open=0 errors_close=0 date=2026-04-15T10:00:00Z
ESTIMATION: gate=v0.4.0 estimated=6h actual=7.80h variance=+30% source=timelog errors_open=0 errors_close=0 date=2026-04-22T10:00:00Z
ESTIMATION: gate=v0.5.0 estimated=5h actual=6.50h variance=+30% source=timelog errors_open=0 errors_close=0 date=2026-04-29T10:00:00Z
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
assert_file_exists "14.4 Extractor reads from foundation/ and writes proposals" "$PROJ/.syntaris/proposed-patterns.md"
rm -rf "$PROJ"
