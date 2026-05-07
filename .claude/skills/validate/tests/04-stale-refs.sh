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
