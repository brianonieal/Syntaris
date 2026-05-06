# COMPONENT_REGISTRY.md
# Syntaris v0.3.0 | Component Registry
# Every UI component is registered here when built.
# Source of truth for what exists, who owns it, and whether it's been visually verified.

---

## HOW TO USE

When a component is built:
1. Add a row to the registry immediately
2. Fill in: name, owner, file path, gate, status
3. After visual verification (/visual-checks): mark VERIFIED = YES

When modifying an existing component:
1. Check the registry to find the file path
2. If TEAM_MODE=true: check the owner - coordinate if you're not the owner
3. After modification: mark VERIFIED = NEEDS RE-VERIFY

---

## GLOBAL COMPONENTS

| Component | Owner | File | Test File | Gate | Status | Verified | Screenshot |
|-----------|-------|------|-----------|------|--------|----------|------------|

## SCREEN COMPONENTS

| Component | Owner | File | Test File | Gate | Status | Verified | Screenshot |
|-----------|-------|------|-----------|------|--------|----------|------------|

## STATUS VALUES

PLANNED - in VERSION_ROADMAP.md, not yet built
IN_PROGRESS - actively being built this gate
COMPLETE - built and passing tests
NEEDS_REVIEW - built but has open questions
DEPRECATED - replaced by another component

## VERIFIED VALUES

YES - Playwright screenshot taken, matches MOCKUPS.md spec
NO - not yet verified (pre-visual-checks)
NEEDS_RE_VERIFY - modified since last verification
SKIPPED - dev server was offline at gate close (manual check required)

## SCREENSHOT PATH FORMAT

/mockups/screenshots/v[X.X.X]/[component-name].png

Example:
/mockups/screenshots/v0.5.0/dashboard-desktop.png
/mockups/screenshots/v0.5.0/dashboard-mobile.png
/mockups/screenshots/v0.6.0/budgets.png
