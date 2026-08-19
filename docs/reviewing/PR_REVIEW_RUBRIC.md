# Lagoon Images - PR Review Rubric (Explanatory Context)

This document explains the review policy and why it exists.

For automated Copilot enforcement rules, use:

- `.github/instructions/pr-review.instructions.md` (canonical machine-consumed policy)

## Why This File Exists

- Human maintainers need rationale and intent, not only strict rule text.
- The repository needs a stable place to describe review philosophy,
  priorities, and maintenance expectations.
- Automation reliability requires machine-consumable rules in
  `.github/instructions/*.instructions.md`.

## Source of Truth Model

- Canonical automation rules live in `.github/instructions/pr-review.instructions.md`.
- This file is explanatory context and should remain aligned with that file.
- `architecture.md` and `.github/copilot-instructions.md` provide supporting
  structure and workflow guidance.

## Review Priorities (Context)

In descending practical impact for this repository:

1. Build wiring correctness (`docker-bake.hcl` targets + service group + `default` group)
2. Test coverage wiring in `helpers/` compose/testing files
3. Deterministic and secure Dockerfile changes
4. Backward compatibility and lifecycle handling
5. Documentation updates for consumer-visible or structural changes

## Expected Reviewer Behavior (Context)

- Keep findings concrete and actionable.
- Avoid duplicate comments across files for the same root cause.
- Prefer repository conventions over generic best-practice advice.
- Flag concrete risks, not speculative concerns.

## When to Update What

- Update `.github/instructions/pr-review.instructions.md` when changing
  mandatory automated review behavior.
- Update this file when changing explanatory guidance, rationale, or review
  operating model.
- Update `.github/copilot-instructions.md` when workflow recipes or maintainer
  instructions change.
- Update `architecture.md` when structural repository conventions change.

## Practical Maintenance Rule

If this file and `.github/instructions/pr-review.instructions.md` disagree,
automation follows `.github/instructions/pr-review.instructions.md`.

Keep this file concise and explanatory, and keep enforceable review checks in
the instructions file.
