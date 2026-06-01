---
name: harness-init
description: Bootstrap a project to use the generic `harness` workflow. Run ONCE in a repo (new or existing) when the user wants to "set up my workflow here", "初始化工作流", "scaffold CLAUDE.md and skills", or start a new project with their standard harness. It explores the repo to learn the real stack and structure, then generates a thin project CLAUDE.md (always-on rules + routing table) and one domain skill per natural surface (frontend / backend / infra / data / db / …), each following the proven snapshot + ground-truth-anchors template, and wires them to the `harness` orchestrator. Presents everything for review before finalizing. Complements `/dev-init` (file/folder scaffold) — this lays down the *context layer*, not the directory tree.
---

# Harness Init — Project Bootstrapper

One-shot setup that ports the user's reusable workflow onto a repo. The goal: after running this, opening any non-trivial task in the repo flows through the global `harness` orchestrator, which routes to thin per-domain skills you generated here — the same closed-loop architecture the user runs on their mature projects, without rebuilding it by hand.

This is the **context layer** (CLAUDE.md + domain skills). It is complementary to `/dev-init`, which lays down the directory tree, Docker, and devlog scaffold. If the repo is greenfield and has no structure yet, suggest running `/dev-init` first (or alongside).

## Operating principle

**Generate from the live repo, not from a guess.** Every path, anchor, and convention you write into the generated skills must come from what you actually observed in the repo — not from assumption. A domain skill that lists wrong paths is worse than none (it sends the harness to ground against fiction). When you genuinely can't tell, write a placeholder and flag it for the user rather than inventing.

## Procedure

### Step 1 — Explore the repo (read-only)

Build an accurate picture before writing anything. Spawn the **Explore** subagent (or Read/Grep directly for small repos) to determine:

- **Stack & languages** — `package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`, `Cargo.toml`, `docker-compose.yml`, lockfiles, framework signals (Next.js, FastAPI, etc.).
- **Top-level shape** — the real first- and second-level directories (`frontend/`, `backend/`, `infra/`, `.github/workflows/`, `scripts/`, …).
- **Existing context** — is there already a `CLAUDE.md`? a `.claude/skills/`? Don't clobber; merge or report.
- **Conventions in the wild** — indentation, naming (snake_case vs camelCase), quote style, comment density, test framework. Read a couple of representative files.
- **Stated intent** — README, docs/, any design notes that say what the project is *for*.

### Step 2 — Map domains

From what you observed, propose the **natural domain surfaces** for this repo — only the ones that actually exist. Typical surfaces:

| Surface | Generate a skill when the repo has… |
|---|---|
| frontend | a UI app (Next.js/React/Vue/…), `frontend/` or app routes |
| backend | an API/service layer (FastAPI/Express/…), routes, business logic |
| infra / cloud | deploy workflows, IaC, Dockerfiles, cloud config |
| data | scrapers, pipelines, datasets, analyzers |
| db | schema, migrations, ORM models (only if relational state exists) |
| (custom) | any other coherent surface the repo clearly has |

Pick a short, stable **prefix** for the project's skills (e.g. repo `acme-shop` → `acme-frontend`, `acme-backend`). One skill per real surface — do not generate empty skills for surfaces the repo doesn't have. Deferred surfaces (e.g. a DB that isn't used yet) get a "load only when actually requested" skill, mirroring how mature projects defer them.

### Step 3 — Generate the thin CLAUDE.md

Write `CLAUDE.md` at repo root using the template below. Keep it **thin** — always-on hard rules + routing table + a one-paragraph "what this repo is". Detail goes in the domain skills (progressive disclosure). Inherit the user's global hard rules by reference (don't re-paste them); add only project-specific always-on rules you can justify from the repo or that the user states.

If a `CLAUDE.md` already exists, do NOT overwrite — show a proposed merge and ask.

### Step 4 — Generate the domain skills

For each mapped domain, write `.claude/skills/<prefix>-<surface>/SKILL.md` from the domain-skill template below. Fill:
- a precise `description` (when to load this skill),
- the **snapshot warning** header + **Ground-truth anchors** list (real paths you found),
- the domain context you actually learned,
- the conventions observed (or inherited).

### Step 5 — Review gate (do not finalize silently)

Present a summary: the proposed prefix, the domains, the CLAUDE.md, and each skill — for the user to review and correct **before** treating them as canonical. This is durable context infra; a wrong anchor compounds. Apply their corrections.

Writing/creating these files needs no git action. Do **not** commit — committing is a Phase-8 / explicit-approval action under the user's hard rules. Mention they can commit via `/git-commit` once happy.

---

## Template — project `CLAUDE.md` (thin)

```markdown
# CLAUDE.md

Thin context guide for `<repo-name>`. Holds only the **always-on hard rules** and a
**routing table**. Detailed domain context lives in on-demand skills under
`.claude/skills/` (progressive disclosure — loaded only when a task hits that surface).

**Start non-trivial work through the `harness` skill** — it runs the
intake → plan → dispatch → ground → implement → verify → gate → approve loop and
routes to the right domain skill(s).

## Routing table — where the detail lives

| Task surface | Load skill |
|---|---|
| <e.g. UI / components / streaming> | **<prefix>-frontend** |
| <e.g. API routes / services> | **<prefix>-backend** |
| <e.g. deploy / Docker / cloud> | **<prefix>-infra** |
| <e.g. data / pipelines> | **<prefix>-data** |

Reuse existing skills for the gate phase: `/code-review`, `/security-review`,
`/verify`, `/run`, `/git-commit`, `/vibe-coding`, `/dev-init`.

## 1. What this repo is (one paragraph)

<one paragraph: what it does, who it's for, the current north star>

## 2. Always-on hard rules

- User global rules apply (delete / git ops need explicit per-action approval; reply
  language; privacy paths) — see `~/.claude/CLAUDE.md`; not re-pasted here.
- <project-specific always-on rules, only if justified — e.g. secrets discipline,
  a locked list, a "never fabricate X" red line, an architecture invariant>

## 3. Open decisions — do NOT decide unilaterally

<list design questions with >1 defensible answer; propose 2–3 options and wait>
```

## Template — domain skill (`.claude/skills/<prefix>-<surface>/SKILL.md`)

```markdown
---
name: <prefix>-<surface>
description: <Surface> domain context for <repo-name>. Load when working on
  <concrete triggers: files, features, subsystems>. Covers <the stack, the key
  abstractions, the locked decisions for this surface>.
---

# <prefix>-<surface>

> **Snapshot — verify before trusting.** Paths/symbols below are point-in-time. Per the
> `harness` Ground phase, Read/Grep the live file before editing or citing it; if it has
> drifted, the code wins — update this skill.
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

It does not lay down the directory tree, Docker, or devlog scaffold — that's `/dev-init`. It does not run the work loop — that's `harness`. It only generates the per-project context layer (CLAUDE.md + domain skills) so `harness` has a map to route through.
