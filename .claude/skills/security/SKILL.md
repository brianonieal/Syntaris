---
name: security
description: "This skill runs security audits at gate close and before production deployments. Use when checking for vulnerabilities, before deploying, or when the user types /security. Covers OWASP Top 10 and AI-specific threats."
---

# SECURITY SKILL - Syntaris v0.5.3
# Invoke: /security or auto-triggered pre-deploy

## WHEN TO RUN

- Lightweight check: every gate close
- Full audit: before every production deploy (mandatory)
- On demand: /security

## LIGHTWEIGHT GATE CLOSE CHECK

```bash
# Check for hardcoded secrets
grep -r "sk-" apps/ --include="*.ts" --include="*.py" | grep -v ".env" | grep -v "test"
grep -r "password\s*=\s*['\"]" apps/ --include="*.py"

# Check for SQL injection patterns
grep -r "f\"SELECT\|f'SELECT\|format.*SELECT" apps/api/ --include="*.py"
```

## FULL PRE-DEPLOY AUDIT (OWASP Top 10)

A01 Broken Access Control:
  - [ ] All routes have auth dependency
  - [ ] RLS enabled on all user-specific tables
  - [ ] No user can access another user's data (RLS isolation test)

A02 Cryptographic Failures:
  - [ ] No secrets in code, git history, or logs
  - [ ] JWT secret is minimum 32 characters
  - [ ] HTTPS enforced

A03 Injection:
  - [ ] All queries use ORM (no raw SQL with f-strings)
  - [ ] All user inputs validated via Pydantic v2
  - [ ] No eval(), exec(), or subprocess with user input

A05 Security Misconfiguration:
  - [ ] DEBUG=false in production
  - [ ] CORS_ORIGINS lists only known domains (no wildcard *)

A07 Auth Failures:
  - [ ] JWT verification on all protected endpoints
  - [ ] Token expiry handled gracefully

AI-Specific:
  - [ ] Cost ceiling enforced per user
  - [ ] Query count tracked and limited
  - [ ] Prompt injection mitigated (user input never directly in system prompt)
  - [ ] Agent log captures all invocations for audit

## AUTO-FIXES

CRITICAL and HIGH: Claude Code fixes autonomously.
MEDIUM: fix before next gate.
LOW: document, address later.
