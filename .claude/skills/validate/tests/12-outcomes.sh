#!/bin/bash
# 12-outcomes.sh - Outcomes feature smoke tests (v0.5.0+)
#
# v0.5.0 ships the OUTCOMES.md template + spec-reviewer extension +
# build-rules integration. Automated grading and retry are deferred to
# v0.6.0. These tests verify the integration points are wired up.

R="$SYNTARIS_ROOT"

# 12.1 - foundation/OUTCOMES.md template exists
assert_file_exists "12.1 foundation/OUTCOMES.md template" "$R/foundation/OUTCOMES.md"

# 12.2 - OUTCOMES.md has the expected schema markers
TOTAL=$((TOTAL+1))
if grep -q "## OUT-" "$R/foundation/OUTCOMES.md" 2>/dev/null \
   && grep -q "Status:" "$R/foundation/OUTCOMES.md" 2>/dev/null \
   && grep -q "Success criteria" "$R/foundation/OUTCOMES.md" 2>/dev/null; then
  echo "  [PASS] 12.2 OUTCOMES.md has schema markers"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 12.2 OUTCOMES.md missing schema markers"
  FAIL=$((FAIL+1))
  FAILURES+=("12.2 OUTCOMES.md schema")
fi

# 12.3 - spec-reviewer agent has Outcomes grading section
TOTAL=$((TOTAL+1))
if grep -q "OUTCOMES.md" "$R/.claude/agents/spec-reviewer.md" 2>/dev/null \
   && grep -q "PENDING" "$R/.claude/agents/spec-reviewer.md" 2>/dev/null; then
  echo "  [PASS] 12.3 spec-reviewer extended for Outcomes grading"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 12.3 spec-reviewer missing Outcomes grading"
  FAIL=$((FAIL+1))
  FAILURES+=("12.3 spec-reviewer outcomes")
fi

# 12.4 - build-rules gate-close protocol mentions OUTCOMES.md
TOTAL=$((TOTAL+1))
if grep -q "OUTCOMES.md" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 12.4 build-rules gate-close mentions OUTCOMES"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 12.4 build-rules gate-close missing OUTCOMES ref"
  FAIL=$((FAIL+1))
  FAILURES+=("12.4 build-rules outcomes")
fi

# 12.5 - foundation/CLAUDE.md gate-close mentions OUTCOMES
TOTAL=$((TOTAL+1))
if grep -q "OUTCOMES.md" "$R/foundation/CLAUDE.md" 2>/dev/null; then
  echo "  [PASS] 12.5 foundation/CLAUDE.md mentions OUTCOMES"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 12.5 foundation/CLAUDE.md missing OUTCOMES ref"
  FAIL=$((FAIL+1))
  FAILURES+=("12.5 CLAUDE.md outcomes")
fi
