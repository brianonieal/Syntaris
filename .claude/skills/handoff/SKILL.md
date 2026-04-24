---
name: handoff
description: "This skill generates client handoff documents when a project reaches v1.0.0. Use at v1.0.0 gate close, when completing a project, or when the user types /handoff. Produces client PDF, technical PDF, and handoff email."
---

# HANDOFF SKILL -- Blueprint v11
# Invoke: /handoff (auto-triggered at v1.0.0 gate close)

## DELIVERABLE 1: CLIENT HANDOFF (non-technical)

1. What was built (plain English)
2. How to access it (URLs, login instructions)
3. What is included (feature list)
4. What is NOT included (future versions, scoped)
5. How to request changes (contact, rate, process)
6. Your data (where stored, who has access, how to export)

## DELIVERABLE 2: TECHNICAL HANDOFF (for future developers)

1. Architecture overview (stack, why each choice)
2. Repository structure
3. Environment setup (how to run locally, all env vars)
4. Database schema (tables, relationships, RLS policies)
5. API reference (all endpoints, auth requirements)
6. Agent architecture (if applicable)
7. Known issues (from ERRORS.md)
8. Decisions log (from DECISIONS.md)
9. How to deploy (from DEPLOYMENT.md)
10. Test suite (how to run, what is covered)

## DELIVERABLE 3: HANDOFF EMAIL DRAFT

Subject: [Project Name] v1.0.0 -- Delivered

Brief email with: what was built, link, next steps, invoice reference.
All pulled from foundation files automatically.
