#!/bin/bash
# 13-adopt-mode.sh - adopt-mode wiring tests (v0.5.2+)
#
# Verifies that /start has the adopt-mode branch (for bringing
# Syntaris to existing code) and that /build-rules has a matching
# adopt-mode shortcut. README's "Adopting Syntaris in an existing
# project" subsection requires both.

R="$SYNTARIS_ROOT"

# 13.1 - /start has the adopt branch
TOTAL=$((TOTAL+1))
if grep -qi "adopt" "$R/.claude/skills/start/SKILL.md" 2>/dev/null \
   && grep -q "existing project\|existing code" "$R/.claude/skills/start/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 13.1 /start mentions adopt-mode for existing projects"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 13.1 /start missing adopt-mode branch"
  FAIL=$((FAIL+1))
  FAILURES+=("13.1 /start adopt branch")
fi

# 13.2 - /start checks for project file detection (package.json, etc.)
TOTAL=$((TOTAL+1))
if grep -q "package.json\|pyproject.toml\|Cargo.toml\|go.mod" "$R/.claude/skills/start/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 13.2 /start detects existing project files for adopt mode"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 13.2 /start missing project-file detection"
  FAIL=$((FAIL+1))
  FAILURES+=("13.2 /start project-file detection")
fi

# 13.3 - /start has adopt bootstrap that skips Steps 3-5 (idea dump, landscape, stack)
TOTAL=$((TOTAL+1))
if grep -qi "skip.*step.*3\|skip.*idea\|skip.*competitive\|adopt-mode bootstrap" "$R/.claude/skills/start/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 13.3 /start adopt mode skips from-scratch steps"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 13.3 /start adopt mode does not document step-skipping"
  FAIL=$((FAIL+1))
  FAILURES+=("13.3 /start adopt skip-steps")
fi

# 13.4 - /build-rules has adopt-mode shortcut
TOTAL=$((TOTAL+1))
if grep -qi "adopt-mode\|adopt mode" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 13.4 /build-rules has adopt-mode shortcut"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 13.4 /build-rules missing adopt-mode shortcut"
  FAIL=$((FAIL+1))
  FAILURES+=("13.4 /build-rules adopt mode")
fi

# 13.5 - /build-rules adopt path documents forward-only roadmap
TOTAL=$((TOTAL+1))
if grep -qi "forward.only\|forward-only\|forward roadmap" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 13.5 /build-rules adopt path documents forward-only roadmap"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 13.5 /build-rules adopt path missing forward-only roadmap concept"
  FAIL=$((FAIL+1))
  FAILURES+=("13.5 /build-rules forward-only")
fi
