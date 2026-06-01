---
name: harness
description: Orchestration entry point for non-trivial work in ANY project. Use this skill at the START of any non-trivial feature request, change, or multi-step task ("帮我做…", "实现…", "加一个…", "改一下…", refactors, deploys, debugging that spans files). It runs a closed-loop workflow — intake guardrails, planning with a sprint contract, on-demand loading of the right domain skill(s), grounding context against live code, implementation, verification, and a quality/security gate — so long-running work stays scoped, safe, and aligned with the user's hard rules. Project-agnostic: it reads the project's own CLAUDE.md routing table and domain skills when present, and degrades gracefully when they are not. Reuses /code-review, /security-review, /verify, /run, /git-commit, /vibe-coding, /dev-init.
---

# Harness — Generic Orchestrator

This is the reusable harness around long-running work in **any** repo. It is the project-agnostic engine extracted from a per-project orchestrator: it holds the workflow, the guardrails, and the routing *mechanism* — but the project-specific *map* (what the repo is, its domains, its red lines) lives in that project's own `CLAUDE.md` and domain skills, loaded on demand.

Guiding idea: the harness is a first-class engineering artifact. Every phase below encodes an assumption about what the model should NOT do unsupervised — task scoping, self-evaluation, irreversible actions. Prune any phase that stops earning its keep on a given project.

**Ground before trust (load-bearing).** Any skill — global or per-project — is a *map*: intent, decisions, and a point-in-time snapshot of structure. The *code* is the territory. Paths, names, and signatures in any skill MAY be stale. Whenever a task depends on a specific piece of code, verify it against the live repo before acting (Phase 4). If reality contradicts a skill, the **code wins** — proceed on the code and fix the skill.

**Where the rules come from.** Two layers stack:
- **User global hard rules** (always loaded from `~/.claude/CLAUDE.md`) — e.g. *any delete or git operation needs explicit per-action approval*; reply language; privacy paths. These always apply.
- **Project rules** (this repo's `CLAUDE.md`, if present) — the always-on section + routing table. Read it at intake. If the repo has no `CLAUDE.md`/domain skills yet, the loop still runs; consider suggesting `harness-init` to lay them down.

## The closed loop

Run these phases in order. Do not skip the gate phases (6–8) on any change that touches code.

### Phase 1 — Intake (guardrail checklist)

Before planning anything, run this checklist out loud (one line each):

1. **Scope / alignment.** Is the request aligned with this project's stated goal and any "in scope" constraints in its `CLAUDE.md`? If it drifts (new vertical, scope creep, something the project explicitly excludes), STOP and flag the conflict before implementing.
2. **Open decisions.** Does it touch a design question with more than one defensible answer, or one the project marks as undecided? If yes, present 2–3 options with tradeoffs and WAIT — never decide unilaterally. (This is the user's standing `vibe-coding` rule.)
3. **Irreversible actions.** Does it involve git (commit/push/merge/rebase/reset/branch switch) or any delete/overwrite? If yes, mark it "requires explicit approval" now; you will stop for approval in Phase 8. Approval is **per-action**, never assumed from a prior turn (user global hard rule).
4. **Project red lines.** Does this repo's `CLAUDE.md` define always-on red lines (e.g. "never fabricate X", secrets discipline, a locked list)? Name the ones this task could touch and hold them through the gate.

### Phase 2 — Plan (sprint contract)

- Decompose into the smallest shippable slices. One feature per slice — do not attempt the whole thing in one pass (long monolithic builds lose coherence).
- Write a **sprint contract**: 2–4 bullets of explicit, testable success criteria for this slice. Confirm with the user before coding when the design has more than one defensible answer.
- Decide which domain skill(s) to load (see Phase 3). Note them explicitly.

### Phase 3 — Dispatch (load domain context on demand)

Consult the project `CLAUDE.md` routing table and load **only** the domain skill(s) the task hits. This is the context-saving move — do not pull all project context for a localized change. A full-stack change may load two skills; a config fix loads one. When unsure which, prefer loading one and expanding over loading all. If the project has no domain skills, build context by reading the relevant files directly (Phase 4 does this anyway).

### Phase 4 — Ground (verify context against live code — verify-on-touch)

Insurance against acting on a stale skill or stale memory. Trigger this **only when the task depends on specific code** (you are about to edit, call, or cite a file / function / signature / structure). Pure-intent tasks (e.g. "is this in scope?") skip it.

- **Narrow ("I'm about to change this one file")** → `Read` the file's current state before editing. Never edit from memory of how a skill described it.
- **Broad ("where is X implemented?", "what does this subsystem look like now?")** → spawn the **Explore** subagent (read-only fan-out search). It scans and returns the conclusion, so supplementary context lands without flooding the main window. Use a domain skill's "Ground-truth anchors" list as starting paths when one exists.
- **Uncertain a cited symbol/path still exists** → `Grep` for it before relying on it.

**Drift handling (code wins + auto-update):** if live code contradicts what a loaded skill claims, proceed on the basis of the code, note the drift in the report, and **update the affected skill's SKILL.md** to match reality. Editing a skill doc is not a git action — no approval needed; but do NOT also commit it (committing still goes through Phase 8). Keep the map current so the next task starts from truth.

### Phase 5 — Implement

Follow the project's coding conventions (from its `CLAUDE.md` / domain skill / the surrounding code). Match the existing style — naming, indentation, quote style, comment density — rather than imposing your own. Preserve existing architecture: no opportunistic refactors while implementing a feature; propose those separately. When a project hasn't stated conventions, fall back to the user's `vibe-coding` defaults (minimum invasiveness, modify only what's specified, respect mock data, no inline comments unless asked).

### Phase 6 — Verify (separate generation from evaluation)

Do NOT let the same context that wrote the code judge it "done." Run `/verify` or `/run` to observe real behavior, or run the relevant tests. Report failures with their output; never claim verified without having actually run something.

### Phase 7 — Quality & Security gate

In order, on any code change:
1. `/code-review` — correctness + reuse/simplification.
2. `/security-review` — pending-changes security pass (secrets discipline: never log a full key — mask all but the last 4, even at DEBUG).
3. If infra files changed (Dockerfile / compose / IaC): lint them (e.g. `hadolint`, a `docker build` dry run, `docker compose config`). Run such tooling inside a container, not via host/global installs, when the project works that way.
Re-confirm the Phase-1 project red lines held in the actual diff.

### Phase 8 — Report & approval

Summarize what changed and what was verified — faithfully; state skipped steps as skipped. For anything marked irreversible in Phase 1 (git / delete / overwrite), STOP and ask for explicit approval before executing. Use `/git-commit` only after approval, following the user's commit style. If a development phase or module completed, consider a devlog entry per `/dev-init` conventions.

## Routing — the mechanism

The harness routes via the **project's own** `CLAUDE.md` routing table (task surface → domain skill). It does not hardcode any project's domains. To create that table and the matching domain skills for a fresh repo, run **`harness-init`** — it explores the repo and lays down a thin `CLAUDE.md` plus per-domain skills that this harness then routes through.

Reusable building blocks this harness sequences (does not reimplement): `/code-review`, `/security-review`, `/verify`, `/run`, `/git-commit`, `/vibe-coding`, `/dev-init`.

## What this skill does NOT do

It does not reimplement review, verification, scaffolding, or commit logic — it sequences the skills above into a safe loop. It does not carry any single project's specifics — those come from that project's `CLAUDE.md` and domain skills. Keep it an orchestration contract; if a phase stops adding value as models improve, prune it.
