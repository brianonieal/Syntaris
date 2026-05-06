# EXAMPLES.md - Next.js + Supabase patterns

## PATTERN 1: Server Component data fetch with Supabase

```tsx
import { createClient } from "@/lib/supabase/server";

export default async function Page() {
  const supabase = createClient();
  const { data, error } = await supabase.from("posts").select("*");
  if (error) throw error;
  return <ul>{data.map((p) => <li key={p.id}>{p.title}</li>)}</ul>;
}
```

## PATTERN 2: Client Component with auth

```tsx
"use client";
import { createClient } from "@/lib/supabase/client";

export function SignOutButton() {
  const supabase = createClient();
  return <button onClick={() => supabase.auth.signOut()}>Sign out</button>;
}
```

## PATTERN 3: API route with auth check

```ts
import { createClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response("Unauthorized", { status: 401 });
  return Response.json({ hello: user.email });
}
```
