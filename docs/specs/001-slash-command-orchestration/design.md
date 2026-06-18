# Design — /harness command UX + delete-guard prompt

UI/UX here is the CLI interaction surface of a slash command and a hook prompt — small but
user-visible, so the choices are pinned here rather than improvised in the command body.

## Flows

- **Primary (bootstrapped repo).** User types `/harness <requirement>` → the command injects the
  orchestration prompt with `$ARGUMENTS` as the requirement → loop runs Phases 0–2 → **one pause**:
  the spec set is presented for approval → user approves → Phases 3–9 run → each git action / delete
  pauses for its own approval. The user reads phase outputs; the only forced stops are the spec gate
  and the per-action approvals.
- **Non-bootstrapped repo.** `/harness` runs but finds no `.claude/skills/harness-engineering/` →
  it runs the compact generic loop AND prints a one-line recommendation to run `/harness-init` so the
  engine becomes permanent in that repo.
- **Delete-guard.** Any `Bash` call → hook scans the command → destructive DB op matched → Claude
  surfaces an `ask` decision with the operation and target shown → user approves or denies.
  No match → silent passthrough (the loop is not interrupted).

## Layout & states (the command)

- `argument-hint`: `<requirement text>`
- **Empty arguments** → the command asks the user what they want built; it does not start the loop
  on an empty requirement.
- Output is plain phase narration. No extra ceremony beyond the two forced stops above.

## Copy

- **db-guard reason** (English, mirroring `install-guard.py`'s tone):
  > 🛡️ Destructive database operation detected (`<op>`). All DB deletes require explicit approval
  > (dead rule). Confirm you intend to run this against `<target>`. If unsure, prefer a reversible
  > path first — soft-delete, or take a backup before running.
- **Non-bootstrapped notice:**
  > No local `harness-engineering` found — running the generic loop. Run `/harness-init` to stamp
  > the engine into this repo so the full loop (LESSONS.md, domain skills, hooks) lives here.

## Decided by user

- Single command + internal pause (not split `/spec` + `/build`).
- DB deletes are hard-gated by a hook, not instruction-only.
- Command (and the matching hook) ship plugin-global.
