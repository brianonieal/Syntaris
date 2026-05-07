# EXAMPLES.md
# Syntaris v0.5.3 | Real Code Patterns
# Stack: Next.js 14+ App Router, FastAPI Python 3.11, Supabase, LangGraph, LiteLLM, Voyage AI
#
# STACK-SPECIFIC FILE
# Syntaris v0.5.3 ships opinionated for the stack listed above. The patterns
# here use Plaid, Voyage AI's voyage-finance-2 model, and other fintech-flavored
# examples drawn from the production build (Forge Finance) that produced the
# methodology's calibration data. If you are on a different stack, treat this
# file as a worked example of the patterns Syntaris expects (auth, DB sessions,
# vector search, agent state) rather than as a literal blueprint. Stack-specific
# recipes for other stacks are in the recipes/ directory as of v0.3.0.

---

## FASTAPI: AUTHENTICATED ENDPOINT PATTERN

```python
# apps/api/app/routers/transactions.py
from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.auth import get_current_user_id
from app.database import get_db
from app.models import Transaction
from app.schemas import TransactionResponse
from sqlalchemy import select

router = APIRouter(prefix="/api/transactions", tags=["transactions"])

@router.get("/", response_model=list[TransactionResponse])
async def get_transactions(
    limit: int = Query(default=50, le=200),
    cursor: str | None = None,
    user_id: str = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    query = (
        select(Transaction)
        .where(Transaction.user_id == user_id)
        .order_by(Transaction.date.desc())
        .limit(limit)
    )
    result = await db.execute(query)
    return result.scalars().all()
```

## FASTAPI: AUTH DEPENDENCY

```python
# apps/api/app/core/auth.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
import os

security = HTTPBearer()

async def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> str:
    token = credentials.credentials
    try:
        payload = jwt.decode(
            token,
            os.environ["SUPABASE_JWT_SECRET"],
            algorithms=["HS256"],
            audience="authenticated",
        )
        user_id: str = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
        return user_id
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

## SQLALCHEMY: ASYNC SESSION PATTERN

```python
# apps/api/app/database.py
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
import os

DATABASE_URL = os.environ["DATABASE_URL"]
# MVP: postgresql+asyncpg://[user]:[pass]@[host]:5432/[db]
# Scale: postgresql+asyncpg://[user]:[pass]@[host]:6543/[db]?pgbouncer=true
# If using port 6543, statement_cache_size=0 is REQUIRED (see connect_args below)

engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    # Required when using Supabase pooler (port 6543) to prevent
    # DuplicatePreparedStatementError. Safe to include on port 5432 too.
    connect_args={"statement_cache_size": 0},
)
AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
```

## SQLALCHEMY: MODEL WITH RLS PATTERN

```python
# apps/api/app/models/transaction.py
from sqlalchemy import Column, String, Numeric, Date, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, ARRAY
from pgvector.sqlalchemy import Vector
from app.database import Base
import uuid

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    account_id = Column(UUID(as_uuid=True), ForeignKey("accounts.id"), nullable=False)
    plaid_transaction_id = Column(String(255), unique=True)
    amount = Column(Numeric(12, 2), nullable=False)
    date = Column(Date, nullable=False)
    merchant_name = Column(String(255))
    category = Column(ARRAY(String))
    embedding = Column(Vector(1024))  # Voyage AI voyage-finance-2
```

## LANGGRAPH: SIMPLE AGENT PATTERN

```python
# apps/api/app/agents/oracle.py
from langgraph.graph import StateGraph, END
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from typing import TypedDict
import litellm
import os

class OracleState(TypedDict):
    user_id: str
    query: str
    query_type: str
    context: str
    response: str
    cost_usd: float

async def classify(state: OracleState) -> dict:
    """Haiku classifies query complexity. Cheap."""
    response = await litellm.acompletion(
        model="claude-haiku-4-5",
        messages=[{"role": "user", "content": f"Is this query simple or complex? Query: {state['query']}. Answer: simple or complex"}],
        max_tokens=10,
    )
    return {"query_type": response.choices[0].message.content.strip()}

async def retrieve_context(state: OracleState) -> dict:
    """Voyage AI semantic search on user's data."""
    # See Voyage AI pattern below for full implementation
    return {"context": "retrieved context here"}

async def respond(state: OracleState) -> dict:
    """Sonnet reasons over context. Only runs when needed."""
    response = await litellm.acompletion(
        model="claude-sonnet-4-6",
        messages=[
            {"role": "system", "content": "You are a helpful AI assistant."},
            {"role": "user", "content": f"Context: {state['context']}\n\nQuestion: {state['query']}"}
        ],
        max_tokens=500,
    )
    return {"response": response.choices[0].message.content}

# REQUIRED: checkpointer for crash recovery, session memory, and HITL
# NOTE: AsyncPostgresSaver uses psycopg (Psycopg 3) internally, NOT asyncpg.
# It accepts a plain postgresql:// connection string, not postgresql+asyncpg://.
# Use a separate env var or strip the +asyncpg prefix for the checkpointer URL.
CHECKPOINT_URL = os.environ.get("DATABASE_URL_SYNC", os.environ["DATABASE_URL"].replace("+asyncpg", ""))

# AsyncPostgresSaver.from_conn_string() returns an async context manager.
# The checkpointer's connection closes when the `async with` block exits,
# so the compiled graph must be used INSIDE the block (or the context manager
# must be held open for the entire app lifecycle).
#
# Correct pattern for FastAPI: hold the context manager open across the app's
# lifespan using @asynccontextmanager. DO NOT return a compiled graph from a
# function that has already exited its `async with` block - the connection
# will be closed and ainvoke() will fail with "connection is closed".

def build_oracle_graph(checkpointer) -> StateGraph:
    """Build the graph structure. Pure function - no I/O."""
    graph_builder = StateGraph(OracleState)
    graph_builder.add_node("classify", classify)
    graph_builder.add_node("retrieve", retrieve_context)
    graph_builder.add_node("respond", respond)
    graph_builder.set_entry_point("classify")
    graph_builder.add_edge("classify", "retrieve")
    graph_builder.add_edge("retrieve", "respond")
    graph_builder.add_edge("respond", END)
    return graph_builder.compile(checkpointer=checkpointer)

# FastAPI lifespan integration (apps/api/app/main.py):
#
# from contextlib import asynccontextmanager
# from fastapi import FastAPI
#
# @asynccontextmanager
# async def lifespan(app: FastAPI):
#     async with AsyncPostgresSaver.from_conn_string(CHECKPOINT_URL) as checkpointer:
#         await checkpointer.setup()  # Creates checkpoint tables on first run
#         app.state.oracle = build_oracle_graph(checkpointer)
#         yield
#     # Context manager exits here when app shuts down; connection closed cleanly.
#
# app = FastAPI(lifespan=lifespan)
#
# @app.post("/query")
# async def query(req: QueryRequest):
#     result = await app.state.oracle.ainvoke(
#         {"user_id": req.user_id, "query": req.query},
#         config={"configurable": {"thread_id": req.thread_id}}
#     )
#     return result
```

## VOYAGE AI: EMBEDDING PATTERN

```python
# apps/api/app/core/embeddings.py
import voyageai
import os

voyage = voyageai.AsyncClient(api_key=os.environ["VOYAGE_API_KEY"])

async def embed_transaction(text: str) -> list[float]:
    """Embed a transaction description for semantic search."""
    result = await voyage.embed(
        [text],
        model="voyage-finance-2",
        input_type="document",
    )
    return result.embeddings[0]

async def search_transactions(query: str, user_id: str, db) -> list:
    """Semantic search over user's transactions using pgvector."""
    from sqlalchemy import text

    query_embedding = await voyage.embed(
        [query],
        model="voyage-finance-2",
        input_type="query",
    )
    vector = query_embedding.embeddings[0]

    # pgvector cosine similarity search
    # Note: use <=> for cosine, NOT <-> (Euclidean)
    # Wrapped in sqlalchemy.text() per CLAUDE.md rule: no raw SQL
    result = await db.execute(
        text("""
            SELECT *, (embedding <=> :vector) as distance
            FROM transactions
            WHERE user_id = :user_id
            ORDER BY embedding <=> :vector
            LIMIT 20
        """),
        {"vector": str(vector), "user_id": str(user_id)}
    )
    return result.fetchall()
```

## NEXT.JS: TANSTACK QUERY PATTERN

```typescript
// apps/web/src/hooks/useTransactions.ts
import { useQuery } from '@tanstack/react-query'
import { api } from '@/lib/api'

export function useTransactions(period: string) {
  return useQuery({
    queryKey: ['transactions', period],
    queryFn: () => api.get(`/api/transactions?period=${period}`),
    staleTime: 1000 * 60 * 5, // 5 minutes
  })
}

// Period selector invalidates all queries with period in the key
// In PeriodSelector component:
const queryClient = useQueryClient()
const handlePeriodChange = (newPeriod: string) => {
  setPeriod(newPeriod)
  queryClient.invalidateQueries({ queryKey: ['transactions'] })
  queryClient.invalidateQueries({ queryKey: ['dashboard'] })
  queryClient.invalidateQueries({ queryKey: ['budgets'] })
}
```

## NEXT.JS: SUPABASE AUTH PATTERN

```typescript
// apps/web/src/lib/supabase.ts
import { createBrowserClient } from '@supabase/ssr'

export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!
  )
}

// apps/web/src/app/auth/callback/route.ts
import { createServerClient } from '@supabase/ssr'
import { cookies } from 'next/headers'
import { NextResponse } from 'next/server'

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url)
  const code = searchParams.get('code')

  if (code) {
    const cookieStore = await cookies()
    const supabase = createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!,
      {
        cookies: {
          getAll() {
            return cookieStore.getAll()
          },
          setAll(cookiesToSet) {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          },
        },
      }
    )
    await supabase.auth.exchangeCodeForSession(code)
  }
  return NextResponse.redirect(`${origin}/dashboard`)
}
```

## NEXT.JS: REUSABLE CARD COMPONENT (with design system tokens)

```typescript
// apps/web/src/components/MetricCard.tsx
interface MetricCardProps {
  label: string
  value: string
  delta?: string
  deltaType?: 'gain' | 'loss' | 'neutral'
  loading?: boolean
}

export function MetricCard({ label, value, delta, deltaType, loading }: MetricCardProps) {
  if (loading) {
    return (
      <div className="bg-bg-surface rounded-xl p-6 animate-pulse">
        <div className="h-4 bg-bg-elevated rounded w-24 mb-3" />
        <div className="h-8 bg-bg-elevated rounded w-40 mb-2" />
        <div className="h-4 bg-bg-elevated rounded w-20" />
      </div>
    )
  }

  return (
    <div className="bg-bg-surface rounded-xl p-6">
      <p className="text-sm text-text-secondary mb-1">{label}</p>
      {/* Apply typography tokens from DESIGN_SYSTEM.md */}
      <p className="text-3xl font-mono font-semibold text-text-primary">{value}</p>
      {delta && (
        <p className={`text-sm font-mono mt-1 ${
          deltaType === 'gain' ? 'text-semantic-positive' :
          deltaType === 'loss' ? 'text-semantic-negative' :
          'text-text-secondary'
        }`}>
          {deltaType === 'gain' ? '▲' : deltaType === 'loss' ? '▼' : ''}
          {' '}{delta}
        </p>
      )}
    </div>
  )
}
```

## ALEMBIC: NAMED MIGRATION PATTERN

```bash
# Generate named migration (NEVER use autogenerate without reviewing output)
alembic revision --autogenerate -m "add_transactions_table_and_indexes"

# Review EVERY line before running
cat alembic/versions/[timestamp]_add_transactions_table_and_indexes.py

# Run
alembic upgrade head
```

```python
# alembic/versions/20260409_001_add_transactions_table.py
"""add transactions table with pgvector embedding column

Revision ID: 20260409_001
"""
from alembic import op
import sqlalchemy as sa
from pgvector.sqlalchemy import Vector

def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    op.create_table(
        "transactions",
        sa.Column("id", sa.UUID(), primary_key=True),
        sa.Column("user_id", sa.UUID(), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("date", sa.Date(), nullable=False),
        sa.Column("embedding", Vector(1024)),
    )

    # Indexes
    op.create_index("ix_transactions_user_id", "transactions", ["user_id"])
    op.create_index("ix_transactions_date", "transactions", ["date"])
    # pgvector index for semantic search
    op.execute("""
        CREATE INDEX ix_transactions_embedding
        ON transactions USING ivfflat (embedding vector_cosine_ops)
        WITH (lists = 100)
    """)

    # RLS
    op.execute("ALTER TABLE transactions ENABLE ROW LEVEL SECURITY")
    op.execute("""
        CREATE POLICY transactions_user_isolation ON transactions
        FOR ALL USING (user_id = auth.uid())
    """)

def downgrade() -> None:
    op.drop_table("transactions")
```

## PYTEST: ASYNC TEST PATTERN

```python
# apps/api/tests/test_transactions.py
import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_get_transactions_requires_auth(client: AsyncClient):
    response = await client.get("/api/transactions")
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_get_transactions_returns_only_user_data(
    client: AsyncClient, auth_headers: dict, other_user_transaction_id: str
):
    response = await client.get("/api/transactions", headers=auth_headers)
    assert response.status_code == 200
    transaction_ids = [t["id"] for t in response.json()]
    assert other_user_transaction_id not in transaction_ids
```

## RENDER.YAML: CORRECT FORMAT

```yaml
# render.yaml (in repo root)
services:
  - type: web
    name: [project]-api
    runtime: python
    rootDir: apps/api
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
    envVars:
      - key: PYTHON_VERSION
        value: 3.11
      - key: DEBUG
        value: false
```

Note: All sensitive env vars set in Render dashboard, NOT in render.yaml.
render.yaml is committed to git. Never put secrets in it.
