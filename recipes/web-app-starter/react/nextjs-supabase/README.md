# Sub-recipe: react/nextjs-supabase

Simplest full-stack React. Next.js 14+ App Router with Supabase as the backend (auth, database, storage). No custom Python or Node backend.

## When to use

- A solo or small-team app where Supabase's built-in features suffice
- AI-light apps (call OpenAI/Anthropic directly from Next.js routes)
- MVPs that need to ship in 1-3 weeks

## When NOT to use

- Complex multi-agent AI orchestration (use `nextjs-fastapi-supabase`)
- Need to run heavy Python/ML libraries server-side
- Microservices or multi-backend architecture (use a different recipe)
