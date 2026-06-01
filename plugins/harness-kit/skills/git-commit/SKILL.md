# Git Commit Message Skill

## Overview
This skill provides guidelines for Jacksen's git commit message style - simple, concise, and practical.

## Commit Message Structure

```
<type>: <brief description>
```

**Key principle**: Keep it short and clear. No scope, no body, no footer needed.

## Commit Types (Jacksen's Style)

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature added | `feat: add Elasticsearch search` |
| `fix` | Bug fix or code correction | `fix: resolve login timeout issue` |
| `docs` | Documentation or file additions | `docs: add API documentation` |
| `change` | Documentation or file additions | change: requirement.txt |
| `delete` | Remove features or code | `delete: remove deprecated API endpoint` |
| `deploy` | Project deployment | `deploy: production release v1.2.0` |

## Message Guidelines

1. **Keep it brief**: Aim for under 50 characters total
2. **Use lowercase**: After the colon, start with lowercase
3. **Be specific but concise**: "add user search" not "add feature"
4. **No period at end**: Clean and simple
5. **Use imperative mood**: "add" not "added" or "adds"

## Good Examples

```
feat: add property search filter
fix: correct database query error
docs: update README installation steps
delete: remove old authentication code
deploy: staging environment v2.1.0
```

## Bad Examples

```
Added some stuff
fix bug
Update files.
feat: This commit adds a new feature that allows users to search for properties using various filters including price range, location, and property type
```

## Quick Decision Guide

**Adding something new?** → `feat:`
**Fixing broken code?** → `fix:`
**Adding/updating docs or files?** → `docs:`
**Removing code or features?** → `delete:`
**Deploying to server?** → `deploy:`

## Terminal Usage

Simple one-line commits:
```bash
git commit -m "feat: add search functionality"
git commit -m "fix: resolve timeout error"
git commit -m "delete: remove legacy code"
```

## Special Cases

### Multiple small changes
If multiple unrelated changes, make separate commits:
```bash
git add feature.js
git commit -m "feat: add new feature"

git add bug-fix.js  
git commit -m "fix: resolve bug"
```

### Work in progress
```bash
git commit -m "feat: WIP user profile"
```

### Deployment with version
```bash
git commit -m "deploy: production v1.2.3"
```

## Integration with Claude Code

When using Claude Code for commits:
- Tell it to follow "Jacksen's commit style" 
- Remind it: "keep it under 50 chars, simple format"
- It will use this skill automatically if placed in skills directory

Example Claude Code commands:
```bash
claude code "commit with proper message following my style"
claude code "review changes and create a short commit"
```

## Commit Frequency

- Commit often, small logical units
- Each commit should represent one clear change
- Better to have many small commits than one large one

## Review Checklist

Before committing:
- [ ] Is the type correct (feat/fix/docs/delete/deploy)?
- [ ] Is the message under 50 characters?
- [ ] Does it clearly describe what changed?
- [ ] Is it in imperative mood and lowercase after colon?

---

*Simple, clean, effective - that's the Jacksen style.*
