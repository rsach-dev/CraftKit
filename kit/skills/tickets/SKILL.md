---
name: tickets
description: "Generates ticket descriptions from a structured requirements artifact. Reads artifacts/{TICKET}/1-requirements.md and produces copy-paste-ready ticket breakdowns with title, description, acceptance criteria, and size estimates, formatted for the ticket system configured in project.yaml (Jira, GitHub Issues, or Linear). Escalates to human when ticket boundaries or sizing are unclear."
---

# tickets — Generate Tickets from Requirements

## Overview

Breaks down a requirements artifact into individual tickets ready for
copy-paste into the team's ticket system. Will not produce tickets until there
is 100% confidence in the breakdown — escalates when ticket boundaries,
sizing, or dependencies are unclear.

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.
Phase name: `tickets`. Escalation file:
`artifacts/{TICKET}/escalations/tickets.md`.

## Usage

### Step 0 — Load project config

```bash
cat "./.craftkit-project/project.yaml"
```

Note `ticket.system` (jira | github | linear; default `jira`) — it determines
the output markup:
- **jira** — Jira wiki markup (`h3.`, `*`, `{code}`)
- **github** — GitHub-flavored markdown
- **linear** — plain markdown

### Step 1 — Identify the ticket

Ask the user for the ticket ID, or infer it if they reference an existing
artifact.

### Step 2 — Check for existing escalations

```bash
TICKET="PROJ-XXXX"
ESCALATION="./artifacts/$TICKET/escalations/tickets.md"
if [ -f "$ESCALATION" ]; then
  cat "$ESCALATION"
fi
```

If exists: check for `<!-- PENDING -->` markers → unanswered = STOP. All
answered → evaluate confidence → append new round or proceed.

### Step 3 — Read requirements

```bash
cat "./artifacts/$TICKET/1-requirements.md"
```

If missing or `status` is not `approved`, tell user to complete the
`requirements` skill first (including any pending escalations).

### Step 4 — Analyze and assess confidence

Plan the ticket breakdown. **Confidence gate** — escalate if any of these are
unclear:
- Can each ticket be independently merged and deployed?
- Are ticket boundaries clean (no circular dependencies)?
- Is there enough detail to estimate size?
- Are acceptance criteria clearly attributable to specific tickets?
- For tickets touching `ownership: external` modules: is the coordination
  model clear?

If not confident → write escalation file and STOP.

### Step 5 — Output tickets

Only reached when confidence is 100%.

Print each ticket in the configured system's markup:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TICKET 1 of N
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Title: {TICKET}: {concise title}

Description:
{formatted description}

Acceptance Criteria
- {criterion 1}
- {criterion 2}

Technical Notes
- Module: {module-name}
- Files: {key files to modify}

Estimate: {1/2/3/5/8}
Labels: {relevant labels}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 6 — Summary

Print:
- Total tickets: N
- Total estimate: X
- Escalation rounds completed: {N}
- Reminder: copy-paste into the ticket system

## Notes

- Match the markup to `ticket.system` — never emit GitHub markdown for Jira or
  vice versa
- If a ticket touches an `ownership: external` module, note the coordination
  requirement
