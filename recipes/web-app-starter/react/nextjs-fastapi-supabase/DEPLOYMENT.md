# DEPLOYMENT.md - Next.js + FastAPI + Supabase

## PRE-DEPLOY
- [ ] All tests pass (frontend AND backend)
- [ ] Vercel env vars: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_API_URL
- [ ] Render env vars: SUPABASE_SERVICE_ROLE_KEY, DATABASE_URL, OPENAI_API_KEY (or equivalent)
- [ ] Supabase migrations applied
- [ ] CORS configured: FastAPI allows requests from Vercel deployment URL

## DEPLOY
Frontend: `git push origin main` (Vercel auto-deploys)
Backend: `git push origin main` (Render auto-deploys, or manual `render deploy`)

## POST-DEPLOY
- [ ] Frontend home page loads
- [ ] FastAPI health endpoint returns 200: `GET /health`
- [ ] Auth flow: sign-up + sign-in works
- [ ] Smoke test: critical user path works end-to-end (frontend -> backend -> DB)
