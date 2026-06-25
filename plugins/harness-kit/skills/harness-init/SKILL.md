---
name: harness-init
description: Bootstrap a project to use the docs-driven harness workflow. Run ONCE in a repo (new or existing) when the user wants to "set up my workflow here", "初始化工作流", "scaffold CLAUDE.md and skills", or start a new project with their standard harness. It explores the repo to learn the real stack and structure, then generates the full context layer into the repo — (1) a project-local `harness-engineering` orchestrator skill (the closed-loop engine with recall/retrospect learning, self-contained) plus its LESSONS.md failure map and decomposition-rubric.md, (2) a thin CLAUDE.md (always-on rules + decision boundary + routing table), (3) one domain skill per natural surface (frontend / backend / infra / data / db / …) following the proven snapshot + ground-truth-anchors template, (4) spec-doc templates under docs/specs/ for the mandatory five-doc gate (requirement / design / implementation / testing / fallback), and (5) enforcement hooks (install-guard, retrospect-guard, a harness-entry router that forces new requirements through /harness, and a spec-gate that blocks code edits with no approved spec). If the repo already has skills, a CLAUDE.md, or docs, it first inventories and reconciles them against the live code — keeping what matches, proposing updates for what drifted, adding what is missing — instead of overwriting. Presents everything for review before finalizing. Complements `/dev-init` (file/folder scaffold) — this lays down the *context layer*, not the directory tree.
---

# Harness Init — Project Bootstrapper

One-shot setup that stamps the user's reusable workflow onto a repo. The goal: after running this, the repo is **self-contained** — it has its own local `harness-engineering` orchestrator that runs the docs-driven closed loop (spec gate → implement → verify → retrospect), learns from its own failures via LESSONS.md, and routes to thin per-domain skills, exactly like the user's mature projects, without depending on any global skill.

This is the **context layer** (a local orchestrator + LESSONS.md + decomposition rubric + CLAUDE.md + domain skills + spec-doc templates + four enforcement hooks). It complements `/dev-init`, which lays down the directory tree, Docker, and devlog scaffold. If the repo is greenfield with no structure yet, suggest running `/dev-init` first (or alongside).

**Key model:** the engine lives **in each project**, not globally. This plugin ships the *generator* (this skill) and the *templates* for the engine; running it drops a tailored `harness-engineering` into the repo. There is no global orchestrator — each project owns its own. (Two pieces *are* plugin-global and NOT stamped per-project: the `/harness` command — the deterministic entry that loads whatever local engine it finds — and the `db-guard` delete-safety hook. harness-init neither generates nor reconciles those.)

## Operating principle

**Generate from the live repo, not from a guess.** Every path, anchor, and convention you write into the generated skills must come from what you actually observed in the repo — not assumption. A domain skill that lists wrong paths is worse than none (it sends the harness to ground against fiction). When you genuinely can't tell, write a placeholder and flag it for the user rather than inventing.

**On a repo that already has context, read it first and reconcile.** Treat existing skills as the *map* and the live code as the *territory*; where they conflict, the code wins and you propose the fix. An existing `LESSONS.md` or `docs/specs/` content is a **project asset** — keep its entries, never regenerate them. Never overwrite an existing file — any change to something that already exists (a skill, CLAUDE.md, an agent, a doc) is a *proposed edit* that waits for approval (per the user's overwrite rule); only brand-new files are created directly.

## Procedure

The flow is **analyze → plan → approve → write**. On a fresh repo it's mostly generation; on a repo that already has skills it's a reconcile. Nothing is written to an **existing** file until the user approves the plan — only brand-new files are created directly.

**Fast path (greenfield).** If `.claude/skills/` is empty and there is no root `CLAUDE.md`, there is nothing to reconcile: skip Steps 3–4 entirely (every file is new and additive, so no approval gate), do a light Step 1 explore just to fill the templates, write all artifacts (Templates A–G), and show the result. The reconcile machinery (Steps 3–4) exists only for repos that already carry context.

### Step 1 — Explore the repo AND inventory existing context (read-only)

Two read-only passes, no writing yet:

**A. The live code.** Spawn the **Explore** subagent (or Read/Grep for small repos) to learn: stack & languages (`package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`, `pubspec.yaml`, `docker-compose.yml`, framework signals like Next.js / FastAPI / Flutter), the real top-level shape (`frontend/`, `backend/`, `infra/`, `.github/workflows/`, …), conventions in the wild (naming, indentation, quote style, comment density, test framework — read a couple of representative files), and stated intent (README, docs/).

**B. The existing context.** Inventory what's already in `.claude/`: every `skills/*/SKILL.md` (including a `LESSONS.md` next to an existing engine), the root `CLAUDE.md`, every `agents/*`, every `hooks/*`. Also inventory `docs/` — if the repo already runs an equivalent spec/RFC/ADR convention, note its structure; you will reconcile with it, not impose a duplicate. For each existing skill note which surface it covers, its **Ground-truth anchors**, and what it claims. Read them — do not touch. If existing skills use a naming **prefix** (e.g. `japass-`, `acme-`), record it; you will reuse it.

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

**Also reconcile the engine itself.** If `harness-engineering` already exists, diff its referenced `/slash-command` names and its template version marker (see Template A) against what the plugin currently ships. A reference to a renamed or removed skill (e.g. a stale `/vibe-coding`) is **UPDATE (propose)** — it is a dead link, fix it. A **v0.5.x or older engine** lacks the v0.6.0 mechanisms and is an **UPDATE (propose)** listing exactly these six deltas: the five-doc spec gate (Phase 2), the `/grill-me` clarity gate (Phase 1), Recall/Retrospect + LESSONS.md (Phases 0/9), the circuit breaker, the Decision boundary (CLAUDE.md §4), and the retrospect-guard hook. A **v0.6.x engine** additionally lacks the v0.7.0 **Phase 1.5 (Decompose)**: **UPDATE (propose)** — add the Decompose phase, write the new `decomposition-rubric.md` next to the engine, and add the **Impact map** section to `requirement.md`. A **v0.7.x engine** additionally lacks the v0.8.0 pieces: **UPDATE (propose)** — record test runs into `testresults.md` at Phase 6 (and stamp the new `_templates/testresults.md` skeleton), and name `/harness` as the primary entry in the engine description and the generated `CLAUDE.md` (skill auto-trigger stays a backstop). A project on the **v0.9.0** plugin additionally lacks the requirement-forcing enforcement hooks — regardless of engine marker, if `.claude/hooks/harness-entry.sh` (Template H) or `.claude/hooks/spec-gate.sh` (Template I) is absent, **UPDATE (propose)**: stamp it and merge its `UserPromptSubmit` / `PreToolUse` entry into `.claude/settings.json` (spec-gate is a second `PreToolUse` entry alongside install-guard; existing hooks are KEPT). The `/harness` command and the `db-guard` hook are plugin-global — they arrive via `/plugin marketplace update`, NOT via this per-project stamp. An existing `LESSONS.md` or populated `docs/specs/` is a project asset: **KEEP** its content; only the surrounding machinery is upgraded.

This step only decides; it writes nothing.

### Step 4 — Present the plan and get approval (gate before touching anything that exists)

Show one consolidated plan: the prefix; **KEEP** (list), **UPDATE** (list + what drifted), **NEW** (list), **FLAG** (list); plus the engine pieces — whether `harness-engineering`, `LESSONS.md`, `CLAUDE.md`, the spec layer, and the hooks will be **created** (don't exist) or **proposed-as-edit** (already exist, e.g. fixing a stale reference, adding routing rows, upgrading a v0.5.x engine).

**Hard rule:** any change to a file that already exists (a skill, CLAUDE.md, an agent, `.gitignore`, `settings.json`) is a *proposed edit* that waits for explicit approval — never a silent overwrite (matches the user's overwrite rule). Brand-new files are additive and may be created without a gate, but still appear in the plan.

### Step 5 — Write (after approval)

- **NEW domain skills** → write from Template C, with real anchors from Step 1 and the chosen prefix.
- **Local orchestrator** → if `harness-engineering` doesn't exist, write it from Template A with the Routing table pointing at the reconciled skill set; if it exists, apply only the approved edits. Fill its `<repo-name>`, the routing rows, the Phase-1 **project red lines** (only ones justified by the repo or stated by the user), and any custom agents from `.claude/agents/` as dispatch targets.
- **Decomposition rubric** → write `.claude/skills/harness-engineering/decomposition-rubric.md` from Template H (always — it's generic, not project-specific; Phase 1.5 reads it). If it already exists, leave it (a project may have refined it with new dimensions).
- **Failure map** → if `.claude/skills/harness-engineering/LESSONS.md` is absent, stamp the Template E skeleton. If present, it is a project asset — keep every entry; never regenerate.
- **CLAUDE.md** → if absent, write a thin one from Template B (routing table = the reconciled skills); if present, apply only the approved merge — do not overwrite.
- **Spec layer** → if `docs/specs/` is absent, stamp Template G (`docs/specs/README.md` + the `_templates/` skeletons). If the repo already has an equivalent spec convention, reconcile: reuse its structure, map it in the engine's Phase 2 wording, don't impose a duplicate.
- **Hooks** → write `.claude/hooks/install-guard.py` (Template D), `.claude/hooks/retrospect-guard.py` (Template F), `.claude/hooks/harness-entry.sh` (Template H), and `.claude/hooks/spec-gate.sh` (Template I); **merge** their `PreToolUse` / `Stop` / `UserPromptSubmit` entries into `.claude/settings.json` (merge into existing settings, never clobber — install-guard and spec-gate are two separate entries in the same `PreToolUse` array). Ensure `.claude/state/` is listed in `.gitignore` (appending to an existing `.gitignore` is a proposed edit). Skip any hook the project already has an equivalent of.
- **UPDATE skills** → apply the approved, targeted edits only (fix the stale anchors/claims) — never a full rewrite.
- **KEEP / FLAG** → leave untouched.

Creating or editing these files needs no git action. Do **not** commit — every git operation is a dead-rule, explicit-approval action under the user's hard rules. Mention they can commit via `/git-commit` once happy.

---

## Template A — project orchestrator (`.claude/skills/harness-engineering/SKILL.md`)

```markdown
---
name: harness-engineering
description: Orchestration entry point for <repo-name>. Normally invoked via the `/harness` command; also auto-triggers as a backstop at the START of any development task ("帮我做…", "实现…", "加一个…", "改一下…", refactors, deploys, cross-file debugging). It runs a docs-driven closed loop — recall lessons, intake guardrails, decompose the requirement into an impact map (grilling the gaps via /grill-me), a mandatory five-doc spec gate (requirement / design / implementation / testing / fallback), on-demand domain skill loading, grounding against live code, implementation, verification against testing.md, a quality/security gate, per-action git approval, and a retrospect that writes LESSONS.md. Routes to the <prefix>-* domain skills and reuses /grill-me, /code-review, /security-review, /verify, /run, /git-commit, /coding-standards, /dev-init.
---

<!-- harness-engineering template v0.8.0 — generated by harness-init; re-run harness-init to refresh -->

# harness-engineering — <repo-name> Orchestrator

The harness around development work in `<repo-name>`. Detailed domain context lives in the
domain skills, loaded on demand (progressive disclosure), so CLAUDE.md stays thin. This file
holds the workflow, the routing table, and the always-on guardrails.

Guiding idea: the harness is a first-class engineering artifact. Every phase encodes an
assumption about what the model should NOT do unsupervised — task scoping, self-evaluation,
irreversible actions. Prune steps that stop earning their keep.

**Three maps, three drift rules (load-bearing).**
- *Structure map* — the domain skills: paths / names / shapes, a point-in-time snapshot.
  Where it contradicts the live repo, the **code wins** — proceed on the code, fix the skill.
- *Failure map* — `LESSONS.md` (next to this file): the recorded mistakes. Phase 0 reads it,
  Phase 9 writes it. A lesson contradicted by live code → mark `status: stale`, verify, fix
  or expire.
- *Intent map* — `docs/specs/`: what the system is SUPPOSED to do. Here the rule inverts:
  code contradicting an approved `requirement.md` is a bug or an unapproved decision —
  **FLAG it to the user**; never rewrite the requirement to bless the code.

**Where the rules come from.**
- User global hard rules (`~/.claude/CLAUDE.md`) — **dead rules, never bypassed by any phase,
  spec, or approval below**: every git operation (branch, commit, push, merge, rebase, …) and
  every delete needs explicit PER-ACTION approval; reply language; privacy paths.
- This repo's `CLAUDE.md`: the always-on rules, the Decision boundary (§4), the routing table.
- **Supply chain:** never add or install a package without grounding it against the live registry
  first (slopsquatting guard — see `/coding-standards` §4); installing is an explicit-approval action.

## The closed loop

Run the phases in order. Do not skip the spec gate (2) or the verification gates (6–7) on any
change that touches code.

### Phase 0 — Recall (read lessons before planning)
Read `LESSONS.md` (same directory) if present. Cite the **active** lessons whose `surface`
overlaps this task — one line each, by ID ("Applying L-003: …"). None apply → say so and move
on. Do NOT paste the file into the plan; cite IDs. A lesson contradicted by the live code is
drift: code wins — mark it `status: stale` in Phase 9.

### Phase 1 — Intake (guardrail checklist)
One line each:
(1) **Scope** — aligned with this repo's goal / in-scope constraints? If it drifts, STOP and flag.
(2) **Tier classification** — walk the planned work against the Decision boundary (CLAUDE.md
§4). Tier-1 items → each pauses for the user when reached. Ambiguous → Tier 1.
(3) **Irreversible surface** — every git action and every delete is per-action approval (dead
rule); list the ones this task will need so the user sees them coming.
(4) **Project red lines** — <list this repo's always-on red lines, or "none beyond the global rules">.
(5) **New dependency** — does it add or bump a package (npm/PyPI)? Run the `/coding-standards`
§4 verify-before-add gate (exists in the registry · is the official package, not a look-alike ·
sane legitimacy signals) BEFORE it lands in any manifest. Installing is privileged and
effectively irreversible (lifecycle scripts run attacker code at install time) — per-action approval.
(6) **Clarity** — hand the requirement to Phase 1.5 (Decompose): it builds the impact map and
grills any gaps before the spec gate. Even a fully-specified requirement passes through for a
quick confirm; a vague one ("加个功能") is where Decompose earns its keep.

### Phase 1.5 — Decompose (build the impact map, grill the gaps)
Turn the (possibly vague) requirement into a structured **impact map** before any doc is written —
this is the normalized intent the rest of the loop runs on. Open `decomposition-rubric.md` (same
directory) and walk only the surfaces the requirement plausibly touches (skip the Data/DB block
entirely if no data layer is involved, etc.). Triage every dimension into one bucket:
- **known** — the user already stated it; record it.
- **inferable** — answerable from live code/specs; resolve by exploring (Read/Grep/Explore), not
  by asking; record the answer and where you found it.
- **must-ask** — genuinely changes what gets built and can't be inferred → it becomes a question.
The must-ask set is the agenda for `/grill-me`: ONE question at a time, each with your recommended
answer; low-stakes choices take the recommendation as a recorded **delegated decision**, never
silently. Cross-surface implications are first-class here — surface every existing-API contract
change, every migration and its effect on existing data, and every state-management or
shared-logic ripple, even when the user never mentioned them.
**Exit (mechanical):** the impact map has no open questions left — every dimension is known,
inferred, asked, or explicitly delegated. That resolved impact map IS the normalized requirement:
in Phase 2 it lands as the **Impact map** section of `requirement.md` and seeds the rest of the
set (UI dimensions → design.md, touched surfaces → implementation.md, blast radius → fallback.md).
Scope ballooning past what Intake framed → STOP, back to Phase 1.

### Phase 2 — Spec (docs ARE the contract — written BEFORE any code)
Create `docs/specs/<NNN>-<slug>/` from `docs/specs/_templates/` and draft the full set. The
set is **mandatory for every development task, however small** — sections may be short, files
may not be skipped (`design.md` only when the work touches UI/UX; the other four always):
1. `requirement.md` — what & why, in/out of scope, acceptance criteria (fed by Phase-1 answers)
2. `design.md` — UI/UX work only: flows, layout & states, copy. All user-visible UI choices
   are Tier 1 and are decided IN this doc, never improvised in code.
3. `implementation.md` — the slices (smallest shippable, one feature each), touched surfaces
   (→ Routing table), proposed branch name, the Tier-2 actions the spec authorizes
4. `testing.md` — per slice: 2–4 testable criteria + HOW each is verified (command / `/verify`
   scenario / manual step). Phase 6 executes THIS file.
5. `fallback.md` — written NOW, while calm: blast radius, detection signals, the concrete
   rollback procedure (revert range / flag off / redeploy previous / data reversal).
Present the SET for approval — one gate, not five. Approval authorizes the Tier-2 work in
Phases 3–7 (implementation edits, tests, doc updates). It does NOT pre-approve any git action
or delete — those stay per-action (dead rule). Scope growing beyond the approved spec → STOP,
back to Phases 1–2. Docs are written in English. Status: draft → approved → implemented → superseded.

### Phase 3 — Dispatch (load domain context on demand)
Load only the domain skill(s) the spec's slices hit (see Routing table). Don't pull all context
for a localized change. When unsure, load one and expand. If `.claude/agents/` has custom
agents, dispatch substantial sub-tasks to them.

### Phase 4 — Ground (verify context against live code)
Only when the task depends on specific code. Narrow ("changing this one file") → `Read` it first.
Broad ("where is X?") → spawn **Explore**, starting from the skill's Ground-truth anchors.
Uncertain a symbol exists → `Grep`. **Drift:** code wins — proceed on the code, note it, and
update the stale skill's SKILL.md (a doc fix, no approval needed; do NOT also commit it).
**Carve-outs:** code wins only for *descriptive* drift (paths, names, shapes). If the code
contradicts a stated red line, a locked decision, or an approved spec's `requirement.md` (the
intent map), that is a finding to FLAG — do not silently rewrite the skill or the spec to
bless the violation.

### Phase 5 — Implement
Implement `implementation.md`'s slices in order, following the repo's conventions (CLAUDE.md /
domain skill / surrounding code). Match existing style. Preserve architecture — no opportunistic
refactors; propose those separately. Fall back to `/coding-standards` defaults when conventions
aren't stated. Mid-flight deviation that keeps the approved intent (same requirement, different
mechanics) → note it in implementation.md's deviation log and continue. Deviation that changes
requirement/design **semantics** → STOP, Tier 1, re-approve before proceeding.

### Phase 6 — Verify (separate generation from evaluation)
Don't let the context that wrote the code judge it done. Run `testing.md` literally — every
criterion, by its stated method (a criterion without a method is not a criterion); check each
off in the doc as it passes. Record the run into `docs/specs/<NNN>-<slug>/testresults.md` (per
criterion: method, pass/fail, evidence). Report failures with output; never claim verified without running
something. On any failure, append one line `phase 6 | <slice> | <one-line symptom>` to
`.claude/state/retrospect-queue.md` (create if absent — harness-owned state, exempt from
approval rules, never committed), then take the back-edge (Loop control).

### Phase 7 — Quality & Security gate
In order: `/code-review` (correctness + reuse) → `/security-review` (secrets discipline: mask all
but last 4, even at DEBUG) → if infra files changed, lint them (in a container, not host installs).
If the diff added or changed any dependency (manifest or lockfile): confirm each NEW name (including
transitive ones the lockfile resolved) passed the §4 verify-before-add gate, and run a supply-chain
scanner if available (`socket`, `osv-scanner`, `npm audit`, `pip-audit`); no scanner → fall back to
the registry-existence + legitimacy check on the new names, never a silent pass.
Re-confirm the Phase-1 red lines held in the actual diff. If `/code-review` or `/security-review`
does not resolve in this environment, STOP and report the gate was unavailable — never silently
pass it. Any finding here → also append `phase 7 | <slice> | <one-line symptom>` to
`.claude/state/retrospect-queue.md` (arms the retrospect-guard).

### Phase 8 — Report & per-action git approvals
Summarize per slice: what changed, what `testing.md` verified (faithfully; skipped steps stated
as skipped), deviations logged, lessons queued. Then the git work — the dead rule applies and
the spec never pre-approved any of it: present the proposed branch / commit(s) in `/git-commit`
style / push as a batch FOR REVIEW, but EXECUTE each only on its own explicit approval, one
action at a time.

### Phase 9 — Retrospect (close the learning loop)
Trigger: this run had ANY of — a Verify failure, a Gate finding, a Ground drift, a breaker
trip, or a user correction ("不对 / 不是这样 / 改回去"). No trigger → skip the lesson step;
never write ritual entries. For each trigger: check `LESSONS.md` for an entry with the same
ROOT CAUSE — found → bump its `hits` and add the date; new → append an entry per the file's
embedded format (symptom → root cause → imperative rule). Any lesson reaching `hits ≥ 2` →
propose (Tier 1) promoting it to a CLAUDE.md red line or a hook; on acceptance mark it
`status: promoted`. A lesson that would apply in OTHER repos too (workflow-level, not
project-level) → also save it to global auto-memory. Then close the spec: flip its status
(`implemented`; partial → note what landed; abandoned → `superseded` + one line on why), and
clear `.claude/state/retrospect-queue.md`. Lesson/doc writes are plain file edits — no git
action is implied; committing them waits for Phase-8-style approval like everything else.

## When this loop applies
Every development task — however small — goes through the full five-doc spec gate and the loop;
the docs scale down in **length**, never in **count** (`design.md` only when UI/UX is touched).
The only exemption is work that changes no code at all (pure questions, explorations, reviews) —
no spec needed. The dead rules (git / delete per-action approval) apply always, even
mid-conversation, even outside the loop.

## Loop control (the loop is closed — use the back-edges)
- Verify (6) fails → return to Phase 5; if the failure implies stale assumptions, re-Ground (4) first.
- Gate (7) finds a correctness bug → fix it and re-run Phase 6 on the fix.
- **Circuit breaker** — at most **3** self-correction cycles per slice (a cycle = one
  5→6/7→back-to-5 round trip on the same failing criterion). On the 3rd consecutive failure
  STOP; do not start a 4th attempt. Report the full failure trail (per attempt — what was
  tried, why it failed, evidence) and propose executing this spec's `fallback.md` rollback
  procedure to return to the last green slice boundary (every rollback step that is a git
  action or delete waits for its own per-action approval — dead rule). Escalate as Tier 1.
  A breaker trip ALWAYS yields a Phase-9 lesson AND a fallback.md review (did the procedure
  actually work? fix it if not).
- Spec (2) or Ground (4) reveals the work materially exceeds the approved spec → STOP and
  re-run Phases 1–2 with the user before continuing.

## Routing table

| Task surface | Load skill | Examples |
|---|---|---|
| <surface 1> | **<prefix>-<surface1>** | <concrete examples> |
| <surface 2> | **<prefix>-<surface2>** | <concrete examples> |

Cross-cutting tasks load multiple. Custom agents available to dispatch: <list from
`.claude/agents/`, or "none">.

## What this skill does NOT do
It sequences existing skills (`/grill-me`, `/code-review`, `/security-review`, `/verify`,
`/run`, `/git-commit`, `/coding-standards`, `/dev-init`) — it does not reimplement them. It
never executes a git action or a delete on its own authority — those are dead-rule, per-action
user approvals. Keep it an orchestration contract; prune a phase if it stops adding value.
```

## Template B — project `CLAUDE.md` (thin)

```markdown
# CLAUDE.md

Thin context guide for `<repo-name>`. Holds only the **always-on hard rules**, the
**decision boundary**, and a **routing table**. Detailed domain context lives in on-demand
skills under `.claude/skills/` (progressive disclosure — loaded only when a task hits that
surface).

**Start every development task with the `/harness` command** — it runs the `harness-engineering`
docs-driven closed loop (recall → intake → decompose/grill → five-doc spec gate → dispatch →
ground → implement → verify → gate → per-action approvals → retrospect) and routes to the right
domain skill(s). (The skill also auto-triggers as a backstop if a task starts without `/harness`.)

## Routing table — where the detail lives

| Task surface | Load skill |
|---|---|
| <e.g. UI / components / streaming> | **<prefix>-frontend** |
| <e.g. API routes / services> | **<prefix>-backend** |
| <e.g. deploy / Docker / cloud> | **<prefix>-infra** |
| <e.g. data / pipelines> | **<prefix>-data** |
| <relational persistence — load only when DB work is requested> | **<prefix>-db** |

Reuse existing skills: `/grill-me` (requirement clarification), `/code-review`,
`/security-review`, `/verify`, `/run`, `/git-commit`, `/coding-standards`, `/dev-init`.

## 1. What this repo is (one paragraph)

<one paragraph: what it does, who it's for, the current north star>

## 2. Always-on hard rules

- **Dead rules from `~/.claude/CLAUDE.md` — never bypassed by any spec, phase, or prior
  approval:** every git operation (branch, commit, push, merge, …) and every delete needs
  explicit PER-ACTION approval; reply language follows the user; privacy paths are off-limits.
- **Docs-driven gate.** No development work starts before its `docs/specs/<NNN>-<slug>/` doc
  set exists and is approved (see harness-engineering Phase 2). Five docs, mandatory;
  `design.md` only when UI/UX is touched. Docs are written in English.
- **Dependency provenance.** Never add or install a package without grounding it against the
  live registry first (exists · official, not a look-alike · sane legitimacy signals) — see
  `/coding-standards` §4. Default installs to non-executing (npm `--ignore-scripts`, PyPI
  `--only-binary=:all:`); installing is an explicit-approval action.
- <project-specific always-on rules, only if justified — e.g. secrets discipline, a locked
  list, a "never fabricate X" red line, an architecture invariant>

## 3. Coding conventions (non-negotiable)

- <naming: snake_case (Python) / camelCase (TS) — match what the repo already does>
- <indentation, quote style, comment policy — match the surrounding code>
- <language rules — e.g. user-facing copy in X, code identifiers in English>

## 4. Decision boundary — who decides what

**Tier 1 — the user decides. Propose options (with a recommendation), then WAIT:**
- Direction / scope changes; anything that re-opens a locked decision
- Approving a spec doc set (Phase 2); any later change to an approved `requirement.md` /
  `design.md`'s **semantics**
- UI/UX choices visible to end users — decided in `design.md`, never improvised in code
- Business-logic **semantics** — changing what the system is *supposed* to do (a bug fix
  restoring documented/intended behavior is Tier 2; changing the intent is Tier 1)
- New or bumped dependencies (after the `/coding-standards` §4 verify-before-add gate)
- **Every git action and every delete — per-action, no exceptions, not pre-approvable by
  any spec or contract (dead rule from `~/.claude/CLAUDE.md`)**
- Promoting a lesson to a red line or a hook (Phase 9)
- Open design questions: <list the repo-specific ones with >1 defensible answer>

**Tier 2 — autonomous inside an approved spec:**
- Implementing the approved slices; bug fixes restoring intended behavior; tests
- Doc / skill / LESSONS.md updates that track approved intent (mechanics, not semantics);
  spec status flips in Phase 9
- Harness-owned state under `.claude/state/` (create / append / clear)

Ambiguous → Tier 1. No approved spec → no Tier-2 envelope; everything non-trivial waits.
Settled decisions are documented in their specs and skills — don't reopen them without cause.

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

## Template D — install-guard hook (`.claude/hooks/install-guard.py` + `.claude/settings.json`)

A `PreToolUse` hook is the *enforcement teeth* the doc rules lack: docs guide the model, but a hook
intercepts the actual `Bash` call. This one pauses any package-install command and asks the user to
confirm after verifying the package against the live registry (slopsquatting guard). It **asks**, it
does not hard-deny — legitimate installs are one keystroke away. Stamping it per-project keeps the
protection self-contained (it ships with the repo, so a teammate or CI run gets it too).

**1. Merge into `.claude/settings.json`** (merge — do not overwrite an existing `hooks` block):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"${CLAUDE_PROJECT_DIR}/.claude/hooks/install-guard.py\"",
            "timeout": 10,
            "statusMessage": "Checking package install…"
          }
        ]
      }
    ]
  }
}
```

**2. Write `.claude/hooks/install-guard.py`:**

```python
#!/usr/bin/env python3
"""PreToolUse hook: gate package-install commands (slopsquatting / supply-chain guard).

Reads the PreToolUse JSON on stdin. If the Bash command is a package install
(npm/pnpm/yarn/bun/pip/uv/poetry/npx…), returns an "ask" decision with a verify-first
reminder. Anything else passes through silently (exit 0, no output = defer to normal flow).
"""
import json, re, sys

INSTALL_PATTERNS = [
    r"\bnpm\s+(install|i|add)\b", r"\bpnpm\s+(install|add|i|dlx)\b",
    r"\byarn\s+add\b", r"\bbun\s+(install|add|a)\b", r"\bbunx\b",
    r"\bpip3?\s+install\b", r"\buv\s+(add|pip\s+install)\b",
    r"\bpoetry\s+add\b", r"\bnpx\s+\S", r"\bpnpm\s+dlx\b",
]
REASON = (
    "🛡️ Package-install command detected. Before approving, ground each NEW package "
    "against the live registry (slopsquatting guard):\n"
    "  • Exists?  npm view <pkg>  /  curl -fsS https://pypi.org/pypi/<pkg>/json  (404 = hallucination, do NOT install)\n"
    "  • Official, not a 1–2 char look-alike of a popular package?\n"
    "  • Sane signals: real source repo, named maintainers, age, non-trivial downloads?\n"
    "  • Prefer non-executing: npm --ignore-scripts / pip --only-binary=:all:"
)

def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    if data.get("tool_name") != "Bash":
        sys.exit(0)
    cmd = (data.get("tool_input") or {}).get("command", "") or ""
    if not any(re.search(p, cmd) for p in INSTALL_PATTERNS):
        sys.exit(0)
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "ask",
        "permissionDecisionReason": REASON,
    }}))

if __name__ == "__main__":
    main()
```

Settings reload live (no restart). `python3` is assumed present; if a project is Node-only, port the
same logic to a Node script and point `command` at it.

## Template E — failure map (`.claude/skills/harness-engineering/LESSONS.md`)

The per-project learning layer: Phase 0 reads it, Phase 9 writes it. Stamp the skeleton below
only if the file is absent — an existing LESSONS.md is a project asset, keep its entries.

```markdown
# LESSONS — <repo-name>

Self-maintained by the harness (Phase 0 reads, Phase 9 writes). Keep entries terse; the
`rule:` line is what Phase 0 applies — imperative and checkable.

**Hygiene (applied at every Phase 9):**
- Same root cause → bump `hits` on the existing entry; never duplicate.
- `hits ≥ 2` → propose promotion (Tier 1) to a CLAUDE.md red line or a hook → `status: promoted`.
- Cap: 30 `active` entries. At the cap, mark the oldest non-recurring entry `status: expired`
  (kept in the file; physically deleting lines is a delete → user approval).
- `status: stale` = contradicted by live code (set during Phase 0/4); verify, then fix or expire.

---

## L-001 — <imperative title, e.g. "Check pagination is 1-indexed in the X API">
- status: active            <!-- active | promoted | stale | expired -->
- hits: 1                   <!-- times this recurred or prevented a repeat -->
- dates: <YYYY-MM-DD>
- surface: <prefix>-<surface>   <!-- routing-table surface; Phase-0 recall filters on this -->
- symptom: <what was observed, one line>
- root cause: <why it actually happened, one line>
- rule: <the prevention rule Phase 0 should apply — one line, imperative>
```

## Template F — retrospect-guard hook (`.claude/hooks/retrospect-guard.py` + settings merge)

The teeth behind "lessons are written automatically": Phases 6/7 append failures to
`.claude/state/retrospect-queue.md`; Phase 9 clears it after writing lessons. This Stop hook
blocks session end (once — it honors `stop_hook_active`, so it can never loop) while the queue
is non-empty, pointing at the unprocessed failures. `.claude/state/` is harness-owned session
state: ensure it is gitignored, and creating/clearing it is exempt from approval rules.

**1. Merge into `.claude/settings.json`** (merge — do not overwrite an existing `hooks` block):

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "python3 \"${CLAUDE_PROJECT_DIR}/.claude/hooks/retrospect-guard.py\"",
            "timeout": 10,
            "statusMessage": "Checking retrospect queue…"
          }
        ]
      }
    ]
  }
}
```

**2. Write `.claude/hooks/retrospect-guard.py`:**

```python
#!/usr/bin/env python3
"""Stop hook: block session end while the retrospect queue is non-empty.

harness-engineering Phases 6/7 append failure lines to .claude/state/retrospect-queue.md;
Phase 9 writes the lessons and clears it. A non-empty queue at Stop means lessons were never
written — block once and point at them. Honors stop_hook_active so it can never loop.
"""
import json, os, sys

def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    if data.get("stop_hook_active"):
        sys.exit(0)
    queue = os.path.join(os.environ.get("CLAUDE_PROJECT_DIR", "."),
                         ".claude", "state", "retrospect-queue.md")
    try:
        with open(queue) as f:
            pending = [l.strip() for l in f if l.strip()]
    except FileNotFoundError:
        sys.exit(0)
    if not pending:
        sys.exit(0)
    print(json.dumps({
        "decision": "block",
        "reason": ("Retrospect pending — run harness-engineering Phase 9 before stopping. "
                   "Unprocessed failures:\n"
                   + "\n".join(f"  - {l}" for l in pending[:10])
                   + "\nWrite/update LESSONS.md entries, then clear "
                     ".claude/state/retrospect-queue.md."),
    }))

if __name__ == "__main__":
    main()
```

## Template H — harness-entry hook (`.claude/hooks/harness-entry.sh` + settings merge)

The teeth behind "every requirement enters the loop": a `UserPromptSubmit` hook runs on each prompt
and, when the input looks like real development work, injects a routing directive so a NEW requirement
is forced through `/harness` (the docs-driven loop) instead of being coded ad-hoc. It does **not**
classify intent itself — sh cannot read meaning. It does a cheap pre-filter (stays quiet on pure
questions and clearly trivial edits) and hands the new-requirement-vs-trivial-fix call to the model;
**ambiguous → injects (treat as a requirement)**. The injection is a reminder, not a hard block — the
hard "no code before an approved spec" floor is a separate `PreToolUse` spec-gate (not yet stamped).
This is the project's first **sh-native** hook (jq for JSON); install-guard/retrospect-guard are still
Python — port them to match when convenient.

**1. Merge into `.claude/settings.json`** (merge — do not overwrite an existing `hooks` block):

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/harness-entry.sh\"",
            "timeout": 10,
            "statusMessage": "Routing to harness…"
          }
        ]
      }
    ]
  }
}
```

**2. Write `.claude/hooks/harness-entry.sh`:**

```bash
#!/usr/bin/env bash
# UserPromptSubmit hook: route new requirements into the harness-engineering loop.
#
# Reads the UserPromptSubmit JSON on stdin and decides whether to INJECT a routing directive
# (stdout on exit 0 is appended to the prompt as context). It does NOT classify intent itself —
# sh cannot read meaning. It runs a cheap pre-filter (stay quiet on pure questions and clearly
# trivial edits) and, for anything that looks like real dev work, injects a rubric so the MODEL
# makes the new-requirement-vs-trivial-fix call. Ambiguous → inject (treat as a requirement).
#
# Portability: macOS system bash 3.2 + BSD grep, POSIX ERE only. jq reads the prompt; if jq is
# missing we inject anyway (over-reminding is safe; under-reminding silently loses the gate).
# CJK keywords are matched as raw substrings (ASCII word boundaries are unreliable across locales
# for multibyte text); ASCII keywords use a [^[:alnum:]_] boundary; question words only count at
# the START of a line (so "figure out why" / "the X is broken" are not misread as questions).
set -u

input=$(cat)
if command -v jq >/dev/null 2>&1; then
  prompt=$(printf '%s' "$input" | jq -r '.prompt // empty' 2>/dev/null)
else
  prompt=""
fi

inject() {
  cat <<'EOF'
[harness-entry] This input is in a harness-bootstrapped repo. Route it (you classify — sh cannot):
  • NEW requirement / feature / behavior change / non-trivial refactor → you MUST run /harness now
    (the docs-driven harness-engineering loop); do NOT edit code before the spec gate.
  • Genuinely trivial (typo, rename, comment, an obvious one-line bug fix) → proceed directly; say so.
  • Unsure → treat it as a requirement and run /harness.
  • Already inside the harness loop for this task → just continue; do not restart it.
Dead rules still apply: per-action approval for every git action and every delete.
EOF
}

[ -z "$prompt" ] && { inject; exit 0; }

padded=" $prompt "
B='[^[:alnum:]_]'
REQ_ASCII='(implement|build|create|add|design|refactor|rewrite|integrate|migrate|feature|requirement|endpoint)'
TRIV_ASCII='(typo|rename|lint|format|comment|wording|one-?line)'
REQ_CJK='新功能|新需求|需求|实现|新增|重构|重写|集成|功能|接口|做一个|做个|加一个|加个'
TRIV_CJK='错别字|重命名|改名|格式化|注释|文案|措辞|小修|小改|微调'
QUES_CJK='为什么|什么|怎么|如何|是不是|能不能|可以吗|吗|多少|哪些|哪个|哪里'

ascii() { printf '%s' "$padded" | grep -Eiq "${B}$1${B}"; }
cjk()   { printf '%s' "$prompt" | grep -Eq "$1"; }
is_question() {
  printf '%s' "$prompt" | grep -Eq '\?|？' && return 0
  printf '%s' "$prompt" | grep -Eiq '^[[:space:]]*(how|what|why|when|where|which|who|can|could|is|are|does|do|should)[[:space:]]' && return 0
  cjk "$QUES_CJK" && return 0
  return 1
}

if ascii "$REQ_ASCII" || cjk "$REQ_CJK"; then inject; exit 0; fi          # clear requirement → force
if ascii "$TRIV_ASCII" || cjk "$TRIV_CJK" || is_question; then exit 0; fi # trivial / pure question → quiet
inject; exit 0                                                            # ambiguous dev work → as requirement
```

`bash` + `jq` are assumed present (jq missing → it injects rather than failing open). The keyword
lists are meant to be tuned per project — add the repo's own vocabulary to `REQ_*` / `TRIV_*`.

## Template I — spec-gate hook (`.claude/hooks/spec-gate.sh` + settings merge)

The **hard floor** under Template H's reminder: a `PreToolUse` hook on `Edit`/`Write`/`MultiEdit`
that blocks code edits when no approved spec is in flight. Where Template H *reminds* the model to
route, this *stops* it from silently coding without a spec. It always allows edits to spec/doc/
machinery paths (you must be able to author the spec), and for any other (code) file it allows the
edit ONLY while a `docs/specs/*/requirement.md` has Status `approved` and not yet `implemented` (the
implementation window). Otherwise it returns **ask** — a genuinely trivial fix is one keystroke; a
new requirement is rejected and routed through `/harness`. (Tune the allowlist `case` arms to the
repo's layout; switch the decision from `ask` to a hard `deny` if you want zero code-without-spec.)

**1. Merge into `.claude/settings.json`** (merge — append to the existing `PreToolUse` array, do
not overwrite install-guard's entry):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "bash \"${CLAUDE_PROJECT_DIR}/.claude/hooks/spec-gate.sh\"",
            "timeout": 10,
            "statusMessage": "Checking spec gate…"
          }
        ]
      }
    ]
  }
}
```

**2. Write `.claude/hooks/spec-gate.sh`:**

```bash
#!/usr/bin/env bash
# PreToolUse hook: spec-gate — no production code before an approved spec (the hard floor).
#
# Fires on Edit/Write/MultiEdit. Always allows edits to spec/doc/machinery paths (you must be able
# to author the spec itself). For any other (code) path it allows the edit ONLY while a spec is in
# its implementation window — a docs/specs/*/requirement.md whose Status value is `approved` and not
# yet `implemented`. Otherwise it returns "ask": a trivial fix is one keystroke, a new requirement
# gets rejected and routed through /harness.
#
# Portability: macOS system bash 3.2 + BSD grep/sed, POSIX ERE only; jq reads the JSON. Fail closed:
# jq missing → ask rather than silently allow. NOTE: the Status line carries an enum comment
# (<!-- draft | approved | implemented | superseded -->) — strip it before reading the value.
set -u

input=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"spec-gate could not run (jq not found). Confirm this code edit is covered by an approved spec."}}'
  exit 0
fi

tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
case "$tool" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$file" ] || exit 0

# 1. Always allow authoring specs/docs + harness machinery.
case "$file" in
  */docs/specs/*|docs/specs/*) exit 0 ;;
  */.claude/*|.claude/*)       exit 0 ;;
  *.md|*.mdx|*.txt|*.rst)      exit 0 ;;
  */.gitignore|.gitignore|*/LICENSE|LICENSE) exit 0 ;;
esac

# 2. Code edit → allow only while a spec is in its implementation window (approved, not implemented).
proj="${CLAUDE_PROJECT_DIR:-.}"
active=""
for req in "$proj"/docs/specs/*/requirement.md; do
  [ -f "$req" ] || continue
  line=$(grep -iE '\*\*status:?\*\*' "$req" | head -1)
  val=$(printf '%s' "$line" | sed -E 's/<!--.*//')   # drop the enum comment, keep the real value
  printf '%s' "$val" | grep -iqw 'approved'    || continue
  printf '%s' "$val" | grep -iqw 'implemented' && continue
  active="$req"; break
done

[ -n "$active" ] && exit 0    # implementing an approved spec → allow

# 3. No active approved spec → ask.
reason="🚧 spec-gate: editing code ($file) but no approved spec is in its implementation window. New behavior needs an approved docs/specs/<NNN>/ set (harness Phase 2) — run /harness; the user approves before code. If this is a genuinely trivial fix (typo, rename, one-line bug), approve to proceed."
jq -nc --arg r "$reason" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
exit 0
```

Together, Templates H + I are the two-layer enforcement: H *routes* new requirements to `/harness`
(soft, model classifies), I *blocks* code that skipped the spec gate (hard, file-state checked).

## Template G — spec docs (`docs/specs/README.md` + `docs/specs/_templates/`)

The intent map. Stamp the README and the five skeletons below (one file each under
`_templates/`); every development task copies them into `docs/specs/<NNN>-<slug>/` at Phase 2.

**`docs/specs/README.md`:**

```markdown
# Specs — docs-driven development

Every development task in this repo starts with a spec under `docs/specs/<NNN>-<slug>/`
(NNN increments; slug is short kebab-case). The doc set is written BEFORE any code
(harness-engineering Phase 2) and approved as ONE set — that approval is the work's contract.

- **Mandatory files per task** — `requirement.md`, `implementation.md`, `testing.md`,
  `fallback.md`; plus `design.md` whenever the work touches UI/UX. Sections may be short;
  files may not be skipped.
- **Phase-6 output** — `testresults.md` is written during verification (Phase 6), recording the
  run of `testing.md`. It is the OUTPUT of testing, NOT one of the docs approved at the gate.
- **Lifecycle** — `draft` → `approved` (user gate) → `implemented` (flipped at Phase 9) →
  `superseded` (abandoned or replaced; one line on why).
- **Drift rule** — these docs are the *intent map*. Code found contradicting an approved
  `requirement.md` is a bug or an unapproved decision — flag it; never edit the requirement
  to match the code.
- Docs are written in English. Copy the skeletons from `_templates/`.
```

**`_templates/requirement.md`:**

```markdown
# Requirement — <feature>

- **Status:** draft <!-- draft | approved | implemented | superseded -->
- **Spec:** <NNN>-<slug>

## Problem / why now
<one paragraph>

## In scope
- <bullet>

## Out of scope
- <bullet — as load-bearing as in-scope>

## Impact map (decomposition — from Phase 1.5)
The normalized, de-vagued requirement: per touched surface, the resolved dimensions; cross-surface
effects called out explicitly. Untouched surfaces get a one-line "n/a".
- **Frontend/UX:** <resolved dimensions, or n/a>
- **Backend/API:** <…, incl. impact on existing APIs>
- **Data/DB:** <…, incl. migration + effect on existing data, or n/a>
- **Cross-cutting:** <deps / security / observability / rollout / blast radius>

## Acceptance criteria
1. <testable — these become testing.md's spine>

## Delegated decisions
<choices the user explicitly delegated during grilling, each with the recommendation taken>

## Open questions
<must be EMPTY before status can be approved>
```

**`_templates/design.md`** (only when the work touches UI/UX):

```markdown
# Design — <feature>

## Flows
<entry → steps → exit, per flow>

## Layout & states
<per screen/component — default / loading / empty / error>

## Copy
<user-facing text, language(s)>

## Decided by user
<the Tier-1 UI choices made here, one line each>
```

**`_templates/implementation.md`:**

```markdown
# Implementation — <feature>

- **Proposed branch:** <name — creating it is a git action, approved per-action at Phase 8>

## Slices
1. <smallest shippable slice → touched surface(s) → routing-table skill(s)>

## Authorized Tier-2 actions
<implementation edits, tests, doc updates — never git actions or deletes>

## Deviation log
<appended during Phase 5 — mechanics-only deviations that keep the approved intent>
```

**`_templates/testing.md`:**

```markdown
# Testing — <feature>

Phase 6 runs this file top to bottom. A criterion without a verification method is not a criterion.

## Slice 1 — <name>
- [ ] <criterion> — verify via <command / /verify scenario / manual step>
```

**`_templates/fallback.md`:**

```markdown
# Fallback — <feature>

Written BEFORE implementation, while calm. Executed (with per-action approvals) on a
circuit-breaker trip or a post-ship failure.

## Blast radius
<what breaks for whom if this goes wrong>

## Detection
<the signals that tell us it broke>

## Rollback procedure
1. <numbered, concrete — revert range / flag off / redeploy previous / data reversal.
   Every git action or delete in here still needs its own approval when executed.>

## Verified
- [ ] procedure actually executed or rehearsed at least once
```

**`_templates/testresults.md`** (a Phase-6 *output*, not part of the approval gate — written
during verification, not before code):

```markdown
# Test Results — <feature>

Written during Phase 6 (Verify): the record of running `testing.md`. This is the OUTPUT of
verification, not one of the docs approved at the spec gate.

- **Spec:** <NNN>-<slug>
- **Run date:** <YYYY-MM-DD>
- **Result:** <all passed | N failed>

## Per criterion
| Slice / criterion | Method | Result | Evidence |
|---|---|---|---|
| <criterion> | <command / /verify / manual step> | ✅ / ❌ | <output snippet or note> |

## Failures & follow-up
<for each ❌: symptom, suspected cause, the back-edge taken (re-Ground / re-Implement), and the
LESSONS.md entry queued. Empty if all passed.>
```

## Template H — decomposition rubric (`.claude/skills/harness-engineering/decomposition-rubric.md`)

The lens behind **Phase 1.5 (Decompose)**: a by-surface dimension checklist the engine walks to
turn a vague requirement into an impact map. It is generic — stamp it verbatim next to the engine
(not project-specific; a project refines it only as it learns new dimensions). Written always,
like the engine itself.

```markdown
# Decomposition Rubric — requirement → impact map

Used by `harness-engineering` **Phase 1.5 (Decompose)**. This is a *lens for finding what you
don't know*, not a form to fill exhaustively. Walk only the surfaces the requirement plausibly
touches; for each dimension, triage into **known** (the user stated it) / **inferable** (resolve
by reading the live code, not by asking) / **must-ask** (genuinely changes what's built AND can't
be inferred → becomes a `/grill-me` question). The filled result is the **impact map** — the
normalized requirement that becomes `requirement.md`'s Impact-map section and seeds the rest of
the doc set.

Keep it proportional: a one-line CSS tweak resolves most dimensions as "n/a" in a sentence; a
cross-stack feature genuinely exercises all four blocks. Raise a dimension as **must-ask** only
when its answer changes the build and can't be inferred — don't spend a question on a default.

## Frontend / UX  (only when UI is touched → also drives design.md)
- **Placement & entry** — where on the page/flow does it live; how is it reached?
- **Component strategy** — reuse an existing component or build new? which one?
- **Visual** — icon needed? colors/spacing from existing theme tokens (not ad-hoc values)?
- **States** — default / loading / empty / error each defined?
- **Copy & i18n** — exact user-facing text; which languages?
- **State management** — local vs shared/global; source of truth; persisted across reloads?
- **Purpose & success signal** — what is this for; how do we know it worked?
- **Ripple** — what existing UI/component/logic does it touch or risk breaking?

## Backend / API  (→ drives implementation.md slices)
- **New endpoints** — method, path, request/response shape, auth/authz.
- **Existing-API impact** — does any current contract change? breaking? needs versioning?
- **Business rules & validation** — the logic and its edge cases.
- **Errors & idempotency** — failure modes, retries, idempotency where it matters.
- **Performance & cost** — heavy queries, N+1, paid / third-party API calls and their cost.

## Data / DB  (skip the whole block if no data layer is touched)
- **Schema change** — new tables / columns / enums?
- **Migration?** — needed or not? plan BOTH forward and backward.
- **Existing-data impact** — backfill? default values? nullable? does it break in-flight rows?
- **Migration safety** — table locks, downtime, online vs offline, reversibility.
- **Indexes & constraints** — new indexes, foreign keys, uniqueness.

## Cross-cutting  (scan every time)
- **Dependencies** — any new package? → `/coding-standards` §4 verify-before-add gate (privileged).
- **Security** — authz, secrets, PII, input trust boundary.
- **Observability** — logs / metrics / traces needed to know it works in prod?
- **Rollout** — feature flag? phased? migration ordering vs deploy?
- **Blast radius** — what breaks for whom if this goes wrong? → seeds fallback.md.
```

## What this skill does NOT do

It does not lay down the directory tree, Docker, or devlog scaffold — that's `/dev-init`. It does not run the work loop — the generated `harness-engineering` does that. It does not clarify requirements — that's `/grill-me`, invoked by the engine's Phase 1. It only generates the per-project context layer (the local orchestrator + LESSONS.md + decomposition rubric + CLAUDE.md + domain skills + spec templates + hooks) so the project is self-contained.
