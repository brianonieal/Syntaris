<!-- DRAFT. Brian decides if and when to publish. Do not publish without approval. -->

# Substack draft: Syntaris as a Compilation-Stage Knowledge Layer

## Length target
700-1000 words.

## Tone
Reflective. Honest. No founder-voice.

## Body

In April 2026 the field around AI coding agents quietly named something that had been there all along. OpenAI called it harness engineering. Martin Fowler called it harness engineering for coding agent users. arxiv papers started using "harness" as a first-class systems object: the layer that integrates memory, tools, planning, and verification into reliable operation. Anthropic supplied the vocabulary; OpenAI made it explicit.

A harness is not a model. It is the system around the model. Context resets, structured handoff artifacts, phase gates, verification loops. The interesting design choice is whether you build a harness that's lightweight enough to survive the next model release, or whether you over-engineer the control flow and watch the next model update break your system.

I've been building a harness for two years without realizing it had a name. I called it Blueprint, then Syntaris when I went public. The original problem was that I kept losing 3-5 days per Forge Genesis rebuild to context resets, regression cascades, and decisions I'd already made being un-made by the agent in a new session. The first fix was to write everything down in markdown files the agent had to read at session start. The second fix was to mechanically enforce that the agent couldn't advance past certain gates without explicit approval. The third fix was to write a reflexion entry every time I closed a gate, comparing predicted hours to actual.

What I didn't realize until April 2026 was that I had built three things the field now has names for. The markdown files are a compilation-stage knowledge layer (per the VentureBeat write-up of Karpathy's compound loop and Pinecone's Nexus architecture). The phase gates are spec-driven development with active validation gates (per the Feb 2026 arxiv paper, "From Code to Contract in the Age of AI"). The reflexion entries are an evaluation harness that doubles as personal calibration data (per Anthropic's distinction between agent harness and evaluation harness in Grace et al., 2026).

This is good news for the project's positioning. The thing I built is now describable in language the field recognizes. It's also bad news for any pretense of novelty. Everything I built has prior art. The contribution, such as it is, is the integration: a five-phase gate ladder mechanically enforced through shell hooks, plus a three-layer memory split (semantic patterns, episodic events, corrections data), plus a calibration loop that runs every gate close.

v0.3.0 of Syntaris is out. Two changes worth talking about.

First: multi-runtime support. The reference runtime is still Claude Code, where hooks block tool calls and gates are mechanical. But the methodology now also loads on Cursor, Windsurf, Codex CLI, Gemini CLI, Aider, Kiro, and OpenCode. The catch is honest tier-based enforcement: Tier 1 (Claude Code) is full hook-based, Tier 2 (Cursor, Windsurf) is rule-based partial, Tier 3 (everything else) is advisory text. The compatibility matrix in the repo names exactly what's enforced where. I considered claiming runtime parity. I decided overclaiming was the bigger risk.

Second: personal versus client. The methodology now distinguishes between personal projects and freelance client work. If you pick "client" at session start, Syntaris collects 12 billing fields, writes them to a CLIENTS.md file, and activates a consolidated billing skill that generates invoices at gate close from actual hours in the calibration loop. At v1.0.0 it produces three handoff documents: a non-technical client summary, a technical handoff for future developers, and a final invoice. Nothing auto-sends; the user reviews everything.

The reason this matters: most methodology frameworks in the AI coding space target casual coders or open-source enthusiasts. Syntaris's actual user is somewhere between casual coder and freelance AI engineer. If you're building for a client, you don't want to remember to manually log hours, generate invoices, or write handoff docs. You want the system you're already using for the methodology to do those things. The client/personal branch in /start is the first version where this is genuinely first-class rather than bolted on.

What's not in v0.3.0: the semantic gate cluster (LSP simulation hook, mutation testing, property-based test scaffolding) ships in v0.4.0. The full 30-task benchmark ships in v0.5.0. The pilot benchmark in v0.3.0 is one task, three runtimes, one published number. It exists as a credibility floor, not a comparison study.

Past audits of Syntaris caught a recurring pattern: I tend to over-scope and under-estimate. v0.3.0 is on the heavier end of that pattern. If the multi-runtime adapters take longer than four weeks to validate, the descope path is honest about it: ship Tier 1 and Tier 2 in v0.3.0 and push Tier 3 to v0.3.5.

Repo: https://github.com/brianonieal/Syntaris.

If you've built a harness without realizing it had a name, you're not alone. The field caught up to the practice. Syntaris is one attempt to do the practice deliberately.
