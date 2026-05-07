#!/bin/bash
# 05-cross-file.sh - cross-file consistency: every referenced artifact exists,
# .gitattributes enforces line endings, format parity bash/PS for new fields

R="$SYNTARIS_ROOT"

# 05.1 - All 7 expected agents present
EXPECTED_AGENTS="research-agent debug-agent health-agent critical-thinker-agent spec-reviewer test-writer security-auditor"
for agent in $EXPECTED_AGENTS; do
  assert_file_exists "05.1 agent: $agent" "$R/.claude/agents/${agent}.md"
done

# 05.2 - Skill count v0.5.0: 15 skills (14 from v0.3.0 + /validate from v0.4.0)
SKILL_COUNT=$(ls "$R/.claude/skills/" 2>/dev/null | wc -l)
assert_eq "05.2 Skill count = 15 (v0.4.0+/validate)" "15" "$SKILL_COUNT"

# 05.3 - Hook count: 10 .sh + 10 .ps1
BASH_COUNT=$(ls "$R/.claude/hooks/"*.sh 2>/dev/null | wc -l)
PS_COUNT=$(ls "$R/.claude/hooks/"*.ps1 2>/dev/null | wc -l)
assert_eq "05.3a Bash hooks = 10" "10" "$BASH_COUNT"
assert_eq "05.3b PowerShell hooks = 10" "10" "$PS_COUNT"

# 05.4 - .gitattributes enforces LF on .sh
TOTAL=$((TOTAL+1))
if grep -q "^\*\.sh.*eol=lf" "$R/.gitattributes" 2>/dev/null; then
  echo "  [PASS] 05.4 .gitattributes enforces LF on *.sh"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.4 .gitattributes missing 'eol=lf' for .sh files"
  FAIL=$((FAIL+1))
  FAILURES+=("05.4 .gitattributes")
fi

# 05.5 - Both calibration hooks have errors_open/errors_close in ESTIMATION line
TOTAL=$((TOTAL+1))
if grep -q "errors_open=" "$R/.claude/hooks/gate-close-calibration.sh" \
   && grep -q "errors_close=" "$R/.claude/hooks/gate-close-calibration.sh"; then
  echo "  [PASS] 05.5a Bash calibration hook has errors_open/close"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.5a Bash calibration hook missing errors_open/close"
  FAIL=$((FAIL+1))
  FAILURES+=("05.5a bash hook missing diag delta")
fi

TOTAL=$((TOTAL+1))
if grep -q "errors_open=" "$R/.claude/hooks/gate-close-calibration.ps1" \
   && grep -q "errors_close=" "$R/.claude/hooks/gate-close-calibration.ps1"; then
  echo "  [PASS] 05.5b PowerShell calibration hook has errors_open/close"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.5b PowerShell calibration hook missing errors_open/close"
  FAIL=$((FAIL+1))
  FAILURES+=("05.5b ps1 hook missing diag delta")
fi

# 05.6 - Both session-start hooks snapshot errors-at-gate-open.count
for ext in sh ps1; do
  TOTAL=$((TOTAL+1))
  if grep -q "errors-at-gate-open.count" "$R/.claude/hooks/session-start.$ext"; then
    echo "  [PASS] 05.6 session-start.$ext snapshots error count"
    PASS=$((PASS+1))
  else
    echo "  [FAIL] 05.6 session-start.$ext missing error snapshot"
    FAIL=$((FAIL+1))
    FAILURES+=("05.6 session-start.$ext")
  fi
done

# 05.7 - testing skill references COMPONENT_REGISTRY (Task 6 traceability)
TOTAL=$((TOTAL+1))
if grep -q "COMPONENT_REGISTRY" "$R/.claude/skills/testing/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 05.7 testing skill references COMPONENT_REGISTRY"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.7 testing skill missing COMPONENT_REGISTRY ref"
  FAIL=$((FAIL+1))
  FAILURES+=("05.7 testing skill")
fi

# 05.8 - test-writer agent references COMPONENT_REGISTRY
TOTAL=$((TOTAL+1))
if grep -q "COMPONENT_REGISTRY" "$R/.claude/agents/test-writer.md" 2>/dev/null; then
  echo "  [PASS] 05.8 test-writer references COMPONENT_REGISTRY"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.8 test-writer missing COMPONENT_REGISTRY ref"
  FAIL=$((FAIL+1))
  FAILURES+=("05.8 test-writer")
fi

# 05.9 - spec-reviewer flags UNTESTED components
TOTAL=$((TOTAL+1))
if grep -q "UNTESTED" "$R/.claude/agents/spec-reviewer.md" 2>/dev/null; then
  echo "  [PASS] 05.9 spec-reviewer flags untested components"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.9 spec-reviewer missing UNTESTED check"
  FAIL=$((FAIL+1))
  FAILURES+=("05.9 spec-reviewer")
fi

# 05.10 - COMPONENT_REGISTRY.md template has Test File column
TOTAL=$((TOTAL+1))
if grep -q "Test File" "$R/foundation/COMPONENT_REGISTRY.md" 2>/dev/null; then
  echo "  [PASS] 05.10 COMPONENT_REGISTRY has Test File column"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.10 COMPONENT_REGISTRY missing Test File column"
  FAIL=$((FAIL+1))
  FAILURES+=("05.10 COMPONENT_REGISTRY")
fi

# 05.11 - HOOKS.md documents the error snapshot
TOTAL=$((TOTAL+1))
if grep -q "errors-at-gate-open" "$R/docs/HOOKS.md" 2>/dev/null; then
  echo "  [PASS] 05.11 HOOKS.md documents error snapshot"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.11 HOOKS.md doesn't document error snapshot"
  FAIL=$((FAIL+1))
  FAILURES+=("05.11 HOOKS.md")
fi

# 05.12a - build-rules skill references /validate at gate close (Layer 1)
TOTAL=$((TOTAL+1))
if grep -q "/validate" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 05.12a build-rules skill references /validate"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.12a build-rules skill missing /validate ref at gate close"
  FAIL=$((FAIL+1))
  FAILURES+=("05.12a build-rules /validate ref")
fi

# 05.12b - foundation/CLAUDE.md gate-close protocol references /validate
TOTAL=$((TOTAL+1))
if grep -q "/validate" "$R/foundation/CLAUDE.md" 2>/dev/null; then
  echo "  [PASS] 05.12b foundation/CLAUDE.md references /validate at gate close"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.12b foundation/CLAUDE.md missing /validate ref"
  FAIL=$((FAIL+1))
  FAILURES+=("05.12b foundation/CLAUDE.md /validate ref")
fi

# 05.12c - health-agent checks /validate freshness (Layer 3)
TOTAL=$((TOTAL+1))
if grep -q "validate" "$R/.claude/agents/health-agent.md" 2>/dev/null \
   && grep -q "skill-log" "$R/.claude/agents/health-agent.md" 2>/dev/null; then
  echo "  [PASS] 05.12c health-agent checks /validate freshness"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.12c health-agent missing /validate freshness check"
  FAIL=$((FAIL+1))
  FAILURES+=("05.12c health-agent /validate freshness")
fi

# 05.12d - GitHub Actions CI workflow exists (Layer 2)
TOTAL=$((TOTAL+1))
if [[ -f "$R/.github/workflows/validate.yml" ]]; then
  echo "  [PASS] 05.12d GitHub Actions validate.yml exists"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.12d GitHub Actions validate.yml missing"
  FAIL=$((FAIL+1))
  FAILURES+=("05.12d CI workflow")
fi

# 05.12e - Case-insensitive approval-word matching documented (v0.5.3+)
TOTAL=$((TOTAL+1))
if grep -qi "case.insensitive\|case insensitive" "$R/foundation/CLAUDE.md" 2>/dev/null \
   && grep -qi "case.insensitive\|case insensitive" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 05.12e Case-insensitive approval matching documented"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.12e Case-insensitive approval-word rule not documented"
  FAIL=$((FAIL+1))
  FAILURES+=("05.12e case-insensitive docs")
fi

# 05.12f - MOCKUPS/FRONTEND APPROVED clarification (v0.5.3+ - foundation gates count as UI)
TOTAL=$((TOTAL+1))
if grep -qi "scaffold\|chrome\|design system" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null \
   | head -5 >/dev/null && grep -qi "user-facing visual" "$R/.claude/skills/build-rules/SKILL.md" 2>/dev/null; then
  echo "  [PASS] 05.12f UI-gate definition includes scaffold/chrome"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.12f UI-gate definition not clarified"
  FAIL=$((FAIL+1))
  FAILURES+=("05.12f UI-gate clarification")
fi

# 05.13 - Plugin manifest is valid JSON
TOTAL=$((TOTAL+1))
PLUGIN="$R/.claude-plugin/plugin.json"
PLUGIN_FOR_PY="$PLUGIN"
if command -v cygpath >/dev/null 2>&1; then
  PLUGIN_FOR_PY=$(cygpath -w "$PLUGIN")
fi
if [[ -f "$PLUGIN" ]] && python3 -c "import json; json.load(open(r'$PLUGIN_FOR_PY'))" 2>/dev/null; then
  echo "  [PASS] 05.12 plugin.json is valid JSON"
  PASS=$((PASS+1))
else
  echo "  [FAIL] 05.12 plugin.json missing or invalid"
  FAIL=$((FAIL+1))
  FAILURES+=("05.12 plugin.json")
fi
