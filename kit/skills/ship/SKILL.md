---
name: ship
description: "Commits any remaining changes from the implement skill, pushes a feature branch to the remote, and generates a pull request description. Uses the ticket ID as the commit/branch prefix. Outputs a formatted PR description with ticket link, change summary, API changes, testing notes, and additional context. Use after implement (and ideally review) completes successfully."
---

# ship — Commit, Push & PR Description

## Overview

Lean post-implementation skill. Commits any remaining changes, pushes the
branch to the remote, and generates a copy-paste-ready pull request
description. Never pushes to the default branch.

## Usage

### Step 0 — Load project config

```bash
cat "./.craftkit-project/project.yaml"
```

Note module paths, `ticket.commit_format`, and ownership.

### Step 1 — Identify ticket and read the plan

The user provides a ticket ID (e.g. `PROJ-1234`). Read the execution plan to
understand what was done:

```bash
TICKET="PROJ-XXXX"
cat "./artifacts/$TICKET/3-execution-plan.md"
```

### Step 2 — Determine impacted modules

From the execution plan, identify which team-owned modules were modified. For
each:

```bash
cd {module-path}
git status --short
git log --oneline {default-branch}..HEAD
```

If there are no changes (committed or uncommitted) in any module, tell the
user there's nothing to ship and stop. Never ship from an
`ownership: external` module.

### Step 3 — Create branch (if still on the default branch)

For each impacted module, ensure work is on a feature branch — never push
directly to the default branch:

```bash
cd {module-path}
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" = "{default-branch}" ]; then
  git checkout -b "feature/$TICKET"
fi
```

If the user is already on a non-default branch, use that branch as-is.

### Step 4 — Commit remaining changes

For each impacted module with uncommitted changes:

```bash
cd {module-path}
git add -A
git commit -m "{TICKET}: {brief description from execution plan title}"
```

### Step 5 — Push

```bash
cd {module-path}
git push -u origin "$(git branch --show-current)"
```

### Step 6 — Generate PR description

Read the execution plan and any available artifacts (requirements, tech spec,
review) to produce the PR description. Output it in a fenced code block the
user can copy-paste (or pass to `gh pr create` if the user asks):

````
```markdown
### Ticket
{TICKET}

### Summary
{2-4 sentences: what changed and why}

### Changes
- {change bullet per significant area}

### API Changes
{table or "None"}

### Testing
- {how it was verified — tests added, build results, review verdict}

### Notes for Reviewers
- {anything that needs special attention}
```
````

### Step 7 — Report

```
🚀 Shipped: {TICKET}
━━━━━━━━━━━━━━━━━━━━
Modules pushed:
  {module}: branch {branch} → origin
PR description: generated above (copy-paste ready)
```

## Rules

- **Never push to the default branch.** Always a feature branch.
- **Never push `ownership: external` modules.**
- Commit messages use `ticket.commit_format` from `project.yaml`.
- This skill does not modify code — if something is broken, route back to
  the feedback or implement skill.
