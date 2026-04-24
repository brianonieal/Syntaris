# RESEARCH_AGENDA.md
# Blueprint v11 | Track 3 Research Agenda
# Independent Study Specifications
# Maps to: {{COURSE_MAPPING}} (configure per academic program)

---

## OVERVIEW

Track 3 is the research agenda that runs parallel to real project builds.
It cannot be built -- it requires data collected from actual gate outcomes.
The data collection vehicle is every project built on Blueprint v11.

Three research questions:
1. Can RAG retrieval replace flat-file memory and improve pre-fill accuracy at scale?
2. Is Blueprint v11's methodology model-agnostic, or does it depend on Claude-specific behavior?
3. Does adding a second developer at specific gate boundaries improve or degrade quality?

Each question is a self-contained study with hypothesis, data collection plan,
measurement protocol, and expected deliverable.

---

## RELATED WORK

Blueprint v11 sits at the intersection of four active research areas. The
following papers and benchmarks are cited by the three research questions
below and position this work within current academic discourse. Every arxiv
ID and attribution in this section has been verified against the primary
source (arxiv abstract page or equivalent) as of April 2026.

**Specification-driven LLM code generation**

- Rosa, G., Moreno-Lumbreras, D., Robles, G., and Gonzalez-Barahona, J.
  (2026). "Understanding Specification-Driven Code Generation with LLMs:
  An Empirical Study Design." arXiv:2601.03878. Stage 1 Registered Report
  with Continuity Acceptance at SANER 2026. Introduces CURRANTE, a Visual
  Studio Code extension guiding developers through a three-stage workflow:
  Specification, Tests, Function. The study design measures how human
  intervention at each stage influences LLM-generated code quality on
  LiveCodeBench problems. Blueprint v11's five-gate approval process is a
  stronger-constraint analogue of CURRANTE's three-stage workflow; Research
  Question 2 directly tests whether the specification-completeness
  hypothesis underpinning both approaches is model-agnostic.

- Thoughtworks (2025). "Spec-driven development: Unpacking one of 2025's
  key new AI-assisted engineering practices." Author: Liu Shangqi.
  https://www.thoughtworks.com/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices
  Industry framing of the practice Blueprint instantiates.

**LLM instruction-following limits**

- Jaroslawicz, D., Whiting, B., Shah, P., and Maamari, K. (2025).
  "How Many Instructions Can LLMs Follow at Once?" arXiv:2507.11538.
  Distyl AI. Introduces IFScale, a 500-keyword-inclusion benchmark measuring
  how instruction-following degrades as instruction density increases.
  Reports that even the best frontier models achieve only 68% accuracy at
  the maximum density of 500 instructions, with three distinct degradation
  patterns correlated with model size and reasoning capability, and a
  measurable bias toward earlier instructions. This motivates Blueprint
  v11's CLAUDE.md discipline of staying concise and preferring hooks for
  mechanical enforcement of the rules that matter most.

- Qi, Y., Peng, H., Wang, X., Xin, A., Liu, Y., Xu, B., Hou, L., and
  Li, J. (2025). "AGENTIF: Benchmarking Instruction Following of Large
  Language Models in Agentic Scenarios." arXiv:2505.16944. NeurIPS 2025 DB
  Spotlight. Constructs 707 human-annotated instructions across 50 real-world
  agentic tasks, averaging 11.9 constraints per instruction. Reports that
  current models generally perform poorly on complex constraint structures
  and tool specifications, motivating Research Question 2's focus on
  specification completeness as a possible compensating mechanism.

- HumanLayer (2025). "Writing a good CLAUDE.md." Author: Dex. Published
  August 29, 2025. https://www.humanlayer.dev/blog/writing-a-good-claude-md
  Practitioner analysis of the Claude Code harness estimating ~50
  instructions in the system prompt, with a soft budget of 150-200 before
  compliance degrades. Argues that CLAUDE.md bias toward prompt peripheries
  means later instructions are not merely ignored but cause uniform
  degradation across all instructions. Relevant to Blueprint v11's choice
  to keep CLAUDE.md under tight length budgets and to route mechanical
  enforcement through hooks rather than prose rules.

**Agent memory architectures**

- Packer, C., Wooders, S., Lin, K., Fang, V., Patil, S.G., Stoica, I., and
  Gonzalez, J.E. (2023). "MemGPT: Towards LLMs as Operating Systems."
  arXiv:2310.08560 (v2 February 2024). Proposes virtual context management
  with a hierarchical memory hierarchy (main context vs external context)
  and interrupt-driven memory paging. The hot/warm/cold pattern in Phase 5
  of Research Question 1 is adapted from MemGPT's main-context vs
  external-context distinction, not identical to it; Blueprint applies the
  pattern to a file-based memory tree rather than LLM-managed paging.

- Voyage AI (2024-2025). voyage-3-large model documentation. Matryoshka
  dimensionality (2048/1024/512/256) enabled by Matryoshka Representation
  Learning; quantization-aware training supporting float, int8, uint8, and
  binary precisions. Relevant to Research Question 1's RAG implementation
  choices. https://blog.voyageai.com/2025/01/07/voyage-3-large/

**Reproducibility and quality of LLM-generated code**

- Vangala, B.P., Adibifar, A., Gehani, A., and Malik, T. (2025).
  "AI-Generated Code Is Not Reproducible (Yet): An Empirical Study of
  Dependency Gaps in LLM-Based Coding Agents." arXiv:2512.22387. Reports
  68.3% execute-out-of-the-box rate across 300 projects generated by three
  leading coding agents (Claude Code, OpenAI Codex, Gemini), with
  substantial variation by language (Python 89.2%, Java 44.0%). Introduces
  a three-layer dependency framework distinguishing claimed, working, and
  runtime dependencies, finding a 13.5x average expansion from declared to
  actual runtime dependencies. Relevant baseline for Research Question 2.

- Watanabe, M., Li, H., Kashiwa, Y., Reid, B., Iida, H., and Hassan, A.E.
  (2025). "On the Use of Agentic Coding: An Empirical Study of Pull
  Requests on GitHub." arXiv:2509.14745. Empirical study of 567 Claude Code
  pull requests across 157 diverse open-source projects. Reports 83.8%
  eventual merge rate with 54.9% of merged PRs integrated without further
  modification. Highlights project-specific rules as a factor in acceptance.
  Directly relevant to Research Question 3 (team collaboration gates).

**Agentic programming landscape**

- Wang, H., Gong, J., Zhang, H., Xu, J., and Wang, Z. (2025). "AI Agentic
  Programming: A Survey of Techniques, Challenges, and Opportunities."
  arXiv:2508.11126. Taxonomy of agent behaviors and system architectures,
  covering planning, memory and context management, tool integration,
  execution monitoring, and benchmarking. Identifies long-context handling,
  lack of persistent memory across tasks, and alignment with user intent
  as key open challenges. Positions Blueprint v11 as a methodology layer
  above any agent framework, not a framework itself.

**Positioning statement**

Blueprint v11's claimed contribution is not a new technique; it is an
integration: specification-driven development (Rosa et al., CURRANTE),
instruction-budget discipline (Jaroslawicz et al., IFScale; HumanLayer),
hierarchical memory (Packer et al., MemGPT), and gate-structured human
oversight applied to a named freelance and academic use case. The three
research questions each isolate one axis of this integration and test it
empirically. The contribution is evidence, not invention.

A known limitation of this positioning: as of v11.2, Blueprint has been
deployed primarily on projects by its original author. External replication
is required before any claim of generalization can be made. Research
Questions 1 and 2 explicitly require multi-project data and cannot produce
meaningful results from a sample size of one.

---

## RESEARCH QUESTION 1: RAG-BASED MEMORY RETRIEVAL

### The Problem

MEMORY_SEMANTIC.md is a flat markdown file.
Claude Code reads it linearly from top to bottom.
At 5 projects it holds ~20 patterns -- manageable.
At 20 projects it holds ~80 patterns -- a wall of text.
There is no semantic indexing. Every pattern competes equally for attention.
Pre-fill accuracy will degrade as the file grows, but this has not been measured.

### Hypothesis

RAG retrieval (embedding-based semantic search over patterns) will:
- Maintain or improve pre-fill accuracy as pattern count grows
- Reduce context footprint at session start (load top-K patterns, not all)
- Produce more relevant pre-fills (semantically similar, not just most recent)

Null hypothesis: flat-file accuracy is sufficient at realistic scale (< 50 patterns)
and RAG adds complexity without meaningful accuracy improvement.

### Data Collection Plan

Phase 1: Instrument Blueprint v11 to record pre-fill events.

At every interrogation, log:
```markdown
## PRE-FILL LOG: [Project Name] -- [date]
Question: [interrogation question]
Pre-fill source: DEC-[NNN] in MEMORY_SEMANTIC.md
Pre-fill answer: [what was pre-filled]
Correct: YES | NO | PARTIAL
If NO: correct answer was [what the user actually answered]
Pattern confidence before: LOW | MEDIUM | HIGH
Pattern confidence after: [updated]
```

Store in: MEMORY_CORRECTIONS.md under ## PRE-FILL ACCURACY LOG

Target: 26 pre-fill events across 2 projects (13 gates × 2 projects minimum)
Stretch target: 52 events across 4 projects

Phase 2: Baseline measurement

After 26 events, calculate:
- Overall pre-fill accuracy rate (correct / total)
- Accuracy by pattern type (tech stack, agent architecture, billing, deployment)
- Accuracy by confidence level (LOW vs MEDIUM vs HIGH)
- Accuracy vs file size (does it degrade as patterns accumulate?)

Phase 3: RAG implementation

Build RAG layer using Voyage AI embeddings:

```python
# memory_rag.py
import voyageai
import numpy as np
from pathlib import Path

voyage = voyageai.AsyncClient()

async def build_pattern_index(memory_semantic_path: str) -> dict:
    """Parse MEMORY_SEMANTIC.md and embed each pattern."""
    patterns = parse_patterns(memory_semantic_path)
    embeddings = await voyage.embed(
        [p["text"] for p in patterns],
        model="voyage-3",
        input_type="document",
    )
    return {
        "patterns": patterns,
        "embeddings": np.array(embeddings.embeddings),
    }

async def retrieve_relevant_patterns(
    query: str,
    index: dict,
    top_k: int = 5,
) -> list[dict]:
    """Retrieve top-K patterns semantically similar to the interrogation question."""
    query_embedding = await voyage.embed(
        [query],
        model="voyage-3",
        input_type="query",
    )
    query_vec = np.array(query_embedding.embeddings[0])

    # Cosine similarity
    similarities = np.dot(index["embeddings"], query_vec) / (
        np.linalg.norm(index["embeddings"], axis=1) * np.linalg.norm(query_vec)
    )
    top_indices = np.argsort(similarities)[::-1][:top_k]
    return [index["patterns"][i] for i in top_indices]
```

Phase 4: A/B measurement

Run 10 interrogation sessions with flat-file retrieval.
Run 10 interrogation sessions with RAG retrieval.
Measure: pre-fill accuracy, pre-fill relevance (1-5 rating by the user), time to SCOPE CONFIRMED.

Phase 5: Hierarchical paging (if RAG validates)

Implement hot/warm/cold memory tiers (MemGPT pattern - Packer et al. 2023, arxiv 2310.08560):
- Hot: current project patterns (always loaded, 5 patterns max)
- Warm: recent patterns from last 3 projects (loaded on similarity threshold)
- Cold: all historical patterns (retrieved only on explicit semantic query)

### Expected Deliverable

Section in independent study paper:
"Flat-File vs RAG Memory Retrieval in Agentic Development Workflows"

Hypothesis validation or rejection with data.
Working RAG implementation included as appendix code.

### Maps to

{{COURSE_651}} Large Language Models -- retrieval-augmented generation
{{COURSE_625}} Agentic AI -- persistent agent memory architectures

---

## RESEARCH QUESTION 2: MULTI-VENDOR RESILIENCE

### The Problem

Blueprint v11 is 100% dependent on Anthropic Claude models.
When Anthropic changed model behavior in February-March 2026 (thinking redaction,
effort level changes), Claude Code quality degraded measurably across all users.
Blueprint v11 had no fallback and degraded in lockstep.

The deeper question: is Blueprint v11's quality attributable to the methodology
(pre-specification, gate structure, memory) or to Claude-specific behavior?

If the methodology is the driver: any capable model should produce similar output.
If Claude is the driver: the methodology is less portable than claimed.

### Hypotheses (falsifiable, decomposed)

The original framing ("within 15% quality") composed three objective metrics into
a single undefined "quality" score. That is not falsifiable. Rewriting as three
separate hypotheses with explicit measurement protocols:

**H2a (test pass rate):** Given identical specifications (SCOPE CONFIRMED through
FRONTEND APPROVED) and the same 5-gate benchmark project, the test pass rate
produced by GPT-5 and Gemini 2.5 Pro (via LiteLLM) will be within ±15 percentage
points of the test pass rate produced by Claude Sonnet 4.6 at each gate.

- Measurement: `pytest --tb=no -q` pass count / total count per gate.
- Falsified if: any non-Claude model's pass rate deviates by more than 15 pp on
  two or more of the 5 gates.

**H2b (security findings):** Security findings count per gate (from the standard
Blueprint `/security` audit) produced by GPT-5 and Gemini 2.5 Pro will differ
from Claude Sonnet 4.6's findings count by at most 2 CRITICAL/HIGH findings
across the 5-gate project total.

- Measurement: count of CRITICAL + HIGH items in SECURITY.md per run.
- Falsified if: any non-Claude model produces 3+ more CRITICAL/HIGH findings
  than Claude across the 5 gates, OR 3+ fewer (missed vulnerabilities).

**H2c (visual drift):** Visual drift findings count per screen (from
Playwright screenshot comparison against the MOCKUPS.md reference images)
produced by GPT-5 and Gemini 2.5 Pro will differ from Claude Sonnet 4.6 by
at most 1.0 drifts per screen on average across all screens in the 5-gate
benchmark project.

Operationalization - what counts as a drift, exactly:

- Each screen in MOCKUPS.md has a reference image captured during
  MOCKUPS APPROVED gate close at a fixed viewport (1280x720 desktop,
  375x812 mobile). These images are the ground truth baseline.
- After each gate close that modifies frontend code, Playwright captures
  the same screens at the same viewports and runs
  `pixelmatch(reference, actual, {threshold: 0.1})`.
- A screen is flagged as a DRIFT if the pixelmatch mismatch ratio exceeds
  0.5% of total pixels. This threshold is empirically chosen to tolerate
  anti-aliasing noise and browser-font rendering variance while catching
  real layout shifts, color changes, or missing elements. The 0.5% figure
  is a Blueprint default; projects may override via VISUAL_CHECKS.md if
  the project has legitimate dynamic content (e.g., randomized charts).
- "Drift count per screen" is a binary 0/1 per screen per gate, summed
  across all screens and gates, divided by (num_screens * num_gates).

- Measurement log format in VISUAL_CHECKS.md (one row per screen per gate):
  ```
  | gate | screen | mismatch_ratio | drifted | reason_if_drifted |
  ```
- Falsified if: any non-Claude model's mean drift-per-screen rate exceeds
  Claude's mean drift-per-screen rate by more than 1.0 (i.e., for every
  screen Claude gets right, the other model drifts on more than one
  additional screen on average).

**Methodological note:** Each hypothesis is tested independently. Partial
confirmation (e.g., H2a holds but H2b fails) is a finding - it would suggest
specification completeness drives functional correctness but not security or
UI fidelity.

**Null hypothesis (combined):** Claude-specific training produces measurably
better output for the Blueprint v11 gate structure on all three metrics, such
that H2a, H2b, and H2c are all falsified.

**Power analysis note:** 5 gates × 3 models = 15 data points per metric. This
is underpowered for strong statistical claims; the study should be framed as
an exploratory case study with effect-size reporting, not a hypothesis test
with p-values. A larger multi-project replication is future work.

### Data Collection Plan

Phase 1: Vendor abstraction layer

Modify CONTRACT.md to support model variables:
```
PRIMARY_AGENT_MODEL:    claude-sonnet-4-6  # change this to swap vendors
CLASSIFIER_MODEL:       claude-haiku-4-5
EMBEDDING_MODEL:        voyage-3
```

Modify skill files to reference model variables instead of hardcoded names.
LiteLLM handles routing -- one line change in CONTRACT.md switches vendors.

Phase 2: Benchmark project design

Design a standardized 5-gate benchmark project:
- Simple CRUD app with auth (no AI agents, to isolate model behavior)
- Fully pre-specified: SCOPE CONFIRMED -> FRONTEND APPROVED before any build
- Same specification, different execution models

Phase 3: Multi-model execution

Run the benchmark project to completion on:
- Claude Sonnet 4.6 (baseline)
- GPT-5 via LiteLLM
- Gemini 2.5 Pro via LiteLLM

Measure per run:
- Test pass rate at each gate (objective)
- Security findings count (objective)
- Visual drift findings count (objective)
- Time to gate close (objective)
- the user's quality rating 1-10 (subjective)

Phase 4: Analysis

For each hypothesis H2a/H2b/H2c independently:
- Calculate the deviation between each non-Claude model and the Claude baseline.
- Compare against the falsification threshold defined in the hypothesis.
- Report per-hypothesis: CONFIRMED | PARTIALLY CONFIRMED | FALSIFIED.
- Partial confirmation (one hypothesis confirmed, another falsified) is itself a
  finding and should be reported as such rather than aggregated.

### Implementation

LiteLLM routing configuration:
```python
# litellm_config.py
import litellm
import os

# Read from CONTRACT.md at session start
PRIMARY_MODEL = os.environ.get("PRIMARY_AGENT_MODEL", "claude-sonnet-4-6")

async def complete(messages: list, **kwargs):
    """Route to configured model via LiteLLM."""
    return await litellm.acompletion(
        model=PRIMARY_MODEL,
        messages=messages,
        **kwargs
    )
```

### Expected Deliverable

Section in independent study paper:
"Model-Agnostic Methodology: Does Specification Completeness Determine Quality?"

Direct test of the core thesis: pre-specification completeness drives quality,
not the model used for execution.

### Maps to

{{COURSE_651}} Large Language Models -- model comparison methodology
{{COURSE_625}} Agentic AI -- agent portability across model providers

---

## RESEARCH QUESTION 3: TEAM COLLABORATION GATE STUDY

### The Problem

Blueprint v11 is designed for solo development.
Every approval gate requires the user's judgment.
Scaling requires either removing gates (dangerous) or distributing approval (complex).

The question is not "should Blueprint support teams?"
The question is "at which gates does a second reviewer improve quality,
and at which gates does it just add coordination overhead?"

### Hypothesis

A second developer adds measurable quality improvement at:
- Architecture gates (roadmap, tech stack, agent design)
- Security review gates

A second developer adds minimal quality improvement but meaningful overhead at:
- Implementation gates (component building, CRUD)
- Gate close checklists

### Study Design

Phase 1: Identify a suitable project

A client project with a second developer is the ideal vehicle.
Alternatively: a personal project where the user invites a peer reviewer at specific gates.

Phase 2: Gate assignment

Randomly assign gates to two conditions:
- SOLO: The user reviews and approves alone
- PAIRED: the user and a second developer both review before GO

Ensure balanced distribution across gate types (architecture, implementation, review).

Phase 3: Measurement

At each gate, measure:
- Time to gate close (solo vs paired)
- Bugs found in next gate that originated in this gate (objective quality measure)
- Security findings in next security audit that trace to this gate
- the user's confidence rating 1-10 (subjective)

Phase 4: Analysis

Compare solo vs paired gates on all metrics.
Identify which gate types benefit most from a second reviewer.
Calculate the overhead cost (time) vs quality benefit.

### Expected Deliverable

Section in independent study paper or separate paper:
"Human Oversight Gate Design in Agentic Development Workflows"

Recommendation: which gates are worth pairing and which are not.
Practical output: TEAM.md updated with data-driven gate assignment guidance.

### Maps to

{{COURSE_625}} Agentic AI -- human-in-the-loop design patterns
{{COURSE_744}} Deep Learning Using Transformers -- multi-agent coordination

---

## DATA COLLECTION INFRASTRUCTURE

All three research questions share a common data collection format.
This makes cross-question analysis possible.

### REFLEXION ENTRY FORMAT (extended for research)

```markdown
## REFLEXION: v[X.X.X] -- [Gate Name]
Date: [date]
Project: [name] | Build #[N across all projects]
Model: [PRIMARY_AGENT_MODEL from CONTRACT.md]

ESTIMATE
  Predicted: [X] hours
  Actual:    [X] hours
  Variance:  [+/-X]%

PRE-FILL ACCURACY (Research Q1)
  Questions asked: [N]
  Pre-filled: [N]
  Pre-fills correct: [N]
  Pre-fills incorrect: [list]

VENDOR NOTES (Research Q2)
  Model used: [model]
  Behavior differences from Claude baseline: [none | list]

COLLABORATION NOTES (Research Q3)
  Gate condition: SOLO | PAIRED
  Time to gate close: [N minutes]
  Reviewer: [name if PAIRED]

TECHNICAL PREDICTIONS VS REALITY
  Predicted: [what was expected]
  Actual: [what happened]
  Gap: [what was different]

CORRECTION FOR FUTURE
  [what changes in future estimates or patterns]

MEMORY_SEMANTIC.md UPDATE
  Pattern added: [none | DEC-NNN description]
  Confidence updated: [none | DEC-NNN LOW->MEDIUM]
```

### CUMULATIVE TRACKING TABLE

Maintain in MEMORY_CORRECTIONS.md after every 5 gates:

```markdown
## CUMULATIVE RESEARCH DATA -- updated [date]

| Metric | Value | Notes |
|--------|-------|-------|
| Total gates completed | [N] | across all projects |
| Pre-fill events logged | [N] | Q1 data collection |
| Pre-fill accuracy | [X]% | Q1 baseline |
| Models tested | Claude Sonnet 4.6 | Q2 -- expand after baseline |
| Solo gates | [N] | Q3 data |
| Paired gates | [N] | Q3 data |
| Estimate accuracy (mean) | [X]% variance | across all gates |
```

---

## PUBLICATION TIMELINE

| Milestone | Target | Deliverable |
|-----------|--------|-------------|
| 26 gate data points | After project 2 | Q1 baseline dataset |
| Flat-file baseline measured | After project 2 | Q1 baseline metrics |
| RAG implementation | Independent study start | Working RAG prototype |
| Vendor abstraction layer | Spring 2026 | LiteLLM-routed BUILD_RULES |
| Benchmark project run | Summer 2026 | Q2 multi-model data |
| Team collaboration study | First client project | Q3 data |
| Research paper draft | September 2026 | Independent study submission |
| Final submission | {{GRADUATION_DATE}} | Independent study complete |

---

## INDEPENDENT STUDY ADVISOR

{{ACADEMIC_ADVISOR}}
{{ACADEMIC_INSTITUTION}}
Context: Blueprint v11 was presented as a potential independent study topic
in the context of AI estimation compression findings (consistent -92% variance
across 7 gate types in one session).

The research agenda in this file maps directly to the academic questions
{{ACADEMIC_ADVISOR}} identified as publishable: methodology reproducibility,
model-agnostic behavior, and human-in-the-loop gate design.
