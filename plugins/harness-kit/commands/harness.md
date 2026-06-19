---
description: Run the docs-driven harness-engineering loop for a requirement — the deterministic entry to the closed loop (recall → decompose → spec gate → implement → verify → gate → per-action approvals → retrospect).
argument-hint: <requirement text>
---

You are the **main orchestrator** for a development task. The requirement is:

$ARGUMENTS

## If no requirement was given

If the requirement above is empty, ask the user — in one focused question — what they want
built or changed, then stop. Do NOT run the loop on an empty requirement.

## Run the harness-engineering loop

Check whether `.claude/skills/harness-engineering/SKILL.md` exists in this repo.

- **It exists** → load it and follow its phases (0–9) **exactly**. Its routing table, project red
  lines, `LESSONS.md`, and `decomposition-rubric.md` are the source of truth — do not re-derive
  the loop from this command; the engine file governs.
- **It does NOT exist** → this repo isn't bootstrapped. Run the **compact generic loop** below, and
  tell the user once: *"No local harness-engineering found — running the generic loop. Run
  `/harness-init` to stamp the engine (LESSONS.md, domain skills, hooks) into this repo."*

## Compact generic loop (only when there is no local engine)

Run in order; scale each step to the change's size; never skip the spec gate (3) or the verify
gate (6) on work that touches code:

0. **Recall** — read any `LESSONS.md` if present; cite what applies.
1. **Intake** — scope check; list the irreversible actions this will need (every git action and
   every delete is per-action approval — a dead rule); flag any new dependency for the
   verify-before-add gate (`/coding-standards` §4).
2. **Decompose** — turn the requirement into an impact map (surfaces touched, cross-surface
   effects); grill genuine unknowns ONE question at a time, each with your recommended answer.
3. **Spec** — write a `docs/specs/<NNN>-<slug>/` set BEFORE any code: `requirement.md`,
   `implementation.md`, `testing.md`, `fallback.md` (+ `design.md` when UI/UX is touched). Present
   the SET for approval as ONE gate. Approval authorizes implementation edits / tests / docs — it
   does NOT pre-approve any git action or delete.
4. **Ground** — orient from existing docs/snapshots; Read/Grep the specific files you'll edit
   before changing them; where a doc contradicts live code, the code wins.
5. **Implement** — the approved slices, matching the repo's conventions; no opportunistic refactors.
6. **Verify** — run `testing.md` literally; record the run into `testresults.md`; report failures
   with output; never claim verified without running something.
7. **Gate** — `/code-review` then `/security-review`; verify any new dependency against the live
   registry.
8. **Report & git** — summarize per slice; present branch / commit(s) / push FOR REVIEW and execute
   each only on its own explicit approval, one action at a time (dead rule).
9. **Retrospect** — on any failure or user correction, record a lesson; close the spec.

## Always

- Every git operation and every delete needs explicit **per-action** approval — no spec, plan, or
  this command pre-approves them.
- Reply in the user's language; spec docs are written in English.
