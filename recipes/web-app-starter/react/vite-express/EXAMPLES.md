# EXAMPLES.md - Vite + Express patterns

## PATTERN 1: Express endpoint with Zod validation

```ts
import express from "express";
import { z } from "zod";

const CreatePostSchema = z.object({
  title: z.string().min(1).max(200),
  body: z.string().max(10000),
});

const app = express();
app.use(express.json());

app.post("/posts", async (req, res) => {
  const parsed = CreatePostSchema.safeParse(req.body);
  if (!parsed.success) return res.status(400).json({ errors: parsed.error.errors });
  // Implementation
  res.json({ id: 1, ...parsed.data });
});
```

## PATTERN 2: React Query data fetch

```tsx
import { useQuery } from "@tanstack/react-query";

export function PostList() {
  const { data, isLoading } = useQuery({
    queryKey: ["posts"],
    queryFn: () => fetch("/api/posts").then((r) => r.json()),
  });
  if (isLoading) return <p>Loading...</p>;
  return <ul>{data.map((p: { id: number; title: string }) => <li key={p.id}>{p.title}</li>)}</ul>;
}
```
