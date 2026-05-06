# DEPLOYMENT.md
# Stack-specific deployment checklist.
# Run the pre-deploy section before every production deploy.

## PRE-DEPLOY

- [ ] All tests pass locally
- [ ] All tests pass in CI
- [ ] Environment variables set on platform
- [ ] Database migrations applied (if any)
- [ ] Sensitive secrets rotated if exposed in this gate
- [ ] [Add stack-specific checks]

## DEPLOY

Frontend:
```bash
[deploy command]
```

Backend:
```bash
[deploy command]
```

Database migrations:
```bash
[migration command]
```

## POST-DEPLOY

- [ ] Health check: `[endpoint]` returns 200
- [ ] Smoke test: critical user path works
- [ ] Monitor error rate for 15 minutes
- [ ] Update DEPLOYMENT.md (foundation file) with deploy log

## ROLLBACK

If any check fails, immediate rollback:
```bash
[rollback command]
```

Document the failure in ERRORS.md before retrying.
