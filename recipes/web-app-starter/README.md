# Recipe: web-app-starter

Stack-flexible recipe for building web applications. Selects a sub-recipe based on the user's frontend framework choice during `/start`.

## Sub-recipes

| Sub-recipe | Stack | Status |
|------------|-------|--------|
| `react/nextjs-supabase` | Next.js 14+ with Supabase backend | Populated |
| `react/nextjs-fastapi-supabase` | Next.js + FastAPI + Supabase + LangGraph (Brian's reference stack) | Populated |
| `react/vite-express` | Vite + Express + Postgres | Populated |
| `vue` | Vue 3 + Pinia + (TBD backend) | Stub (BUILD_NEXT.md) |
| `svelte` | SvelteKit + (TBD backend) | Stub (BUILD_NEXT.md) |
| `plain` | Plain HTML/CSS/JS, no framework | Stub (BUILD_NEXT.md) |

## How sub-recipes are picked

`/start` asks "Web app - frontend framework?" and routes to the matching sub-recipe directory. If the framework has multiple stack options (like React's three), it asks one more question to narrow. If the framework has only one stack option (Vue, Svelte), it loads directly.

## Why React has three sub-recipes

React is Syntaris's most-tested ecosystem because Brian's reference projects (Forge Finance, EOM-AI, Feast-AI) are built on it. The three React sub-recipes reflect three valid stacks with different complexity tradeoffs:

- `nextjs-supabase` - simplest full-stack React. Auth and DB handled by Supabase, no custom backend.
- `nextjs-fastapi-supabase` - Brian's reference stack. Use when you need Python backend logic (LangGraph agents, ML, complex data work).
- `vite-express` - when you want full control over both ends.

If you're not sure, pick `nextjs-supabase` first. You can always graduate to a more complex stack later.
