---
name: harness-init
description: Bootstrap a project to use the harness workflow. Run ONCE in a repo (new or existing) when the user wants to "set up my workflow here", "初始化工作流", "scaffold CLAUDE.md and skills", or start a new project with their standard harness. It explores the repo to learn the real stack and structure, then generates THREE things into the repo — (1) a project-local `harness-engineering` orchestrator skill (the closed-loop engine, self-contained), (2) a thin CLAUDE.md (always-on rules + routing table), and (3) one domain skill per natural surface (frontend / backend / infra / data / db / …) following the proven snapshot + ground-truth-anchors template. If the repo already has skills or a CLAUDE.md, it first inventories and reconciles them against the live code — keeping what matches, proposing updates for what drifted, adding what is missing — instead of overwriting. Presents everything for review before finalizing. Complements `/dev-init` (file/folder scaffold) — this lays down the *context layer*, not the directory tree.
---

# Harness Init — Project Bootstrapper

One-shot setup that stamps the user's reusable workflow onto a repo. The goal: after running this, the repo is **self-contained** — it has its own local `harness-engineering` orchestrator that runs the closed loop and routes to thin per-domain skills, exactly like the user's mature projects, without depending on any global skill.

This is the **context layer** (a local orchestrator + CLAUDE.md + domain skills). It complements `/dev-init`, which lays down the directory tree, Docker, and devlog scaffold. If the repo is greenfield with no structure yet, suggest running `/dev-init` first (or alongside).

**Key model:** the engine lives **in each project**, not globally. This plugin ships the *generator* (this skill) and the *template* for the engine; running it drops a tailored `harness-engineering` into the repo. There is no global orchestrator — each project owns its own.

## Operating principle

**Generate from the live repo, not from a guess.** Every path, anchor, and convention you write into the generated skills must come from what you actually observed in the repo — not assumption. A domain skill that lists wrong paths is worse than none (it sends the harness to ground against fiction). When you genuinely can't tell, write a placeholder and flag it for the user rather than inventing.

**On a repo that already has context, read it first and reconcile.** Treat existing skills as the *map* and the live code as the *territory*; where they conflict, the code wins and you propose the fix. Never overwrite an existing file — any change to something that already exists (a skill, CLAUDE.md, an agent) is a *proposed edit* that waits for approval (per the user's overwrite rule); only brand-new files are created directly.

## Procedure

The flow is **analyze → plan → approve → write**. On a fresh repo it's mostly generation; on a repo that already has skills it's a reconcile. Nothing is written to an **existing** file until the user approves the plan — only brand-new files are created directly.

**Fast path (greenfield).** If `.claude/skills/` is empty and there is no root `CLAUDE.md`, there is nothing to reconcile: skip Steps 3–4 entirely (every file is new and additive, so no approval gate), do a light Step 1 explore just to fill the templates, write, and show the result. The reconcile machinery (Steps 3–4) exists only for repos that already carry context.

### Step 1 — Explore the repo AND inventory existing context (read-only)

Two read-only passes, no writing yet:

**A. The live code.** Spawn the **Explore** subagent (or Read/Grep for small repos) to learn: stack & languages (`package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`, `pubspec.yaml`, `docker-compose.yml`, framework signals like Next.js / FastAPI / Flutter), the real top-level shape (`frontend/`, `backend/`, `infra/`, `.github/workflows/`, …), conventions in the wild (naming, indentation, quote style, comment density, test framework — read a couple of representative files), and stated intent (README, docs/).

**B. The existing context.** Inventory what's already in `.claude/`: every `skills/*/SKILL.md`, the root `CLAUDE.md`, every `agents/*`. For each existing skill note which surface it covers, its **Ground-truth anchors**, and what it claims. Read them — do not touch. If existing skills use a naming **prefix** (e.g. `japass-`, `acme-`), record it; you will reuse it.

### Step 2 — Map domains from the code

From the live code, list the natural domain surfaces that actually exist — frontend / web / mobile / backend / infra / data / db / custom — only the ones present (one skill per real surface; defer ones not used yet as "load only when requested"). You now hold two lists: **surfaces-in-code** and **existing-skills**. Pick the skill **prefix**: reuse the existing one if the repo already has skills; otherwise derive a short, stable one from the repo name.

### Step 3 — Reconcile (the key step — read-only analysis)

Skip on a fresh repo (no existing skills — everything is simply "new"). Otherwise classify each surface by comparing the existing skill against the live code:

| Situation | Plan |
|---|---|
| Existing skill matches the code | **KEEP** — leave untouched |
| Existing skill but the code has drifted (stale paths, removed symbols, changed shape) | **UPDATE (propose)** — code wins; note exactly what's out of date |
| A code surface with no skill yet | **NEW** — generate a domain skill |
| A skill for a surface no longer in the code | **FLAG** — list it, do NOT delete; ask the user |

**Also reconcile the engine itself.** If `harness-engineering` already exists, diff its referenced `/slash-command` names and its template version marker (see Template A) against what the plugin currently ships. A reference to a renamed or removed skill (e.g. a stale `/vibe-coding`) is **UPDATE (propose)** — it is a dead link, fix it. Note if the engine's template version is behind the current one.

This step only decides; it writes nothing.

### Step 4 — Present the plan and get approval (gate before touching anything that exists)

Show one consolidated plan: the prefix; **KEEP** (list), **UPDATE** (list + what drifted), **NEW** (list), **FLAG** (list); plus the two engine pieces — whether `harness-engineering` and `CLAUDE.md` will be **created** (don't exist) or **proposed-as-edit** (already exist, e.g. fixing a stale reference or adding routing rows).

**Hard rule:** any change to a file that already exists (a skill, CLAUDE.md, an agent) is a *proposed edit* that waits for explicit approval — never a silent overwrite (matches the user's "overwrite needs approval" rule). Brand-new files are additive and may be created without a gate, but still appear in the plan.

### Step 5 — Write (after approval)

- **NEW domain skills** → write from Template C, with real anchors from Step 1 and the chosen prefix.
- **Local orchestrator** → if `harness-engineering` doesn't exist, write it from Template A with the Routing table pointing at the reconciled skill set; if it exists, apply only the approved routing edits. Fill its `<repo-name>`, the routing rows, the Phase-1 **project red lines** (only ones justified by the repo or stated by the user), and any custom agents from `.claude/agents/` as dispatch targets.
- **CLAUDE.md** → if absent, write a thin one from Template B (routing table = the reconciled skills); if present, apply only the approved merge — do not overwrite.
- **UPDATE skills** → apply the approved, targeted edits only (fix the stale anchors/claims) — never a full rewrite.
- **KEEP / FLAG** → leave untouched.

Creating or editing these files needs no git action. Do **not** commit — committing is an explicit-approval action under the user's hard rules. Mention they can commit via `/git-commit` once happy.

---

## Template A — project orchestrator (`.claude/skills/harness-engineering/SKILL.md`)

```markdown
---
name: harness-engineering
description: Orchestration entry point for <repo-name>. Use this skill at the START of any non-trivial feature request, change, or multi-step task ("帮我做…", "实现…", "加一个…", "改一下…", refactors, deploys, cross-file debugging). It runs a closed-loop workflow — intake guardrails, planning with a sprint contract, on-demand loading of the right domain skill(s), grounding context against live code, implementation, verification, and a quality/security gate. Routes to the <prefix>-* domain skills and reuses /code-review, /security-review, /verify, /run, /git-commit, /coding-standards, /dev-init.
---

<!-- harness-engineering template v0.4.0 — generated by harness-init; re-run harness-init to refresh -->

# harness-engineering — <repo-name> Orchestrator

The harness around long-running work in `<repo-name>`. Detailed domain context lives in the
domain skills, loaded on demand (progressive disclosure), so CLAUDE.md stays thin. This file
holds the workflow, the routing table, and the always-on guardrails.

Guiding idea: the harness is a first-class engineering artifact. Every phase encodes an
assumption about what the model should NOT do unsupervised — task scoping, self-evaluation,
irreversible actions. Prune steps that stop earning their keep.

**Ground before trust (load-bearing).** The domain skills are a *map* — intent, decisions, a
point-in-time snapshot of structure. The *code* is the territory. Paths/names/signatures in any
skill MAY be stale. Whenever a task depends on a specific piece of code, verify it against the
live repo before acting (Phase 4). If reality contradicts a skill, the **code wins** — proceed
on the code and fix the skill.

**Where the rules come from.**
- User global hard rules (always loaded from `~/.claude/CLAUDE.md`): any delete or git op needs
  explicit per-action approval; reply language; privacy paths.
- This repo's `CLAUDE.md`: the always-on section + the routing table (mirrored below).

## The closed loop

Run these phases in order. Do not skip the gate phases (6–8) on any change that touches code.

### Phase 1 — Intake (guardrail checklist)
One line each: (1) **Scope** — is the request aligned with this repo's goal / in-scope
constraints? If it drifts, STOP and flag. (2) **Open decisions** — does it touch a question
with >1 defensible answer? Present 2–3 options and WAIT. (3) **Irreversible** — git or
delete/overwrite? Mark "requires explicit approval" now (per-action). (4) **Project red lines** —
<list this repo's always-on red lines, or "none beyond the global rules">.

### Phase 2 — Plan (sprint contract)
Decompose into the smallest shippable slices (one feature per slice). Write 2–4 testable success
criteria. Confirm before coding when the design has >1 defensible answer.

### Phase 3 — Dispatch (load domain context on demand)
Load only the domain skill(s) the task hits (see Routing table). Don't pull all context for a
localized change. When unsure, load one and expand. If `.claude/agents/` has custom agents,
dispatch substantial sub-tasks to them.

### Phase 4 — Ground (verify context against live code)
Only when the task depends on specific code. Narrow ("changing this one file") → `Read` it first.
Broad ("where is X?") → spawn **Explore**, starting from the skill's Ground-truth anchors.
Uncertain a symbol exists → `Grep`. **Drift:** code wins — proceed on the code, note it, and
update the stale skill's SKILL.md (a doc fix, no approval needed; do NOT also commit it).
**Carve-out:** code wins for *descriptive* drift (paths, names, shapes); if the code contradicts a
stated red line or a locked decision, that is a finding to FLAG — do not silently rewrite the skill
to bless the violation.

### Phase 5 — Implement
Follow the repo's conventions (CLAUDE.md / domain skill / surrounding code). Match existing style.
Preserve architecture — no opportunistic refactors; propose those separately. Fall back to
`/coding-standards` defaults when conventions aren't stated.

### Phase 6 — Verify (separate generation from evaluation)
Don't let the context that wrote the code judge it done. Run `/verify` or `/run`, or the tests.
Report failures with output; never claim verified without running something.

### Phase 7 — Quality & Security gate
In order: `/code-review` (correctness + reuse) → `/security-review` (secrets discipline: mask all
but last 4, even at DEBUG) → if infra files changed, lint them (in a container, not host installs).
Re-confirm the Phase-1 red lines held in the actual diff. If `/code-review` or `/security-review`
does not resolve in this environment, STOP and report the gate was unavailable — never silently pass it.

### Phase 8 — Report & approval
Summarize what changed and what was verified (faithfully; skipped steps stated as skipped). For
anything marked irreversible in Phase 1, STOP and ask for explicit approval before executing.
Use `/git-commit` only after approval.

## When this loop applies
Single-file change with no new decisions and no Phase-1 red line / irreversible surface → just do it
(still under the global hard rules); don't run the full ceremony. Anything touching a red line or an
irreversible action → run Intake + the gate even if it looks trivial.

## Loop control (the loop is closed — use the back-edges)
- Verify (6) fails → return to Phase 5; if the failure implies stale assumptions, re-Ground (4) first.
- Gate (7) finds a correctness bug → fix it and re-run Phase 6 on the fix.
- Plan (2) or Ground (4) reveals the work materially exceeds the intake scope → STOP and re-run
  Phases 1–2 with the user before continuing.

## Routing table

| Task surface | Load skill | Examples |
|---|---|---|
| <surface 1> | **<prefix>-<surface1>** | <concrete examples> |
| <surface 2> | **<prefix>-<surface2>** | <concrete examples> |

Cross-cutting tasks load multiple. Custom agents available to dispatch: <list from
`.claude/agents/`, or "none">.

## What this skill does NOT do
It sequences existing skills (`/code-review`, `/security-review`, `/verify`, `/run`,
`/git-commit`, `/coding-standards`, `/dev-init`) — it does not reimplement them. Keep it an
orchestration contract; prune a phase if it stops adding value.
```

## Template B — project `CLAUDE.md` (thin)

```markdown
# CLAUDE.md

Thin context guide for `<repo-name>`. Holds only the **always-on hard rules** and a
**routing table**. Detailed domain context lives in on-demand skills under `.claude/skills/`
(progressive disclosure — loaded only when a task hits that surface).

**Start non-trivial work through the `harness-engineering` skill** — it runs the
intake → plan → dispatch → ground → implement → verify → gate → approve loop and routes to the
right domain skill(s).

## Routing table — where the detail lives

| Task surface | Load skill |
|---|---|
| <e.g. UI / components / streaming> | **<prefix>-frontend** |
| <e.g. API routes / services> | **<prefix>-backend** |
| <e.g. deploy / Docker / cloud> | **<prefix>-infra** |
| <e.g. data / pipelines> | **<prefix>-data** |
| <relational persistence — load only when DB work is requested> | **<prefix>-db** |

Reuse existing skills for the gate phase: `/code-review`, `/security-review`, `/verify`,
`/run`, `/git-commit`, `/coding-standards`, `/dev-init`.

## 1. What this repo is (one paragraph)

<one paragraph: what it does, who it's for, the current north star>

## 2. Always-on hard rules

- User global rules apply (delete / git ops need explicit per-action approval; reply language;
  privacy paths) — see `~/.claude/CLAUDE.md`; not re-pasted here.
- <project-specific always-on rules, only if justified — e.g. secrets discipline, a locked list,
  a "never fabricate X" red line, an architecture invariant>

## 3. Coding conventions (non-negotiable)

- <naming: snake_case (Python) / camelCase (TS) — match what the repo already does>
- <indentation, quote style, comment policy — match the surrounding code>
- <language rules — e.g. user-facing copy in X, code identifiers in English>

## 4. Open decisions — do NOT decide unilaterally

<list design questions with >1 defensible answer; propose 2–3 options and wait>

## 5. When in doubt

Ask. <name the few places where a wrong call compounds fastest for this repo.>
```

## Template C — domain skill (`.claude/skills/<prefix>-<surface>/SKILL.md`)

```markdown
---
name: <prefix>-<surface>
description: <Surface> domain context for <repo-name>. Load when working on
  <concrete triggers — files, features, subsystems>. Covers <the stack, the key
  abstractions, the locked decisions for this surface>.
---

# <prefix>-<surface>

> **Snapshot — verify before trusting.** Paths/symbols below are point-in-time. Per the
> `harness-engineering` Ground phase, Read/Grep the live file before editing or citing it; if it
> has drifted, the code wins — update this skill.
> **Ground-truth anchors:** <real entry-point paths: routes here · components there ·
> config here — the files a task on this surface will actually touch>

## <Stack / key facts (locked)>
<framework versions, the load-bearing decisions that shouldn't be reopened>

## <The main abstractions>
<the 2–5 things someone editing this surface must understand: the request flow, the
component shape, the deploy targets — whatever this surface's "shape" is>

## Conventions
<naming, indentation, quote style, comment policy observed here; what to preserve;
"propose refactors separately">

## <Surface-specific rules / gotchas>
<the traps unique to this surface — the thing a newcomer breaks first: an append-only
constraint, a multilingual contract, a paid-API cost gate, a render-order rule. Omit if none.>
```

## What this skill does NOT do

It does not lay down the directory tree, Docker, or devlog scaffold — that's `/dev-init`. It does not run the work loop — the generated `harness-engineering` does that. It only generates the per-project context layer (the local orchestrator + CLAUDE.md + domain skills) so the project is self-contained.
