# Implementation — Slash-command orchestration + delete-guard

- **Proposed branch:** `feat/slash-command-orchestration` (creating it is a git action, approved
  per-action at Phase 8 — not pre-approved by this spec)

## Slices

### Slice 1 — `/harness` slash command (the front door)
- **NEW** `plugins/harness-kit/commands/harness.md`
  - Frontmatter: `description`, `argument-hint: <requirement text>`.
  - Body: take `$ARGUMENTS` as the requirement. If `.claude/skills/harness-engineering/SKILL.md`
    exists, **load it and follow Phases 0–9 exactly** (its routing table + project red lines +
    LESSONS.md are the source of truth). If it does not exist, run a **compact generic loop**
    (recall → intake → decompose/grill → five-doc spec gate → implement → verify → gate →
    per-action approvals → retrospect) and recommend `/harness-init`. Empty `$ARGUMENTS` → ask for
    the requirement instead of running.
  - The command does **not** re-specify phase internals beyond the compact fallback — the engine
    file stays the single source of truth.
- Effect: plugin-global command (available after install), drives the per-project engine.

### Slice 2 — DB delete-guard (PreToolUse, plugin-global)
- **NEW** `plugins/harness-kit/hooks/db-guard.py` — stdlib `python3` only; reads the PreToolUse JSON
  on stdin; if `tool_name == "Bash"` and the command matches the destructive-DB set, emit
  `permissionDecision: ask` with the matched op + target in the reason; otherwise `exit 0` silently.
  Mirror `install-guard.py`'s shape and tone.
  - **Matcher set (conservative — ask, never hard-deny):** `DROP (TABLE|DATABASE|SCHEMA)`,
    `TRUNCATE`, `DELETE FROM`, destructive migration verbs (`db:drop`, `prisma migrate reset`,
    `alembic downgrade`, `knex migrate:rollback`, `sequelize db:migrate:undo`, `… migrate … down`,
    `manage.py flush`), and `rm` targeting `*.db|*.sqlite|*.sqlite3`. Case-insensitive.
- **NEW** `plugins/harness-kit/hooks/hooks.json` — plugin hook manifest registering a `PreToolUse`
  `Bash` matcher → `db-guard.py` via `${CLAUDE_PLUGIN_ROOT}`. (Confirm exact plugin-hook JSON shape
  against live docs during Phase 4 before writing.)

### Slice 3 — `testresults.md` (Phase-6 output, not a gate doc)
- harness-init **Template G**: add a `_templates/testresults.md` skeleton, and list it in the spec
  `README.md` as a **Phase-6 output** (explicitly NOT one of the pre-approval five docs).
- Engine **Phase 6**, in **BOTH** copies (`harness-init` embedded Template A **and**
  `templates/harness-engineering.SKILL.md.template`): add "record the run into
  `docs/specs/<NNN>-<slug>/testresults.md` — criterion, method, pass/fail, evidence."
- Leave all "five-doc spec gate" wording unchanged — testresults is an output artifact.

### Slice 4 — wire & document
- Engine `description` (both copies): name `/harness` as the **primary** entry; keep
  "Use this skill at the START…" as an auto-trigger **backstop**.
- CLAUDE.md template (**Template B** + `templates/CLAUDE.md.template`): "Start every development task
  with `/harness` — it runs `harness-engineering`."
- `harness-init` `description` + Step notes: mention the plugin-global `/harness` command and the
  db-guard so the reconcile path does not try to stamp them per-project.
- `README.md`: add `commands/` and plugin-level `hooks/` to the architecture; document `/harness`,
  the deterministic entry, db-guard, and testresults.
- `plugins/harness-kit/.claude-plugin/plugin.json`: version `0.7.0 → 0.8.0`; description mentions the
  command + delete-guard.
- `.claude-plugin/marketplace.json`: description mention.
- `CHANGELOG.md`: add the v0.8.0 entry.

## Authorized Tier-2 actions

File creation/edits under `plugins/`, `templates/`, `README.md`, `CHANGELOG.md`, `plugin.json`,
`marketplace.json`, and `docs/specs/001-*`. **Not** git actions; **not** deletes.

## Deviation log

(appended during Phase 5 — mechanics-only deviations that keep the approved intent)
