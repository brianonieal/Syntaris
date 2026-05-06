# TEAM.md
# Syntaris v0.3.0 | Multi-Developer Collaboration Layer
# OPTIONAL - activate only on multi-developer projects
# Solo projects do not use this file

---

## ACTIVATION

This file is inactive by default.
Activate by adding to CONTRACT.md: TEAM_MODE = true

Solo projects (personal apps, single-client work): TEAM_MODE = false
Multi-developer projects: TEAM_MODE = true

---

## ONBOARDING A SECOND DEVELOPER

When a second developer joins a Syntaris project:

### Step 1: Share access

- [ ] Add developer as collaborator on GitHub repo
- [ ] Share Supabase project access (Dashboard -> Project Settings -> Members)
- [ ] Share .env.local file securely (NOT via git - use 1Password or similar)
- [ ] Share DEPLOYMENT_CONFIG.md so they can configure locally

### Step 2: Brief them on foundation files

Send them ONBOARDING.md and WHY.md from the Syntaris docs.
Have them read CONTRACT.md and VERSION_ROADMAP.md for this project.
Have them read DECISIONS.md to understand locked decisions.

Key message: DECISIONS.md entries marked LOCKED cannot be changed without
both developers agreeing and creating a new DEC-NNN entry that supersedes it.

### Step 3: Assign ownership

Update COMPONENT_REGISTRY.md - every component gets an owner field.
Update DECISIONS.md - every future decision gets an owner field.
Owner = the developer responsible for that component/decision.

---

## GIT WORKFLOW (multi-developer)

### Branch strategy

main: production only - never commit directly
develop: integration branch - both developers merge here
feature/[dev-name]/[feature]: individual feature branches

```bash
# Developer workflow
git checkout develop
git pull origin develop
git checkout -b feature/dev-a/oracle-streaming
# ... build the feature ...
git push origin feature/dev-a/oracle-streaming
# Open PR -> develop
```

### Pull request requirements

- [ ] All tests passing on the PR branch
- [ ] No TypeScript errors
- [ ] No ruff errors (Python)
- [ ] At least one approval from the other developer
- [ ] Co-Authored-By hook strips Anthropic trailer automatically

### Claude Code on team projects

Each developer runs their own Claude Code session on their own branch.
Claude Code never commits directly to main or develop.
All Claude Code work goes through the normal PR review process.

---

## DECISIONS ON TEAM PROJECTS

All architectural decisions require both developers to confirm.

DECISIONS.md entry format on team projects:
```markdown
## DEC-[NNN] - [Decision title]
Date: [date]
Gate: [vX.X.X]
Owner: [lead developer or other developer]
Proposed by: [who suggested it]
Approved by: [{{OWNER_NAME}}] + [other developer]
Decision: [what was decided]
Reason: [why]
Status: LOCKED
```

No decision gets LOCKED status without both developer names in Approved by.

---

## COMPONENT OWNERSHIP

COMPONENT_REGISTRY.md adds owner and contact fields:

```markdown
| Component | Owner | File | Status | Visual Verified | Notes |
|-----------|-------|------|--------|----------------|-------|
| [Component] | [Owner] | [file path] | [gate] | [status] | [verified] |
| MetricCard | [Developer 2] | components/dashboard/MetricCard.tsx | COMPLETE | YES | |
```

Rule: only the owner modifies a component without discussion.
Cross-owner changes require a comment in the PR explaining why.

---

## CONFLICT RESOLUTION

If two developers disagree on a technical decision:
1. Each writes their case in DECISIONS.md as a PROPOSED entry
2. Both read each other's case
3. Try to reach agreement
4. If no agreement: the project lead has final say

DECISIONS.md is the court of record. No Slack arguments, no verbal agreements.
If it's not in DECISIONS.md, it didn't happen.
