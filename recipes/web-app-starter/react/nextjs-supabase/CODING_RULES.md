# CODING_RULES.md - Next.js + Supabase

## LANGUAGE
- TypeScript strict mode, no `any`
- Use `unknown` and narrow with type guards

## NEXT.JS
- App Router only (no Pages Router for new code)
- Server Components by default; mark Client Components explicitly with `"use client"`
- API routes in `/app/api/<route>/route.ts`
- Server actions for form submissions, not API routes when possible

## SUPABASE
- All DB access via Supabase client, no direct Postgres connections
- Row Level Security (RLS) enabled on every table that holds user data
- Auth flows via `@supabase/ssr` for server, `@supabase/supabase-js` for client

## TESTING
- Vitest for unit tests
- React Testing Library for components
- Playwright for E2E
- Coverage target: 80% on business logic
