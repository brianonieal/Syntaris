---
name: performance
description: "This skill audits frontend load speed, backend response time, and database query performance. Use before production deployments, at gate close, or when the user types /performance."
---

# PERFORMANCE SKILL -- Blueprint v11
# Invoke: /performance or auto-triggered pre-deploy

## TARGETS

Frontend (Lighthouse): Performance 90+, Accessibility 95+, Best Practices 95+
Backend: P50 < 200ms (non-AI), P95 < 500ms, AI endpoints < 3s to first token
Database: No query over 100ms, all FKs indexed, vector index on embedding columns

## LIGHTWEIGHT GATE CLOSE CHECK

Add response time assertions to test suite for new endpoints.

## FULL PRE-DEPLOY AUDIT

```bash
# Frontend Lighthouse
npx lighthouse http://localhost:3000 --output=json --quiet

# Database slow query check
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## AUTO-FIXES

CRITICAL (blocks deploy): N+1 queries, missing indexes on FK columns
HIGH: queries over 500ms, Lighthouse below 80
MEDIUM: queries 100-500ms, Lighthouse 80-90
