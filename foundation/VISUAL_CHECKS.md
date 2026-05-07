# VISUAL_CHECKS.md
# Syntaris v0.6.0 | Visual Verification at Gate Close
# Playwright screenshots compared against MOCKUPS.md spec

---

## PURPOSE

MOCKUPS.md is approved before any code is written.
FRONTEND_SPEC.md documents every component's expected behavior.
But without visual verification, drift between spec and implementation
is only caught when the user manually looks at the browser.

Visual checks catch drift at gate close, not in the browser.

---

## WHEN TO RUN

Auto-trigger at every gate close where at least one screen was built.
Skip (with warning) if dev server is not running.
Run manually: /visual-checks

---

## PROTOCOL

### Step 1: Verify dev server is running

```bash
curl -s http://localhost:3000 > /dev/null && echo "RUNNING" || echo "OFFLINE"
```

If OFFLINE:
  Print: "Visual verification skipped - dev server not running.
          Start server and run /visual-checks manually before typing GO."
  Do NOT block gate close. Log skip in VISUAL_CHECKS.md.

### Step 2: Take screenshots via Playwright MCP

For each screen built in this gate, capture:

```javascript
// Pattern for each screen
await page.goto('http://localhost:3000/[route]');
await page.waitForLoadState('networkidle');
await page.screenshot({
  path: 'mockups/screenshots/v[X.X.X]/[screen-name].png',
  fullPage: true
});
```

Store at: /mockups/screenshots/v[X.X.X]/[screen-name].png

### Step 3: Compare against MOCKUPS.md spec

For each screenshot, Claude Code reads the corresponding MOCKUPS.md entry
and checks for drift on these specific elements:

ALWAYS CHECK:
- [ ] Page loads without errors (no error state showing)
- [ ] Navigation sidebar present and correct route highlighted (desktop)
- [ ] Mobile bottom tab bar present on screens below 768px
- [ ] Loading skeleton matches spec (no spinners on initial load)
- [ ] Empty states match spec text exactly

CHECK FOR DOMAIN-SPECIFIC RULES (configure in CONTRACT.md):
- [ ] Domain-specific formatting rules are met (per DESIGN_SYSTEM.md)
- [ ] Semantic color tokens match DESIGN_SYSTEM.md (positive/negative states)
- [ ] Typography tokens match DESIGN_SYSTEM.md (monospace where required)
- [ ] All required data display rules from CONTRACT.md are followed

CHECK FOR AUTH SCREENS:
- [ ] Login button present in top-right of landing page
- [ ] Auth modal overlays page (not navigates away)
- [ ] Test credentials visible in small gray text

### Step 4: Flag findings

PASS: Screenshot matches spec. Log in VISUAL_CHECKS.md.
DRIFT: Screenshot differs from spec. Log finding, Claude Code fixes autonomously if straightforward.
REVIEW: Screenshot differs and fix is ambiguous. Flag for the user's review before GO.

---

## VISUAL_CHECKS.MD FORMAT

```markdown
# VISUAL CHECKS LOG
# Syntaris

## v[X.X.X] - [Gate Name] - [date]

### [Screen Name] (/route)
Screenshot: /mockups/screenshots/v[X.X.X]/[screen].png
Status: PASS | DRIFT | REVIEW | SKIPPED

Findings:
  - [PASS] Navigation sidebar present, /dashboard active
  - [DRIFT] Login button missing from landing page nav - fixed autonomously
  - [REVIEW] Color on delta differs from spec - needs user review

### SKIPPED GATES
| Gate | Reason | Manual Check Done? |
|------|--------|-------------------|
| v0.1.0 | Dev server offline | YES - User confirmed 2026-04-09 |
```

---

## SCREENSHOT STORAGE

```
/mockups/
  screenshots/
    v0.3.0/
      auth-login.png
      settings-profile.png
    v0.5.0/
      dashboard-desktop.png
      dashboard-mobile.png
      transactions.png
      oracle-chat.png
    v0.6.0/
      budgets.png
      goals.png
```

Screenshots committed to git. They serve as the visual regression baseline
for future gates - if a later gate breaks a prior screen, the diff is visible.

---

## DRIFT SEVERITY

CRITICAL: App is broken or unusable (wrong route, error state showing, blank page)
HIGH: Key feature invisible or wrong (missing login button, wrong colors on money)
MEDIUM: Layout differs from spec but functional (spacing, sizing)
LOW: Minor cosmetic difference (font weight, border radius)

Claude Code autonomously fixes CRITICAL and HIGH.
MEDIUM and LOW: log and flag for next session.
