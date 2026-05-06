# Sub-recipe: react/vite-express

Vite + Express + Postgres. Full control over both ends, lighter than Next.js + FastAPI, more flexible than Next.js + Supabase.

## When to use

- You want React without Next.js (no App Router, no Server Components)
- You want Express because it's simple and you know it
- You want a Postgres database without the Supabase ecosystem
- You're comfortable wiring auth and storage manually

## When NOT to use

- You want Server Components or React Server Actions (use Next.js variants)
- You don't want to wire your own auth (use Supabase variants)
