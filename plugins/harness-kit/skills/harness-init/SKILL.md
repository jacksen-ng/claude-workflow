---
name: harness-init
description: Bootstrap a project to use the harness workflow. Run ONCE in a repo (new or existing) when the user wants to "set up my workflow here", "初始化工作流", "scaffold CLAUDE.md and skills", or start a new project with their standard harness. It explores the repo to learn the real stack and structure, then generates THREE things into the repo — (1) a project-local `harness-engineering` orchestrator skill (the closed-loop engine, self-contained), (2) a thin CLAUDE.md (always-on rules + routing table), and (3) one domain skill per natural surface (frontend / backend / infra / data / db / …) following the proven snapshot + ground-truth-anchors template. Presents everything for review before finalizing. Complements `/dev-init` (file/folder scaffold) — this lays down the *context layer*, not the directory tree.
---

# Harness Init — Project Bootstrapper

One-shot setup that stamps the user's reusable workflow onto a repo. The goal: after running this, the repo is **self-contained** — it has its own local `harness-engineering` orchestrator that runs the closed loop and routes to thin per-domain skills, exactly like the user's mature projects, without depending on any global skill.

This is the **context layer** (a local orchestrator + CLAUDE.md + domain skills). It complements `/dev-init`, which lays down the directory tree, Docker, and devlog scaffold. If the repo is greenfield with no structure yet, suggest running `/dev-init` first (or alongside).

**Key model:** the engine lives **in each project**, not globally. This plugin ships the *generator* (this skill) and the *template* for the engine; running it drops a tailored `harness-engineering` into the repo. There is no global orchestrator — each project owns its own.

## Operating principle

**Generate from the live repo, not from a guess.** Every path, anchor, and convention you write into the generated skills must come from what you actually observed in the repo — not assumption. A domain skill that lists wrong paths is worse than none (it sends the harness to ground against fiction). When you genuinely can't tell, write a placeholder and flag it for the user rather than inventing.

## Procedure

### Step 1 — Explore the repo (read-only)

Build an accurate picture before writing anything. Spawn the **Explore** subagent (or Read/Grep directly for small repos) to determine:

- **Stack & languages** — `package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`, `pubspec.yaml`, `docker-compose.yml`, lockfiles, framework signals (Next.js, FastAPI, Flutter, etc.).
- **Top-level shape** — the real first- and second-level directories (`frontend/`, `backend/`, `infra/`, `.github/workflows/`, `scripts/`, …).
- **Existing context** — is there already a `CLAUDE.md`? a `.claude/skills/`? `.claude/agents/`? Don't clobber; merge or report.
- **Conventions in the wild** — indentation, naming (snake_case vs camelCase), quote style, comment density, test framework. Read a couple of representative files.
- **Stated intent** — README, docs/, any design notes that say what the project is *for*.

### Step 2 — Map domains

From what you observed, propose the **natural domain surfaces** for this repo — only the ones that actually exist. Typical surfaces:

| Surface | Generate a skill when the repo has… |
|---|---|
| frontend / web | a UI app (Next.js/React/Vue/…), `frontend/` or app routes |
| mobile | Flutter / React Native / native app |
| backend | an API/service layer (FastAPI/Express/…), routes, business logic |
| infra / cloud | deploy workflows, IaC, Dockerfiles, cloud config |
| data | scrapers, pipelines, datasets, analyzers |
| db | schema, migrations, ORM models (only if relational state exists) |
| (custom) | any other coherent surface the repo clearly has |

Pick a short, stable **prefix** for the project's skills (e.g. repo `acme-shop` → `acme-frontend`, `acme-backend`). One skill per real surface — do not generate empty skills for surfaces the repo doesn't have. Deferred surfaces (e.g. a DB not used yet) get a "load only when actually requested" skill, mirroring how mature projects defer them.

### Step 3 — Generate the project-local orchestrator (`harness-engineering`)

Write `.claude/skills/harness-engineering/SKILL.md` from the **orchestrator template** below (Template A). This is the engine — copy it mostly verbatim, then fill the project-specific parts:
- the `<repo-name>` references,
- the **Routing table** rows — one per domain you mapped in Step 2, with concrete examples,
- any **project red lines** for the Phase-1 intake (only ones justified by the repo or stated by the user),
- if the repo has `.claude/agents/`, list those custom agents as dispatch targets.

The generic loop mechanics (the 8 phases, ground-before-trust, the gate) stay the same across projects — that's the reusable engine. Only the routing and red lines are project-specific.

### Step 4 — Generate the thin CLAUDE.md

Write `CLAUDE.md` at repo root using Template B. Keep it **thin** — it points to `harness-engineering` as the entry point, mirrors the routing table, holds always-on hard rules, and a one-paragraph "what this repo is". Detail goes in the domain skills. Inherit the user's global hard rules by reference (don't re-paste). If a `CLAUDE.md` already exists, do NOT overwrite — show a proposed merge and ask.

### Step 5 — Generate the domain skills

For each mapped domain, write `.claude/skills/<prefix>-<surface>/SKILL.md` from Template C. Fill: a precise `description` (when to load), the **snapshot warning** header + **Ground-truth anchors** (real paths you found), the domain context you actually learned, the conventions observed.

### Step 6 — Review gate (do not finalize silently)

Present a summary: the prefix, the domains, the orchestrator, the CLAUDE.md, and each skill — for the user to review and correct **before** treating them as canonical. This is durable context infra; a wrong anchor compounds. Apply their corrections.

Writing/creating these files needs no git action. Do **not** commit — committing is an explicit-approval action under the user's hard rules. Mention they can commit via `/git-commit` once happy.

---

## Template A — project orchestrator (`.claude/skills/harness-engineering/SKILL.md`)

```markdown
---
name: harness-engineering
description: Orchestration entry point for <repo-name>. Use this skill at the START of any non-trivial feature request, change, or multi-step task ("帮我做…", "实现…", "加一个…", "改一下…", refactors, deploys, cross-file debugging). It runs a closed-loop workflow — intake guardrails, planning with a sprint contract, on-demand loading of the right domain skill(s), grounding context against live code, implementation, verification, and a quality/security gate. Routes to the <prefix>-* domain skills and reuses /code-review, /security-review, /verify, /run, /git-commit, /vibe-coding, /dev-init.
---

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

### Phase 5 — Implement
Follow the repo's conventions (CLAUDE.md / domain skill / surrounding code). Match existing style.
Preserve architecture — no opportunistic refactors; propose those separately. Fall back to
`/vibe-coding` defaults when conventions aren't stated.

### Phase 6 — Verify (separate generation from evaluation)
Don't let the context that wrote the code judge it done. Run `/verify` or `/run`, or the tests.
Report failures with output; never claim verified without running something.

### Phase 7 — Quality & Security gate
In order: `/code-review` (correctness + reuse) → `/security-review` (secrets discipline: mask all
but last 4, even at DEBUG) → if infra files changed, lint them (in a container, not host installs).
Re-confirm the Phase-1 red lines held in the actual diff.

### Phase 8 — Report & approval
Summarize what changed and what was verified (faithfully; skipped steps stated as skipped). For
anything marked irreversible in Phase 1, STOP and ask for explicit approval before executing.
Use `/git-commit` only after approval.

## Routing table

| Task surface | Load skill | Examples |
|---|---|---|
| <surface 1> | **<prefix>-<surface1>** | <concrete examples> |
| <surface 2> | **<prefix>-<surface2>** | <concrete examples> |

Cross-cutting tasks load multiple. Custom agents available to dispatch: <list from
`.claude/agents/`, or "none">.

## What this skill does NOT do
It sequences existing skills (`/code-review`, `/security-review`, `/verify`, `/run`,
`/git-commit`, `/vibe-coding`, `/dev-init`) — it does not reimplement them. Keep it an
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

Reuse existing skills for the gate phase: `/code-review`, `/security-review`, `/verify`,
`/run`, `/git-commit`, `/vibe-coding`, `/dev-init`.

## 1. What this repo is (one paragraph)

<one paragraph: what it does, who it's for, the current north star>

## 2. Always-on hard rules

- User global rules apply (delete / git ops need explicit per-action approval; reply language;
  privacy paths) — see `~/.claude/CLAUDE.md`; not re-pasted here.
- <project-specific always-on rules, only if justified — e.g. secrets discipline, a locked list,
  a "never fabricate X" red line, an architecture invariant>

## 3. Open decisions — do NOT decide unilaterally

<list design questions with >1 defensible answer; propose 2–3 options and wait>
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
```

## What this skill does NOT do

It does not lay down the directory tree, Docker, or devlog scaffold — that's `/dev-init`. It does not run the work loop — the generated `harness-engineering` does that. It only generates the per-project context layer (the local orchestrator + CLAUDE.md + domain skills) so the project is self-contained.
