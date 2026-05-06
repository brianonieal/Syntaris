# Recipe: _template

This is the skeleton for writing a Syntaris recipe. Copy this directory to a new name (e.g., `rails`, `django-htmx`, `astro-hono`) and fill in the placeholders.

## Files in a recipe

A recipe is a directory under `recipes/<name>/` with these files:

```
recipes/<name>/
  README.md              <- this file, but for your recipe
  CONTRACT.snippet.md    <- stack-specific fields merged into CONTRACT.md
  CODING_RULES.md        <- language and framework coding rules
  DEPLOYMENT.md          <- deployment platform checklist
  EXAMPLES.md            <- code patterns the agent should follow
  banned-technologies.md <- (optional) technologies banned for this stack
```

## How recipes are loaded

When the user types `CONFIRMED` at the start of a project (after `/start` and `/build-rules` interrogation), Syntaris reads `RECIPE` from CONTRACT.md and merges the recipe's `CONTRACT.snippet.md` into the project's CONTRACT.md. Skills then read `CODING_RULES.md`, `DEPLOYMENT.md`, etc. when they need stack-specific guidance.

## Time to write a recipe

If you know your stack well, a recipe takes 30-60 minutes to write. The skeleton below is the minimum viable version. Fill placeholders and the recipe is functional.

## Promoting your recipe

Once your recipe works for at least one project, submit a PR to the Syntaris repo. The PR template asks for:
- One project that successfully built with the recipe
- Calibration data (predicted vs actual hours for at least 3 gates)
- Honest framing of what works and what doesn't

Community recipes are marked as such in the README and don't carry implicit guarantees from the maintainer.
