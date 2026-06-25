# CLAUDE.md

Thin context guide for `claude-workflow` — the **source repo of the `harness-kit` plugin** and
its `jack-workflow` marketplace. This is the *meta* repo: it ships the workflow that other repos
consume. It is **not** itself a bootstrapped consumer (no local `harness-engineering` engine here),
but it follows the same docs-driven discipline via `docs/specs/`.

This file holds only the **always-on hard rules**, the **decision boundary**, and a **pointer
table**. Deeper context lives in `README.md`, `CHANGELOG.md`, and the spec sets under `docs/specs/`.

---

## Where the detail lives

| You need… | Look in |
|---|---|
| What the plugin is / architecture diagram | `README.md` |
| What shipped in each version + rationale | `CHANGELOG.md` |
| The bootstrapper + all stamped templates (A–G) | `plugins/harness-kit/skills/harness-init/SKILL.md` |
| The per-project engine (canonical copy) | `templates/harness-engineering.SKILL.md.template` |
| Intent map for a change (five-doc spec) | `docs/specs/<NNN>-<slug>/` (001 done · 002 draft) |
| Plugin-global hook(s) | `plugins/harness-kit/hooks/` |

Reuse existing skills: `/grill-me` (requirement clarification), `/code-review`,
`/security-review`, `/verify`, `/git-commit`, `/coding-standards`.

---

## 1. What this repo is (one paragraph)

A personal Claude Code workflow packaged as a plugin (`harness-kit`) and distributed through this
repo's own marketplace. The plugin's core idea: the closed-loop **engine lives in each project**,
not globally — `harness-init` explores a target repo and stamps a self-contained
`harness-engineering` orchestrator + thin `CLAUDE.md` + domain skills + spec templates + enforcement
hooks into it. This repo is where that generator and its templates are authored, versioned, and
released. Changes here ripple to every project that later runs `/plugin marketplace update`.

---

## 2. Always-on hard rules

- **Dead rules from `~/.claude/CLAUDE.md` — never bypassed by any spec, phase, or prior approval:**
  every git operation (branch, commit, push, merge, reset, …) and every delete needs explicit
  PER-ACTION approval; batching *proposals* is fine, execution is one approval per action. Reply
  language follows the user (Chinese by default). Privacy paths are off-limits.
- **Docs-driven gate.** No non-trivial change starts before its `docs/specs/<NNN>-<slug>/` set
  exists and is approved: requirement / implementation / testing / fallback are mandatory,
  `design.md` only when a UI/UX surface is touched. Docs are written in **English**.
- **Dependency provenance.** Never add or install a package without grounding it against the live
  registry first (exists · official, not a look-alike · sane signals) — slopsquatting guard. The
  global install-guard hook enforces this; do not work around it.

## 2a. Repo-specific invariants (this is plugin source — these break consumers if violated)

- **Hooks are POSIX shell, not Python.** Every plugin hook is `bash` + `jq` (read the PreToolUse /
  Stop JSON from stdin via `jq`; emit decisions as JSON). Target **macOS system bash 3.2 + BSD
  grep**: no `\b` / `\s` (use `[[:space:]]` and pad the string with spaces + `[^[:alnum:]_]` to
  emulate a word boundary), no bash-4 features. A guard hook MUST **fail closed** — if a dependency
  (e.g. `jq`) is missing it ASKS/denies, never silently passes. Reference: `hooks/db-guard.sh`.
  > Known follow-up: the per-project templates **D (install-guard)** and **F (retrospect-guard)** in
  > `harness-init/SKILL.md` are still Python. Converting them to sh is pending; do it before claiming
  > "all hooks are sh."
- **The engine has two byte-identical copies.** `templates/harness-engineering.SKILL.md.template`
  and the **Template A** block embedded in `harness-init/SKILL.md` must stay identical — any engine
  edit touches BOTH, and a diff check is part of testing. Never edit one alone.
- **Release discipline is atomic.** A version bump updates `plugins/harness-kit/.claude-plugin/
  plugin.json`, `.claude-plugin/marketplace.json` (description), and adds a `CHANGELOG.md` entry —
  together, in the same change. Current plugin version: **0.8.0**.
- **`docs/specs/00N` are records.** Past spec sets document what was true at the time; don't rewrite
  history to reflect a later change — add a new spec / CHANGELOG entry instead.

---

## 3. Conventions

- Hooks: `bash` (`#!/usr/bin/env bash`), POSIX ERE, `jq` for JSON. Markdown/docs: English, terse.
- Templates stamped into other repos use `${CLAUDE_PROJECT_DIR}`; plugin-global hooks use
  `${CLAUDE_PLUGIN_ROOT}`. Don't cross them.
- Commit messages: `/git-commit` style — short, single-line, conventional `<type>` prefix.

---

## 4. Decision boundary — who decides what

**Tier 1 — the user decides. Propose options (with a recommendation), then WAIT:**
- Direction / scope changes; reopening a locked decision; approving a spec doc set
- Changing the engine's *contract* (phase numbering, the spec gate, the dead rules)
- New or bumped dependencies (after the verify-before-add gate)
- A version bump / release; editing the marketplace manifest
- **Every git action and every delete — per-action, no exceptions, not pre-approvable**

**Tier 2 — autonomous inside an approved spec:**
- Implementing approved slices; template/doc edits that track approved intent (mechanics, not
  semantics); keeping the two engine copies in sync; spec status flips at retrospect

Ambiguous → Tier 1. No approved spec → no Tier-2 envelope; non-trivial work waits.

---

## 5. When in doubt

Ask. The fastest-compounding mistakes here: editing only one of the two engine copies; weakening a
dead-rule / approval-gate wording; or shipping a hook that fails *open*. When unsure, stop and surface it.
