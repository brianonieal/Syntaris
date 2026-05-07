---
name: deployment
description: "This skill manages production deployments with pre-deploy gates, health checks, and rollback protocols. Use when deploying, configuring CI/CD, or when the user types /deploy."
---

# DEPLOYMENT SKILL - Syntaris v0.5.2
# Invoke: /deploy

## PRE-DEPLOY GATES (all must pass)

1. /security full audit - zero CRITICAL or HIGH findings
2. /performance audit - target scores met
3. All tests passing (zero failures)
4. DEPLOYMENT_CONFIG.md checklist complete
5. User types: DEPLOY APPROVED

## DEPLOYMENT SEQUENCE

Step 1: Verify deployment config (render.yaml or equivalent)
Step 2: Run /deploy --configure (walks through DEPLOYMENT_CONFIG.md checklist)
Step 3: Push to main (triggers auto-deploy on connected platforms)
Step 4: Health checks (curl endpoints)
Step 5: Smoke tests (auth flow, core feature, error state)
Step 6: Log deployment to DEPLOYMENT.md

## ROLLBACK PROTOCOL

If production deploy fails health checks:
1. Rollback via hosting platform dashboard
2. Log incident in DEPLOYMENT.md
3. Root cause in ERRORS.md
