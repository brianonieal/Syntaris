# DEPLOYMENT.md - Next.js + Supabase on Vercel

## PRE-DEPLOY
- [ ] All tests pass
- [ ] Environment variables set on Vercel: NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY (server only)
- [ ] Supabase migrations applied
- [ ] RLS policies verified for tables holding user data

## DEPLOY
```bash
git push origin main  # Vercel auto-deploys
```

## POST-DEPLOY
- [ ] Health check: home page loads
- [ ] Auth flow: sign-up + sign-in works
- [ ] Critical user path: smoke test
