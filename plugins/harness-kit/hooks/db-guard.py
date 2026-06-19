#!/usr/bin/env python3
"""PreToolUse hook: gate destructive database operations (delete-safety guard).

Reads the PreToolUse JSON on stdin. If the Bash command contains a destructive DB operation
(DROP / TRUNCATE / DELETE FROM / a destructive migration verb / rm on a db file), returns an
"ask" decision so the user must confirm — enforcing the "all DB deletes need approval" dead rule
mechanically, not by model goodwill. Anything else passes through silently (exit 0, no output).

Conservative by design: it ASKS, never hard-denies (a legitimate op is one keystroke away), and
errs toward asking on ambiguous matches rather than silently passing a destructive one.
"""
import json, re, sys

# (label, pattern) — matched case-insensitively against the Bash command.
DESTRUCTIVE_PATTERNS = [
    ("DROP TABLE",          r"\bdrop\s+table\b"),
    ("DROP DATABASE/SCHEMA", r"\bdrop\s+(database|schema)\b"),
    ("TRUNCATE",            r"\btruncate\b"),
    ("DELETE FROM",         r"\bdelete\s+from\b"),
    ("prisma migrate reset", r"\bprisma\s+migrate\s+reset\b"),
    ("alembic downgrade",   r"\balembic\s+downgrade\b"),
    ("knex rollback",       r"\bknex\s+migrate:rollback\b"),
    ("sequelize undo",      r"\bsequelize\s+db:migrate:undo\b"),
    ("db:drop",             r"\bdb:drop\b"),
    ("migrate down",        r"\bmigrate[:\s]+down\b"),
    ("django flush",        r"\b(manage\.py|django-admin)\s+flush\b"),
    ("rm on db file",       r"\brm\b[^|;&]*\.(db|sqlite|sqlite3)\b"),
]

REASON_TMPL = (
    "🛡️ Destructive database operation detected ({op}). All DB deletes require explicit approval "
    "(dead rule from ~/.claude/CLAUDE.md). Confirm you intend to run this. If unsure, prefer a "
    "reversible path first — soft-delete, or take a backup before running."
)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        sys.exit(0)
    if data.get("tool_name") != "Bash":
        sys.exit(0)
    cmd = (data.get("tool_input") or {}).get("command", "") or ""
    for label, pat in DESTRUCTIVE_PATTERNS:
        if re.search(pat, cmd, re.IGNORECASE):
            print(json.dumps({"hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": REASON_TMPL.format(op=label),
            }}))
            return
    sys.exit(0)


if __name__ == "__main__":
    main()
