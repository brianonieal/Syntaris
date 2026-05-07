#!/bin/bash
# 04-stale-refs.sh - sweep for stale references in active source files
#
# Excludes: .git/, archive/, CHANGELOG.md (history is OK), MIGRATION.md
# (history is OK), docs/distribution/ (drafts are OK).

R="$SYNTARIS_ROOT"

# 04.1 - No ONBOARDING_MODE in active code
COUNT=$(grep -r "ONBOARDING_MODE" \
  --include="*.md" --include="*.sh" --include="*.ps1" --include="*.json" \
  --exclude-dir=.git --exclude-dir=archive --exclude-dir=Syntaris \
  "$R" 2>/dev/null \
  | grep -v "CHANGELOG.md" \
  | grep -v "MIGRATION.md" \
  | wc -l)
assert_eq "04.1 No ONBOARDING_MODE in active code" "0" "$COUNT"

# 04.2 - No "casual coder" outside drafts
COUNT=$(grep -ri "casual coder" \
  --include="*.md" --include="*.sh" --include="*.ps1" \
  --exclude-dir=.git --exclude-dir=archive --exclude-dir=Syntaris \
  "$R" 2>/dev/null \
  | grep -v "CHANGELOG.md" \
  | grep -v "MIGRATION.md" \
  | grep -v "docs/distribution/" \
  | wc -l)
assert_eq "04.2 No 'casual coder' in active code" "0" "$COUNT"

# 04.3 - CONTRACT.md template uses PROJECT_TYPE not CLIENT_TYPE
TOTAL=$((TOTAL+1))
if grep -q "^CLIENT_TYPE" "$R/foundation/CONTRACT.md" 2>/dev/null; then
  echo "  [FAIL] 04.3 CONTRACT.md template still has CLIENT_TYPE"
  FAIL=$((FAIL+1))
  FAILURES+=("04.3 CLIENT_TYPE in template")
else
  echo "  [PASS] 04.3 CONTRACT.md uses PROJECT_TYPE not CLIENT_TYPE"
  PASS=$((PASS+1))
fi

# 04.4 - PROJECT_TYPE present in template
TOTAL=$((TOTAL+1))
if grep -q "^PROJECT_TYPE" "$R/foundation/CONTRACT.md" 2>/dev/null; then
  echo "  [PASS] 04.4 PROJECT_TYPE present in CONTRACT.md template"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 04.4 PROJECT_TYPE missing from CONTRACT.md template"
  FAIL=$((FAIL+1))
  FAILURES+=("04.4 PROJECT_TYPE missing")
fi

# 04.5 - "New to Syntaris?" not in /start skill
COUNT=$(grep -ci "new to syntaris" "$R/.claude/skills/start/SKILL.md" 2>/dev/null) || true
COUNT="${COUNT:-0}"
assert_eq "04.5 'New to Syntaris?' not in /start" "0" "$COUNT"

# 04.6 - No "concise mode" / "casual mode" gatekeeping in /start
COUNT=$(grep -ci "concise mode\|casual mode" "$R/.claude/skills/start/SKILL.md" 2>/dev/null) || true
COUNT="${COUNT:-0}"
assert_eq "04.6 No old onboarding-mode gatekeeping in /start" "0" "$COUNT"

# 04.7 - v0.5.1+ gate model: SCOPE CONFIRMED retired in active code
# (Self-exclude tests/04-stale-refs.sh since it contains the literal pattern.)
COUNT=$(grep -rln "SCOPE CONFIRMED" \
  --include="*.md" --include="*.sh" --include="*.ps1" \
  --exclude-dir=.git --exclude-dir=archive \
  "$R" 2>/dev/null \
  | grep -v "CHANGELOG.md" \
  | grep -v "MIGRATION.md" \
  | grep -v "tests/04-stale-refs.sh" \
  | wc -l)
assert_eq "04.7 No SCOPE CONFIRMED in active code (renamed to CONFIRMED at gate level, BUILD APPROVED at project level)" "0" "$COUNT"

# 04.8 - v0.5.1+ gate model: TESTS APPROVED retired in active code
# Exclusions: history docs (CHANGELOG, MIGRATION, BUILD_NEXT), version-table
# entry in README, this self-test file. Active skills + hooks + foundation
# templates must not mention TESTS APPROVED.
COUNT=$(grep -rln "TESTS APPROVED" \
  --include="*.md" --include="*.sh" --include="*.ps1" \
  --exclude-dir=.git --exclude-dir=archive \
  "$R" 2>/dev/null \
  | grep -v "CHANGELOG.md" \
  | grep -v "MIGRATION.md" \
  | grep -v "BUILD_NEXT.md" \
  | grep -v "/README.md" \
  | grep -v "tests/04-stale-refs.sh" \
  | wc -l)
assert_eq "04.8 No TESTS APPROVED in active skills/hooks/foundation" "0" "$COUNT"

# 04.9 - foundation/CLAUDE.md and build-rules reference BUILD APPROVED
TOTAL=$((TOTAL+1))
if grep -q "BUILD APPROVED" "$R/foundation/CLAUDE.md" 2>/dev/null \
   && grep -q "BUILD APPROVED" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 04.9 BUILD APPROVED present in foundation/CLAUDE.md and build-rules"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 04.9 BUILD APPROVED missing from methodology docs"
  FAIL=$((FAIL+1))
  FAILURES+=("04.9 BUILD APPROVED methodology")
fi

# 04.10 - foundation/CLAUDE.md and build-rules reference ROADMAP APPROVED
TOTAL=$((TOTAL+1))
if grep -q "ROADMAP APPROVED" "$R/foundation/CLAUDE.md" 2>/dev/null \
   && grep -q "ROADMAP APPROVED" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 04.10 ROADMAP APPROVED present in methodology docs"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 04.10 ROADMAP APPROVED missing from methodology docs"
  FAIL=$((FAIL+1))
  FAILURES+=("04.10 ROADMAP APPROVED methodology")
fi
