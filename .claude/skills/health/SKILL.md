---
name: health
description: "This skill audits Blueprint v11 installation and project foundation files. Use when checking system integrity, after long breaks from a project, or when the user types /health."
---

# HEALTH SKILL -- Blueprint v11
# Invoke: /health

## STEP 1: MEMORY NETWORK AUDIT

| File | Check |
|------|-------|
| MEMORY_SEMANTIC.md | Exists, has patterns, none over 90 days stale |
| MEMORY_EPISODIC.md | Exists, last gate outcome logged, no unclosed STOP EVENTs |
| MEMORY_CORRECTIONS.md | Exists, reflexion entries present after gate 3+ |

## STEP 2: FOUNDATION FILE AUDIT

ALWAYS LOAD (5): CLAUDE.md, CONTRACT.md, SPEC.md, ERRORS.md, MEMORY_SEMANTIC.md
ON DEMAND (17+): VERSION_ROADMAP.md, PLANS.md, DECISIONS.md, FRONTEND_SPEC.md,
DESIGN_SYSTEM.md, COMPONENT_REGISTRY.md, TESTS.md, COSTS.md, SECURITY.md,
PERFORMANCE.md, DEPLOYMENT.md, DEPLOYMENT_CONFIG.md, CONTEXT_BUDGET.md,
VISUAL_CHECKS.md, CHANGELOG.md, TIMELOG.md, RESEARCH.md

Report: [X] foundation files present. Missing files at pre-v0.0.0: expected.

## STEP 3: HOOK INSTALLATION AUDIT

```bash
ls .git/hooks/commit-msg 2>/dev/null && echo "INSTALLED" || echo "MISSING"
grep -q "Co-Authored-By" .git/hooks/commit-msg && echo "CORRECT" || echo "WRONG"
```

## STEP 4: PATTERN QUALITY CHECK

Review MEMORY_SEMANTIC.md: flag stale, contradicted, or stuck patterns.

## STEP 5: RESEARCH STALENESS

Check RESEARCH.md last updated date. Flag if over 90 days.

## OUTPUT FORMAT

```
HEALTH CHECK -- [Project Name]
Memory Network:     [3/3] or [X/3]
Foundation Files:   [X present]
Hook Installation:  PASS or FAIL
Pattern Quality:    [N stale] [N contradicted]
Research Staleness: CURRENT or STALE
```
