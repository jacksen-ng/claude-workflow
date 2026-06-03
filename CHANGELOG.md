# Changelog

All notable changes to the `harness-kit` plugin. Format follows
[Keep a Changelog](https://keepachangelog.com/); this project uses semantic versioning,
and the `version` in `plugins/harness-kit/.claude-plugin/plugin.json` gates updates —
bump it whenever you add an entry here.

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
