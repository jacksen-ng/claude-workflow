# Testing — Slash-command orchestration + delete-guard

Phase 6 runs this file top to bottom; results are recorded in `testresults.md`.
A criterion without a verification method is not a criterion.

## Slice 1 — /harness command
- [ ] `commands/harness.md` has valid frontmatter + body — verify via Read.
- [ ] After `/plugin marketplace update` + `/reload-plugins`, `/harness` appears in the command
      list — manual step.
- [ ] In a bootstrapped repo, `/harness "trivial change"` loads the local engine and reaches the
      Phase-2 approval pause — manual /verify scenario.
- [ ] In a non-bootstrapped repo, `/harness "x"` runs and prints the `/harness-init` recommendation
      — manual step.

## Slice 2 — db-guard
- [ ] `echo '{"tool_name":"Bash","tool_input":{"command":"psql -c \"DROP TABLE users\""}}' |
      python3 plugins/harness-kit/hooks/db-guard.py` → JSON with `permissionDecision: ask` — command.
- [ ] Destructive fixtures each → `ask`: `TRUNCATE foo`, `DELETE FROM users`, `alembic downgrade -1`,
      `prisma migrate reset`, `rm data.sqlite` — command (loop the fixtures).
- [ ] Benign commands → empty output, exit 0: `SELECT * FROM t`, `npm test`, `git status`,
      `rm build.log` — command.
- [ ] `hooks/hooks.json` is valid JSON and references `${CLAUDE_PLUGIN_ROOT}` —
      `python3 -c "import json;json.load(open('plugins/harness-kit/hooks/hooks.json'))"`.

## Slice 3 — testresults
- [ ] `_templates/testresults.md` skeleton exists in Template G and the spec `README.md` lists it as
      a Phase-6 output — Read.
- [ ] Both engine copies' Phase 6 mention writing `testresults.md` —
      `grep -rl "testresults.md" plugins/harness-kit/skills/harness-init/SKILL.md templates/`.

## Slice 4 — wiring
- [ ] "five-doc" occurrence count is unchanged (we intentionally did NOT rename) —
      `grep -rc "five-doc" README.md plugin.json marketplace.json` matches the pre-change baseline.
- [ ] README documents `/harness`, db-guard, and testresults — grep/Read.
- [ ] `plugin.json` version == `0.8.0` and is valid JSON — command.
- [ ] The two engine copies are still identical (extract embedded Template A from harness-init,
      diff against `templates/harness-engineering.SKILL.md.template`) — command; zero diff expected.
