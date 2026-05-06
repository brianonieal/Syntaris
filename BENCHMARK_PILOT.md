# BENCHMARK_PILOT.md - Syntaris v0.3.0 Pilot Benchmark

This is the pilot run that ships with v0.3.0. ONE task, THREE runtimes, ONE day, ONE published result. Even if Syntaris loses or ties, publishing the result IS the credibility move.

The full 30-task benchmark with audited task selection by a non-Syntaris user ships in v0.5.0. This pilot is a credibility deposit, not a comparison study.

## Task

**Build a Python CLI todo app** with these exact requirements:

- `todo add <text>` adds a todo
- `todo list` shows pending todos
- `todo done <id>` marks complete
- `todo delete <id>` removes
- `todo show <id>` shows a single todo
- SQLite storage (persistent across runs)
- 10+ tests (`pytest`)
- Coverage above 70% on business logic
- Working `--help` for every command
- Published as a `pip install`able package via `pyproject.toml`

The exact task spec, including initial prompt text given to the agent, is locked in `BENCHMARK_PILOT_TASK.md` - generate that file before running so all three runs use identical prompts.

## Runtimes (3)

1. **Vanilla Claude Code** - fresh Claude Code install. No Syntaris, no methodology, no skills, no hooks. The user prompts naturally.
2. **Syntaris-on-Claude-Code** - Claude Code with Syntaris v0.3.0 installed at Tier 1. User runs `/start`, picks `python-cli` recipe, follows the gate flow.
3. **Syntaris-on-Cursor** - Cursor with Syntaris v0.3.0 Tier 2 adapter installed. Same task, same user prompt structure as Tier 1, with Tier 2's reduced enforcement.

## Metrics

For each run, log:

1. **Total tokens (input + output)** - pulled from runtime usage data or API billing
2. **Wall-clock time** - start to "task complete" stopwatch
3. **Number of human interventions** - count messages where the user said "no", "that's wrong", "go back", or had to re-explain a requirement
4. **Test pass count at completion** - how many of the 10+ tests pass on first `pytest` run
5. **Manual verification: does the CLI actually work** - the user runs `todo add "test"` then `todo list` and confirms expected behavior
6. **Number of regressions** - features that worked at one point but broke later (count distinct ones)

## Run protocol

For each runtime, follow this exact sequence:

1. Fresh project directory: `mkdir benchmark-pilot-<runtime>`
2. Open the runtime in that directory
3. Paste the locked task spec from `BENCHMARK_PILOT_TASK.md`
4. For Syntaris runs: type `CONFIRMED` after CONTRACT.md is generated, `ROADMAP APPROVED` after VERSION_ROADMAP.md, `GO` for the build gate. (Skip MOCKUPS APPROVED and FRONTEND APPROVED - CLI has no UI.)
5. For Vanilla Claude Code: just iterate naturally. Don't impose any methodology.
6. Stop when the user can run all CLI commands and tests pass - or when the user gives up after 3 hours of intervention.
7. Record metrics in `BENCHMARK_PILOT_RESULTS.md`

## Honest framing

This is `n=1` per condition. Statistically meaningless. Useful as:

- A sanity check that Syntaris doesn't make things slower for trivial tasks
- A demonstration that the methodology applies to a non-fintech project
- The first published result from a Syntaris benchmark, ever
- A test of the Tier 2 adapter against Tier 1 to validate that rules-based enforcement works

What it is NOT:
- Evidence of general productivity claims
- A comparison against other frameworks (Superpowers, GSD, gstack) - those need their own runs in v0.5.0
- A statistically valid measurement of anything

## What to publish

After the run, write `BENCHMARK_PILOT_RESULTS.md` with:

- Date of run
- Operator (you)
- Three runtime results in a table (tokens, time, interventions, tests, regressions)
- Honest commentary: what surprised you, what's not in this data, what you'd want to test next
- Link from README.md to the results file

If Syntaris loses on time or tokens (likely on this small a task - gate overhead costs something), publish the loss. Don't hide it. The credibility move is honesty about what the methodology costs and where it pays back.

## Cost estimate for the pilot

- Vanilla Claude Code: 1-2 hours, ~50K tokens
- Syntaris on Claude Code: 1-3 hours, ~80-150K tokens (gate overhead)
- Syntaris on Cursor: 1-3 hours, ~80-150K tokens (Tier 2 partial enforcement)

Total: 4-8 hours of operator time. ~$3-8 in API costs depending on model selection.

## When to run

After the v0.3.0 zip is unpacked, install scripts have been validated against Claude Code on the user's machine, and Tier 2 Cursor adapter has been smoke-tested via `BUILD_NEXT.md` task 1.

Run on a single weekend day. Document raw and publish.
