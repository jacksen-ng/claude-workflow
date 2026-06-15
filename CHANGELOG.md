# Changelog

All notable changes to the `harness-kit` plugin. Format follows
[Keep a Changelog](https://keepachangelog.com/); this project uses semantic versioning,
and the `version` in `plugins/harness-kit/.claude-plugin/plugin.json` gates updates —
bump it whenever you add an entry here.

## [0.7.0] - 2026-06-15
### Added
- **Decompose phase (engine Phase 1.5).** Between Intake and the spec gate, the engine now turns a
  (possibly vague) requirement into a structured **impact map** BEFORE any doc is written: walk the
  touched surfaces, triage every dimension into known / inferable-from-code / must-ask, and let the
  must-ask set drive `/grill-me`. Cross-surface effects are first-class — existing-API contract
  changes, migrations and their effect on existing data, and state / shared-logic ripples are
  surfaced even when the user never mentioned them. The resolved impact map is the normalized
  requirement that seeds the whole doc set (UI → design.md, surfaces → implementation.md, blast
  radius → fallback.md).
- **`decomposition-rubric.md` reference** (new **Template H**), written next to the engine — a
  by-surface dimension checklist (Frontend/UX · Backend/API · Data/DB · Cross-cutting) used as a
  lens for finding unknowns, scaled to the change rather than filled as a form. Mirrored as
  `templates/decomposition-rubric.md.template`.
- **`requirement.md` gains an Impact-map section** (Template G) — the persisted, reviewable
  normalized requirement; the rest of the doc set expands from it.
### Changed
- Engine Phase 1's clarity gate now hands off to Phase 1.5; the loop one-liners and the engine
  description read recall → intake → decompose/grill → spec gate → … . Existing integer phase
  numbers are unchanged (Decompose slots in as 1.5), so the spec gate stays Phase 2 and the verify
  gates stay 6–7.
- Engine template marker bumped 0.6.0 → 0.7.0; standalone `templates/harness-engineering.SKILL.md.template`
  and `templates/CLAUDE.md.template` kept in sync with the canonical embedded Templates A/B.
- harness-init reconcile: a **v0.6.x engine** is an **UPDATE (propose)** — add Phase 1.5, write
  `decomposition-rubric.md`, and add the Impact-map section to `requirement.md`.

## [0.6.0] - 2026-06-12
### Added
- **Docs-driven development gate.** Engine Phase 2 is now a Spec phase: every development task —
  however small — writes a `docs/specs/<NNN>-<slug>/` doc set BEFORE any code (`requirement.md`,
  `implementation.md`, `testing.md`, `fallback.md`, plus `design.md` whenever UI/UX is touched;
  the docs scale down in length, never in count). The approved SET is the work's contract
  (one approval gate, not five); Phase 6 executes `testing.md` literally; a breaker trip
  executes `fallback.md` (written before implementation, while calm). New **Template G** stamps
  `docs/specs/README.md` + `_templates/` skeletons. Spec docs are the *intent map* — code
  contradicting an approved requirement is FLAGGED to the user, never blessed by editing the doc.
- **Learning loop (self-iteration).** New engine **Phase 0 (Recall)** reads a per-project
  `.claude/skills/harness-engineering/LESSONS.md` (new **Template E** — failure map with
  status / hits / surface fields, recall filtered by routing surface, 30-active cap); new
  **Phase 9 (Retrospect)** writes it on any verify failure, gate finding, ground drift, breaker
  trip, or user correction — deduped by root cause, never ritual entries. A lesson with
  `hits ≥ 2` is proposed (Tier 1) for promotion to a CLAUDE.md red line or a hook
  (lesson → rule → enforcement, the same path the install-guard took). Workflow-level lessons
  are mirrored to global auto-memory; project lessons travel with the repo.
- **Retrospect-guard Stop hook** (new **Template F**): Phases 6/7 append failures to
  `.claude/state/retrospect-queue.md`; a Stop hook blocks session end (once — honors
  `stop_hook_active`, can never loop) while the queue is non-empty, so "lessons are written
  automatically" is enforced mechanically, not by model goodwill. `.claude/state/` is
  gitignored harness-owned state.
- **Circuit breaker:** at most 3 self-correction cycles per slice, then STOP — report the full
  failure trail, propose the `fallback.md` rollback (each git/delete step still per-action
  approved), escalate as Tier 1; a trip always yields a lesson and a fallback.md review.
- **`/grill-me` bundled skill** (vendored from `mattpocock/skills`, MIT, with attribution),
  wired into engine Phase 1 as a **clarity gate**: a requirement that can't be written without
  guessing triggers an interview — ONE question at a time, each with a recommended answer;
  codebase-answerable questions are explored, not asked; low-stakes choices take the
  recommendation as recorded "delegated decisions". Mechanical exit (requirement.md writes
  itself / user says "按你推荐的来") — never endless interrogation.
- **Decision boundary** (CLAUDE.md Template B §4): Tier 1 = the user decides (direction/scope,
  spec-set approval, UI/UX in `design.md`, business-logic *semantics*, dependencies, every git
  action and delete, lesson promotion); Tier 2 = autonomous inside an approved spec
  (implementing approved slices, intent-restoring bug fixes, tests, doc/lesson updates).
  Ambiguous → Tier 1. The semantics line: restoring documented intent is Tier 2; changing
  intent is Tier 1.
### Changed
- **Git/delete approval codified as a dead rule:** per-action, no exceptions, never
  pre-approvable by any spec/contract/phase. Engine Phase 8 presents branch/commit/push as a
  batch *proposal* but executes each only on its own approval. (Autonomous feature-branch
  commits were considered during design and explicitly rejected by the user.)
- Engine template marker bumped 0.5.0 → 0.6.0. `templates/harness-engineering.SKILL.md.template`
  and `templates/CLAUDE.md.template` reconciled to the canonical embedded Templates A/B; the new
  Templates E/F/G live only embedded in `harness-init` (single source of truth, no new mirrors).
- `harness-init` Step 1 now also inventories `docs/` (an existing spec/RFC/ADR convention is
  reconciled with, not duplicated); Step 3 recognizes a v0.5.x engine as **UPDATE (propose)**
  listing the six v0.6.0 mechanism deltas, and treats an existing `LESSONS.md` / populated
  `docs/specs/` as project assets (KEEP entries, upgrade only the machinery). README gained an
  "Upgrading an existing project" section documenting re-run-`harness-init` as the upgrade path.

## [0.5.0] - 2026-06-03
### Added
- Supply-chain hardening against package hallucination / **slopsquatting** (attackers pre-register
  the package names LLMs are known to hallucinate). `coding-standards` §4 gains a **verify-before-add
  gate** (registry-existence → official-vs-look-alike → legitimacy signals, grounded against the live
  registry, never model memory) plus non-executing install defaults (npm `--ignore-scripts`, PyPI
  `--only-binary=:all:`), a locked-install preference (`npm ci` / `--require-hashes`), and a release
  cooldown note.
- Engine Phase 1 gains intake item **(5) New dependency**; Phase 7 gains a **dependency-provenance
  scan** step (Socket / OSV / `npm audit` / `pip-audit` if available, else registry-existence
  fallback — never a silent pass). CLAUDE.md template gains a dependency-provenance always-on red line.
- `harness-init` now stamps an **install-guard `PreToolUse` hook** into each bootstrapped project
  (new Template D: `.claude/hooks/install-guard.py` + a `.claude/settings.json` entry) — the doc rules
  guide the model, the hook intercepts the actual `npm/pip/...` install and asks the user to verify first.
### Changed
- Engine template marker bumped 0.4.0 → 0.5.0; standalone `templates/harness-engineering.SKILL.md.template`
  reconciled back up to canonical Template A (it had drifted — was missing the version marker, the
  Phase-4 red-line carve-out, "When this loop applies", "Loop control", and the Phase-7
  STOP-if-gate-unavailable clause).

## [0.4.0] - 2026-06-02
### Fixed
- `git-commit` had no YAML frontmatter, so it carried no description/triggers and could not
  auto-load on a commit request — added `name` + a trigger-rich `description`.
- `dev-init` frontmatter declared `name: scaffold` (with an H1 "Scaffold Skill") while the
  directory and every caller use `dev-init` — aligned the metadata.
- `git-commit`'s `change` type had a description copy-pasted from `docs`; rewrote it to its real
  meaning (behavioral/config/dependency change) and fixed the example to obey the skill's own rules.
### Changed
- Consolidated the engine/CLAUDE/domain templates to a single source of truth: the copies embedded
  in `harness-init` (Template A/B/C) are canonical, and the embedded B/C now carry the richer
  sections that had drifted into the standalone `templates/` files (Coding conventions, When in
  doubt, db routing row, surface-specific gotchas). The README Layout no longer points at the
  unshipped `templates/` directory.
- `coding-standards`: replaced the "Ethical Constraint Override" section (ineffective and risky on a
  public repo) with a positive "Legitimate Engineering Tasks" note, and made the Context7 dependency
  conditional + vendor-neutral with a no-fabricated-citations rule.
- Stamped engine (`harness-engineering`) is now actually a closed loop: added "Loop control"
  back-edges (Verify fail → re-implement, Gate bug → re-verify, scope blow-up → re-plan) and a
  "When this loop applies" escape hatch for trivial edits; the security gate now fails loud instead
  of silently passing when `/code-review` or `/security-review` is unavailable; the Ground rule gained
  a red-line carve-out (code wins for descriptive drift, but FLAG a real violation, don't bless it).
- Generated engines now carry a `<!-- harness-engineering template vX -->` version marker, and
  harness-init's reconcile diffs an existing engine's slash-references + version against what the
  plugin ships (catches stale links like a renamed skill). Added a greenfield fast-path that skips
  the reconcile/approval machinery on an empty repo.

## [0.3.0] - 2026-06-02
### Changed
- Renamed the `vibe-coding` skill to `coding-standards`. The old name was misleading: the
  skill is a conservative engineering contract (minimal invasiveness, solution-first,
  preserve existing architecture, mock-data-as-contract, comment/style discipline) — the
  opposite of casual "vibe coding". Updated every reference across the bootstrapper,
  templates, and manifests; `/vibe-coding` is now `/coding-standards`.

## [0.2.2] - 2026-06-01
### Changed
- `harness-init` now handles repos that already have skills: it inventories the existing
  `.claude/` context, reconciles it against the live code (KEEP / UPDATE / NEW / FLAG), and
  presents a plan for approval before writing. Existing skills are reused as routing targets;
  stale ones get proposed updates (code wins).
### Added
- Non-destructive guarantee: existing files are never overwritten — any change to something
  that already exists is a proposed edit that waits for approval; only brand-new files are
  created directly.

## [0.2.1] - 2026-06-01
### Fixed
- Invalid YAML in `harness-init` frontmatter — an unquoted `: ` (colon + space) in the
  `description` broke strict YAML parsers (e.g. GitHub's renderer). Fixed the same pattern
  in the bundled domain-skill template so generated skills stay valid.

## [0.2.0] - 2026-06-01
### Changed
- Engine is now **per-project**: `harness-init` stamps a local `harness-engineering`
  orchestrator into each repo (alongside `CLAUDE.md` + domain skills), so every project is
  self-contained instead of depending on a global engine.
### Added
- `templates/harness-engineering.SKILL.md.template` — the local orchestrator template.
### Removed
- The global `harness` orchestrator skill (each project now owns its own engine).

## [0.1.0] - 2026-06-01
### Added
- Initial `harness-kit` plugin and `jack-workflow` marketplace (single repo serving as both).
- Bundled skills: `harness` (generic orchestrator), `harness-init` (project bootstrapper),
  `dev-init`, `vibe-coding`, `git-commit`.
- `CLAUDE.md` and domain-skill templates.
