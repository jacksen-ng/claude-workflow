# Requirement — Slash-command orchestration + delete-guard

- **Status:** implemented <!-- draft | approved | implemented | superseded -->
- **Spec:** 001-slash-command-orchestration

## Problem / why now

The harness engine (`harness-engineering`) is reached today only by **skill auto-trigger** —
Claude decides whether a task description "matches" the skill's `description`. That decision is
probabilistic, so the loop fires inconsistently: the same kind of request sometimes runs the full
docs-driven loop and sometimes doesn't. The user wants a **deterministic front door** — type one
slash command, hand it the requirement, and the loop runs every time.

Two adjacent gaps surface at the same moment and are cheap to close together:
- "All database deletes need approval" is today only a soft instruction the model may forget.
- Test results are produced during the loop but never captured as a durable artifact.

## In scope

- A **global `/harness <requirement>`** slash command shipped by the plugin — the deterministic
  entry that runs the closed loop. Single command, with the existing internal spec-approval pause.
- A **`PreToolUse` hook (plugin-global)** that hard-intercepts destructive DB operations and asks
  for approval — the enforcement teeth under the "all DB deletes need approval" rule.
- A **`testresults.md`** artifact written during Phase 6 into the spec folder.
- Wiring: engine description names `/harness` as the primary entry (auto-trigger demoted to a
  backstop); CLAUDE.md template, harness-init, README, CHANGELOG, version bump, marketplace desc.

## Out of scope

- Rewriting the phase logic of the loop — Phases 0–9 stay as they are.
- Converting `install-guard` / `retrospect-guard` from per-project to global (separate decision).
- De-duplicating the two engine-template copies (`templates/` vs embedded Template A) — this change
  keeps them in sync but does not consolidate them. Flagged, not fixed here.
- Any git automation — every git action stays per-action approval (dead rule).

## Impact map (decomposition — from Phase 1.5)

- **Frontend/UX:** the command's CLI interaction — `argument-hint`, the single doc-approval pause,
  the empty-argument case, and the db-guard confirmation prompt copy → `design.md`.
- **Backend/API:** n/a (no services in this repo).
- **Data/DB:** n/a to *this* repo, but the db-guard's **matcher set** (what counts as a destructive
  DB op) is the core logic to get right — conservative "ask", never hard-deny, never false-pass.
- **Cross-cutting:**
  - Distribution model: command + hook are **plugin-global**; the engine stays **per-project**.
  - Edge: a global `/harness` must still work in a repo that was never bootstrapped (no local
    engine) → fall back to a generic loop and recommend `/harness-init`.
  - Two engine-template copies must stay byte-identical after the edits.
  - No new runtime dependency: the hook is stdlib `python3`, matching `install-guard.py`.
  - Version bump + marketplace/README/CHANGELOG copy.

## Acceptance criteria

1. Typing `/harness <text>` in any repo with the plugin installed **deterministically** starts the
   loop: loads the local engine if present; otherwise runs the generic loop and recommends
   `/harness-init`.
2. The loop still pauses once for spec approval, and still requires per-action approval for every
   git action and every delete (dead rule intact).
3. A Bash command containing a destructive DB op (DROP TABLE/DATABASE, TRUNCATE, DELETE FROM,
   a destructive migration verb, or `rm` on a `*.db/*.sqlite` file) triggers the hook's `ask`
   decision; a benign command passes silently (exit 0, no output).
4. After Phase 6 runs, `testresults.md` exists in the spec folder recording pass/fail per criterion.
5. The engine's description no longer relies solely on auto-trigger; `/harness` is documented as the
   entry in README + the CLAUDE.md template.
6. `templates/harness-engineering.SKILL.md.template` and the embedded Template A remain identical
   after the edits.

## Delegated decisions

- **Command form** — single `/harness` with internal pause, not split `/spec` + `/build` (user chose).
- **DB-delete enforcement** — PreToolUse hard hook, not instruction-only (user chose).
- **Command location** — plugin-global (user chose).
- **Hook location** — plugin-global, to match the command and protect every repo (recommendation
  taken; alternative was stamping per-project like the other two guards).
- **testresults classification** — a Phase-6 *output* doc, not a 6th pre-approval contract doc, so
  the "five-doc spec gate" wording stays unchanged (recommendation taken).

## Open questions

(none — must stay empty before status flips to approved)
