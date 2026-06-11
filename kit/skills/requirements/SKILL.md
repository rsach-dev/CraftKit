---
name: requirements
description: "Builds structured requirements from raw feature descriptions, meeting notes, or chat threads. Reads the project module registry for landscape context. Produces a numbered requirements artifact at artifacts/{TICKET}/1-requirements.md with problem statement, acceptance criteria, scope, impacted modules, and dependencies. Escalates to human when confidence is below 100%."
---

# requirements — Build Structured Requirements

## Overview

Transforms raw feature descriptions into a structured requirements document
that feeds downstream skills. Will not produce the artifact until there is
100% confidence in the content — escalates to human via a structured
escalation file when clarification is needed.

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.
Phase name: `requirements`. Escalation file:
`artifacts/{TICKET}/escalations/requirements.md`.

## Usage

### Step 0 — Load project config

```bash
cat "./.craftkit-project/project.yaml"
```

Note the ticket prefixes, artifact dir, and module registry.

### Step 1 — Get ticket ID

Ask the user for the ticket ID (using a prefix from `ticket.prefixes`, e.g.
`PROJ-1234`). If not provided, ask before proceeding.

### Step 2 — Check for existing escalations

```bash
TICKET="PROJ-XXXX"
ESCALATION="./artifacts/$TICKET/escalations/requirements.md"
if [ -f "$ESCALATION" ]; then
  cat "$ESCALATION"
fi
```

If the file exists:
1. Check for any `<!-- PENDING -->` markers — if found, tell user which questions are unanswered and STOP
2. Read all answers from all rounds
3. Evaluate: do the answers give 100% confidence? If not, append a new `## Round N` with follow-up questions and STOP
4. If confident, update frontmatter `status: resolved` and proceed to Step 5

### Step 3 — Read workspace context

```bash
cat "./.craftkit-project/context/workspace.md"
```

Use the module registry to understand what modules exist and their ownership.

### Step 4 — Analyze and assess confidence

From the user's input (description, chat thread, meeting notes, etc.):
1. Identify the core problem being solved
2. Extract explicit and implicit acceptance criteria
3. Determine which modules are likely impacted
4. Identify any ambiguities, gaps, or assumptions

**Confidence gate:** Can you write every section of the requirements artifact
with 100% certainty? If NO on any of these, escalate:
- Problem statement is clear and unambiguous
- Each acceptance criterion is testable and specific
- Scope boundaries are well-defined
- Impacted modules are confidently identified
- No business rules are assumed without evidence

If not confident → write escalation file and STOP:

```bash
mkdir -p "./artifacts/$TICKET/escalations"
```

Write `artifacts/{TICKET}/escalations/requirements.md` following the format in
the escalation protocol. Print:
```
⚠ Escalation: {N} questions need your input
→ artifacts/{TICKET}/escalations/requirements.md

Fill in answers and re-run this skill.
```
**STOP. Do not produce the requirements artifact.**

### Step 5 — Write the requirements artifact

Only reached when confidence is 100%.

```bash
mkdir -p "./artifacts/$TICKET"
```

Write `artifacts/{TICKET}/1-requirements.md`:

```markdown
---
ticket: {TICKET}
title: {concise title}
date: {YYYY-MM-DD}
status: approved
---
# Requirements: {title}

## Problem Statement

{What problem does this solve? Why is it needed? 2-4 sentences max.}

## Acceptance Criteria

1. {Testable criterion}
2. {Testable criterion}
...

## Scope

### In Scope
- {bullet list}

### Out of Scope
- {bullet list}

## Impacted Modules

| Module | Ownership | Nature of Impact |
|--------|-----------|-----------------|
| {name} | team/external | {brief description} |

## Dependencies

- {Other teams, services, APIs, or data sources this depends on}
```

Note: No "Open Questions" section. All questions were resolved via escalation
before this artifact was produced.

### Step 6 — Report

Print:
- Artifact path: `artifacts/{TICKET}/1-requirements.md`
- Status: **approved** (all ambiguities resolved)
- Summary: ticket ID, title, number of acceptance criteria, impacted modules
- Escalation rounds completed: {N} (or 0 if none needed)
- Next step: run the `tech-spec` skill, or `tickets` to generate ticket text
