#!/usr/bin/env bash
# PreToolUse hook: gate destructive database operations (delete-safety guard).
#
# Bash port of db-guard.py. Reads the PreToolUse JSON on stdin. If the Bash command
# contains a destructive DB operation (DROP / TRUNCATE / DELETE FROM / a destructive
# migration verb / rm on a db file), emits an "ask" decision so the user must confirm —
# enforcing the "all DB deletes need approval" dead rule mechanically, not by model goodwill.
# Anything else passes through silently (exit 0, no output).
#
# Conservative by design: it ASKS, never hard-denies (a legitimate op is one keystroke away),
# and errs toward asking on ambiguous matches rather than silently passing a destructive one.
#
# Portability: targets macOS system bash 3.2 + BSD grep. POSIX ERE only — \b/\s are emulated
# by padding the command with spaces and matching a single non-word char [^[:alnum:]_] at each
# boundary (equivalent to \b for these keywords). jq parses the JSON in/out.
set -u

input=$(cat)

# fail-safe: jq is required to parse the input precisely. If it is missing we cannot read the
# command — ASK rather than silently pass (delete-safety > convenience).
if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"db-guard could not run (jq not found on PATH). Confirm this command is safe before running."}}'
  exit 0
fi

# only act on the Bash tool; bad/empty JSON -> jq yields empty -> pass (mirrors the py fail-open)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)
[ "$tool" = "Bash" ] || exit 0

cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || exit 0

# pad so a keyword at the very start/end still has a boundary char on each side
padded=" $cmd "
B='[^[:alnum:]_]'                       # one non-word char = a \b boundary
match() { printf '%s' "$padded" | grep -iEq "$1"; }

op=""
if   match "${B}drop[[:space:]]+table${B}";                      then op="DROP TABLE"
elif match "${B}drop[[:space:]]+(database|schema)${B}";          then op="DROP DATABASE/SCHEMA"
elif match "${B}truncate${B}";                                   then op="TRUNCATE"
elif match "${B}delete[[:space:]]+from${B}";                     then op="DELETE FROM"
elif match "${B}prisma[[:space:]]+migrate[[:space:]]+reset${B}"; then op="prisma migrate reset"
elif match "${B}alembic[[:space:]]+downgrade${B}";               then op="alembic downgrade"
elif match "${B}knex[[:space:]]+migrate:rollback${B}";           then op="knex rollback"
elif match "${B}sequelize[[:space:]]+db:migrate:undo${B}";       then op="sequelize undo"
elif match "${B}db:drop${B}";                                    then op="db:drop"
elif match "${B}migrate[:[:space:]]+down${B}";                   then op="migrate down"
elif match "${B}(manage\.py|django-admin)[[:space:]]+flush${B}"; then op="django flush"
elif match "${B}rm[^|;&]*\.(db|sqlite|sqlite3)${B}";             then op="rm on db file"
fi

[ -n "$op" ] || exit 0

reason="🛡️ Destructive database operation detected (${op}). All DB deletes require explicit approval (dead rule from ~/.claude/CLAUDE.md). Confirm you intend to run this. If unsure, prefer a reversible path first — soft-delete, or take a backup before running."

jq -nc --arg r "$reason" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
exit 0
