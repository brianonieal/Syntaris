# DEPLOYMENT_CONFIG.md
# Syntaris v0.6.0 | External Service Configuration Checklist
# Run this checklist before every production deployment
# Invoke: /deploy --configure
#
# STACK-SPECIFIC FILE
# This checklist is written for the Syntaris v0.6.0 stack: Next.js + FastAPI +
# Supabase + LangGraph + Plaid + Voyage AI, deploying to Vercel (frontend) and
# Render (backend). The Plaid, Voyage AI, and Sentry sections are specific to
# fintech projects. If you are on a different stack, copy this file into your
# project's foundation/ directory and edit the env vars and dashboard sections
# to match your services. The structure (env vars, dashboards, smoke tests,
# common failure modes) carries over even when the specific services do not.

---

## PURPOSE

Every production deploy requires external service configuration that Claude Code
cannot do autonomously. This file documents every step, every dashboard location,
and every common failure mode so configuration takes 15 minutes, not 2 hours.

---

## PRE-DEPLOY CHECKLIST

### GITHUB

- [ ] git config user.email matches your GitHub account primary email
- [ ] git config user.name matches your GitHub username
- [ ] commit-msg hook installed (run: bash ~/.claude/hooks/strip-coauthor.sh)
- [ ] Repo connected to Vercel (auto-deploy on push to main)
- [ ] Repo connected to Render (auto-deploy on push to main)

Verify:
```bash
git config user.email
git config user.name
cat .git/hooks/commit-msg | grep "Co-Authored-By"
```

### SUPABASE

Dashboard: supabase.com -> [Project] -> Project Settings -> API

- [ ] NEXT_PUBLIC_SUPABASE_URL copied (Project URL)
- [ ] NEXT_PUBLIC_SUPABASE_ANON_KEY copied (anon / public key)
- [ ] SUPABASE_SERVICE_ROLE_KEY copied (service_role secret - NEVER expose client-side)
- [ ] SUPABASE_JWT_SECRET copied (Settings -> API -> JWT Settings)
- [ ] DATABASE_URL copied and prefix changed (see note below)

DATABASE_URL note:
  Supabase gives you: postgres://postgres:[password]@[host]:5432/postgres
  For MVP (recommended): postgresql+asyncpg://postgres:[password]@[host]:5432/postgres
  Changes: postgres:// -> postgresql+asyncpg:// (keep port 5432 direct connection)

  For production with pooling (scale):
  postgresql+asyncpg://postgres:[password]@[host]:6543/postgres?pgbouncer=true
  PLUS: pass statement_cache_size=0 to create_async_engine:
    engine = create_async_engine(DATABASE_URL, echo=False,
                                 connect_args={"statement_cache_size": 0})
  WARNING: Port 6543 without statement_cache_size=0 causes
  DuplicatePreparedStatementError at startup. PgBouncer transaction mode
  breaks asyncpg's default prepared statements.

Auth configuration:
- [ ] Google OAuth enabled (Authentication -> Sign In / Providers -> Google)
  - [ ] Client ID from Google Cloud Console entered
  - [ ] Client Secret from Google Cloud Console entered
- [ ] Site URL set (Authentication -> URL Configuration)
  - Development: http://localhost:3000
  - Production: https://[your-vercel-domain].vercel.app
- [ ] Redirect URLs added:
  - http://localhost:3000/auth/callback
  - https://[your-vercel-domain].vercel.app/auth/callback

Email (for magic links):
- [ ] SMTP configured (Authentication -> SMTP Settings)
  - Recommended: Resend (resend.com - free tier, easy setup)
  - SMTP host: smtp.resend.com | Port: 465 | Username: resend

### GOOGLE CLOUD CONSOLE (for OAuth)

Dashboard: console.cloud.google.com -> APIs & Services -> Credentials

- [ ] Project created (name it after your app)
- [ ] OAuth 2.0 Client ID created (Web application type)
- [ ] Authorized JavaScript origins:
  - http://localhost:3000
  - https://[your-vercel-domain].vercel.app
- [ ] Authorized redirect URIs:
  - https://[project-id].supabase.co/auth/v1/callback
  - http://localhost:3000/auth/callback
  - https://[your-vercel-domain].vercel.app/auth/callback
- [ ] Client ID and Client Secret copied to Supabase Google provider

### VERCEL (Frontend)

Dashboard: vercel.com -> [Project] -> Settings -> Environment Variables

Required environment variables (4):
- [ ] NEXT_PUBLIC_SUPABASE_URL
- [ ] NEXT_PUBLIC_SUPABASE_ANON_KEY
- [ ] NEXT_PUBLIC_API_URL = https://[render-service-name].onrender.com
- [ ] NEXT_PUBLIC_SENTRY_DSN (from Sentry project)

Project settings:
- [ ] Framework Preset: Next.js (auto-detected)
- [ ] Root Directory: apps/web (for monorepo)
- [ ] Build Command: pnpm build
- [ ] Node.js Version: 20.x

### RENDER (Backend)

Dashboard: dashboard.render.com -> [Service] -> Environment

Required environment variables (13):
- [ ] DATABASE_URL (postgresql+asyncpg:// format, port 5432 for MVP, or 6543 with statement_cache_size=0 for scale - see DEC-003)
- [ ] SUPABASE_URL
- [ ] SUPABASE_SERVICE_ROLE_KEY
- [ ] SUPABASE_JWT_SECRET
- [ ] CORS_ORIGINS = ["https://[vercel-domain].vercel.app","http://localhost:3000"]
- [ ] ANTHROPIC_API_KEY
- [ ] PLAID_CLIENT_ID
- [ ] PLAID_SECRET
- [ ] PLAID_ENV = sandbox (development) | production (v5.0.0+)
- [ ] PLAID_WEBHOOK_URL = https://[render-url].onrender.com/api/plaid/webhook
- [ ] VOYAGE_API_KEY
- [ ] SENTRY_DSN
- [ ] DEBUG = false
- [ ] PYTHON_VERSION = 3.11

Service settings:
- [ ] Runtime: Python 3
- [ ] Root Directory: apps/api
- [ ] Build Command: pip install -r requirements.txt
- [ ] Start Command: uvicorn app.main:app --host 0.0.0.0 --port $PORT
- [ ] Auto-Deploy: Yes (from GitHub main)

### PLAID

Dashboard: dashboard.plaid.com -> Team Settings -> Keys

- [ ] PLAID_CLIENT_ID copied
- [ ] PLAID_SECRET copied (use Sandbox secret for development)
- [ ] Webhook URL registered in Plaid dashboard
- [ ] Products enabled: transactions, auth

### VOYAGE AI

Dashboard: dash.voyageai.com -> API Keys

- [ ] VOYAGE_API_KEY created and copied
- [ ] Model to use: voyage-finance-2 (for fintech) or voyage-3 (general)

### SENTRY

Dashboard: sentry.io -> New Project

Create TWO projects:
- [ ] Frontend project (Next.js) -> copy DSN -> NEXT_PUBLIC_SENTRY_DSN for Vercel
- [ ] Backend project (FastAPI) -> copy DSN -> SENTRY_DSN for Render

### STRIPE (v5.0.0+ only)

Dashboard: dashboard.stripe.com -> Developers -> API Keys

- [ ] STRIPE_SECRET_KEY copied
- [ ] STRIPE_WEBHOOK_SECRET copied
- [ ] Webhook endpoint registered: https://[render-url].onrender.com/api/webhooks/stripe
- [ ] Webhook events enabled: checkout.session.completed, customer.subscription.updated,
      customer.subscription.deleted, invoice.payment_failed

---

## COMMON FAILURE MODES

| Failure | Symptom | Fix |
|---------|---------|-----|
| Co-Authored-By blocks Vercel | "GitHub could not associate committer" | Run strip-coauthor.sh hook |
| DATABASE_URL wrong prefix | SQLAlchemy connection error on startup | Change postgres:// to postgresql+asyncpg://; use port 5432 for MVP, or port 6543 with statement_cache_size=0 for scale (see DEC-003 and EXAMPLES.md connect_args) |
| NEXT_PUBLIC_API_URL = localhost | Frontend loads, API calls fail in production | Update to real Render URL after backend deploys |
| Google OAuth redirect mismatch | OAuth error after login | Add all three redirect URIs to Google Cloud Console |
| Render port conflict | Service fails health check | Use $PORT not a hardcoded port in start command |
| Missing jose module | ModuleNotFoundError on Render startup | Add python-jose[cryptography] to requirements.txt |
| CORS_ORIGINS wrong format | FastAPI rejects frontend requests | Must be JSON array: ["https://domain.vercel.app"] |

---

## STATIC VALUES (type these exactly)

```
PLAID_ENV:        sandbox
DEBUG:            false
PYTHON_VERSION:   3.11
```
