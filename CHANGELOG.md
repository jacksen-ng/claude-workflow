# Changelog

All notable changes to the `harness-kit` plugin. Format follows
[Keep a Changelog](https://keepachangelog.com/); this project uses semantic versioning,
and the `version` in `plugins/harness-kit/.claude-plugin/plugin.json` gates updates —
bump it whenever you add an entry here.

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
