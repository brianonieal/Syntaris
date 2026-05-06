# EXAMPLES.md - Next.js + FastAPI + Supabase patterns

## PATTERN 1: FastAPI endpoint with Pydantic validation

```python
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from app.auth import get_current_user

router = APIRouter()

class CreatePostRequest(BaseModel):
    title: str
    body: str

class CreatePostResponse(BaseModel):
    id: int
    title: str

@router.post("/posts", response_model=CreatePostResponse)
async def create_post(
    request: CreatePostRequest,
    user_id: int = Depends(get_current_user),
):
    # Implementation here
    ...
```

## PATTERN 2: Frontend fetch with typed response

```ts
import { z } from "zod";

const PostSchema = z.object({
  id: z.number(),
  title: z.string(),
});

export async function createPost(title: string, body: string) {
  const res = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/posts`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title, body }),
  });
  if (!res.ok) throw new Error(`HTTP ${res.status}`);
  return PostSchema.parse(await res.json());
}
```

## PATTERN 3: LangGraph agent state schema (lock before gate close)

```python
from typing import TypedDict, Annotated
from langgraph.graph.message import add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    user_id: int
    intermediate_results: dict
    completed: bool
```
