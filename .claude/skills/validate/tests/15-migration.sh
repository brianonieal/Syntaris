#!/bin/bash
# 15-migration.sh - migrate-reflexion-to-estimation.sh tests (v0.6.0+)
#
# Verifies the migration helper that backfills structured ESTIMATION:
# lines from existing narrative REFLEXION blocks. Critical for projects
# that ran on pre-v0.6.0 hooks without the calibration hook firing.

MIGRATOR="$SYNTARIS_ROOT/scripts/migrate-reflexion-to-estimation.sh"
EXTRACTOR="$SYNTARIS_ROOT/.claude/lib/extract-patterns.sh"

# 15.1 - Migrator script exists
assert_file_exists "15.1 migrate-reflexion-to-estimation.sh present" "$MIGRATOR"

if [[ ! -f "$MIGRATOR" ]]; then return; fi

# 15.2 - Migrator parses narrative REFLEXION blocks and adds ESTIMATION lines
PROJ=$(setup_test_project)
mkdir -p "$PROJ/foundation"
cat > "$PROJ/foundation/MEMORY_CORRECTIONS.md" <<'EOF'
# MEMORY_CORRECTIONS.md

## REFLEXION LOG

### REFLEXION: v0.0.0 — Foundation
Date: 2026-05-01
Project: TestApp

ESTIMATE
  Predicted: 4 hours
  Actual:    2 hours
  Variance:  -50%

### REFLEXION: v0.1.0 — Core
Date: 2026-05-02
Project: TestApp

ESTIMATE
  Predicted: 8 hours
  Actual:    5 hours
  Variance:  -38%
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$MIGRATOR" >/dev/null 2>&1
LINES=$(grep -c "^ESTIMATION:" "$PROJ/foundation/MEMORY_CORRECTIONS.md")
assert_eq "15.2 Migration adds ESTIMATION lines for all REFLEXION blocks" "2" "$LINES"
rm -rf "$PROJ"

# 15.3 - Migration is idempotent (re-running doesn't duplicate)
PROJ=$(setup_test_project)
mkdir -p "$PROJ/foundation"
cat > "$PROJ/foundation/MEMORY_CORRECTIONS.md" <<'EOF'
# MEMORY_CORRECTIONS.md

## REFLEXION LOG

### REFLEXION: v0.0.0 — Foundation
Date: 2026-05-01
Project: TestApp

ESTIMATE
  Predicted: 4 hours
  Actual:    2 hours
  Variance:  -50%
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$MIGRATOR" >/dev/null 2>&1
CLAUDE_PROJECT_DIR="$PROJ" bash "$MIGRATOR" >/dev/null 2>&1
LINES=$(grep -c "^ESTIMATION:" "$PROJ/foundation/MEMORY_CORRECTIONS.md")
assert_eq "15.3 Migration idempotent - 1 line per gate after 2 runs" "1" "$LINES"
rm -rf "$PROJ"

# 15.4 - Migration creates a backup
PROJ=$(setup_test_project)
mkdir -p "$PROJ/foundation"
cat > "$PROJ/foundation/MEMORY_CORRECTIONS.md" <<'EOF'
### REFLEXION: v0.0.0
Date: 2026-05-01
ESTIMATE
  Predicted: 4 hours
  Actual:    2 hours
  Variance:  -50%
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$MIGRATOR" >/dev/null 2>&1
assert_file_exists "15.4 Migration backup created" "$PROJ/foundation/MEMORY_CORRECTIONS.md.pre-migration.bak"
rm -rf "$PROJ"

# 15.5 - End-to-end: migrate then extract patterns
PROJ=$(setup_test_project)
mkdir -p "$PROJ/foundation"
cat > "$PROJ/foundation/MEMORY_CORRECTIONS.md" <<'EOF'
## REFLEXION LOG

### REFLEXION: v0.0.0
Date: 2026-05-01
ESTIMATE
  Predicted: 4 hours
  Actual: 2 hours
  Variance: -50%

### REFLEXION: v0.1.0
Date: 2026-05-02
ESTIMATE
  Predicted: 8 hours
  Actual: 4 hours
  Variance: -50%

### REFLEXION: v0.2.0
Date: 2026-05-03
ESTIMATE
  Predicted: 6 hours
  Actual: 3 hours
  Variance: -50%

### REFLEXION: v0.3.0
Date: 2026-05-04
ESTIMATE
  Predicted: 5 hours
  Actual: 2.5 hours
  Variance: -50%

### REFLEXION: v0.4.0
Date: 2026-05-05
ESTIMATE
  Predicted: 4 hours
  Actual: 2 hours
  Variance: -50%
EOF
CLAUDE_PROJECT_DIR="$PROJ" bash "$MIGRATOR" >/dev/null 2>&1
CLAUDE_PROJECT_DIR="$PROJ" bash "$EXTRACTOR" >/dev/null 2>&1
TOTAL=$((TOTAL+1))
if [[ -f "$PROJ/.syntaris/proposed-patterns.md" ]] \
   && grep -q "Project-level systemic estimation bias" "$PROJ/.syntaris/proposed-patterns.md"; then
  echo "  [PASS] 15.5 End-to-end: narrative -> migrated -> pattern extracted"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 15.5 End-to-end migration+extraction failed"
  FAIL=$((FAIL+1))
  FAILURES+=("15.5 e2e migration")
fi
rm -rf "$PROJ"
