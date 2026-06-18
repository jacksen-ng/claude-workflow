# Fallback — Slash-command orchestration + delete-guard

Written before implementation, while calm. Executed (with per-action approvals) on a
circuit-breaker trip or a post-ship problem.

## Blast radius

Plugin-only change; no production system or live data is touched (this repo ships a dev tool).
Worst cases:
- A malformed `commands/harness.md` or hook file makes `/harness` or the hook error → an annoyance
  during a session, not data loss.
- db-guard **false-positives** and nags on benign commands (friction), or **false-negatives** and
  misses a destructive one — in which case the soft instruction layer (CLAUDE.md / engine) still
  applies as the backstop, so this degrades to today's behavior, not worse.

## Detection

- `/harness` missing from the command list, or erroring, after `/reload-plugins`.
- db-guard throwing (a hook error shown in-session), or not firing on a known `DROP` fixture.
- Engine-copy drift — the two engine templates diverge — caught by the Slice-4 diff check.

## Rollback procedure

1. Revert the feature branch / commit range (git action — **per-action approval**).
2. Or surgically: remove `plugins/harness-kit/commands/` and `plugins/harness-kit/hooks/`
   (delete — **per-action approval**) and revert the `plugin.json` version bump.
3. `/plugin marketplace update jack-workflow` → `/reload-plugins` to drop the bad version from the
   cache.
4. If only db-guard misbehaves but the command is fine → disable just the hook by removing its entry
   from `hooks/hooks.json` (a targeted edit, not a full rollback).

## Verified

- [ ] rollback step 3 (marketplace update + reload) rehearsed at least once
