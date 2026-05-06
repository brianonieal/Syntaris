# VERSION_ROADMAP.md
# Syntaris v0.3.0 | Full Version Roadmap
# Generated during SCOPE CONFIRMED phase.
# Covers v0.0 through the final version for this build type.

## BUILD TYPE

[Production / GA  |  Internal  |  Exploratory / Prototype]

The build type determines the final version:
- Production / GA -> ends at v1.0 Production Live
- Internal -> ends at v1.0 Internal GA
- Exploratory -> ends at prototype-validated gate (typically v0.3 or v0.4)

## CALIBRATION MULTIPLIER

Multiplier applied to raw estimates: [X.X]x
Source: median variance across last [N] ESTIMATION entries in
MEMORY_CORRECTIONS.md. Default 2.0x when fewer than 3 entries exist.

## ROADMAP

Near-term gates (typically v0.0 through v0.3 or the first third of
total gates) have single-number estimates. Later gates have ranges
with a note on what drives the uncertainty.

| Version | Gate Name | Goal | Est Hours | Actual Hours | Status |
|---------|-----------|------|-----------|--------------|--------|
|         |           |      |           |              |        |

Example row for a near-term gate:
| v0.1 | Core CRUD | add, list, complete, delete commands wired to DB | 3h | - | pending |

Example row for a far-term gate:
| v0.7 | Analytics dashboard | Show revenue, churn, signups over time | 3-10h (depends on Stripe built-in vs custom events) | - | pending |

## RULES

- No gate is skipped
- Failing tests = do not advance
- Each gate defines exactly what ships and what does NOT ship
- Gates over 6 hours should be split into sub-gates (e.g. v0.5-A, v0.5-B)
- Scope changes require re-doing SCOPE CONFIRMED; do not silently
  edit this file mid-build
- When variance > 30% at a gate close, a heads-up is printed but
  approved ranges are NOT silently edited - the user decides whether
  to re-approve

## FINAL GATE

The final gate is labeled explicitly as one of:
- `v1.0 Production Live` (Production / GA build type)
- `v1.0 Internal GA` (Internal build type)
- `v0.X Prototype Validated` (Exploratory build type, X depends on scope)
