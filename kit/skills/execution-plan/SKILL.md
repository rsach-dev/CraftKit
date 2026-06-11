---
name: execution-plan
description: "Builds a step-by-step execution plan from a tech spec artifact. Produces artifacts/{TICKET}/3-execution-plan.md with ordered implementation steps, file-level changes, testing checklist, and assumptions. Falls back to requirements if no tech spec exists. Escalates when step ordering, file scope, or test strategy has gaps."
---

# execution-plan — Build Execution Plan

## Overview

Converts a tech spec (or requirements) into an ordered, step-by-step
implementation plan. Each step maps to specific file changes. Will not produce
the plan until there is 100% confidence — escalates when step boundaries, file
scope, or test strategy are unclear.

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.
Phase name: `execution-plan`. Escalation file:
`artifacts/{TICKET}/escalations/execution-plan.md`.

## Usage

### Step 0 — Load project config

```bash
cat "./.craftkit-project/project.yaml"
```

### Step 1 — Check for existing escalations

```bash
TICKET="PROJ-XXXX"
ESCALATION="./artifacts/$TICKET/escalations/execution-plan.md"
if [ -f "$ESCALATION" ]; then
  cat "$ESCALATION"
fi
```

If exists: check `<!-- PENDING -->` → unanswered = STOP. All answered →
evaluate → append new round or proceed.

### Step 2 — Read inputs

```bash
# Prefer tech spec, fall back to requirements
if [ -f "./artifacts/$TICKET/2-tech-spec.md" ]; then
  cat "./artifacts/$TICKET/2-tech-spec.md"
else
  cat "./artifacts/$TICKET/1-requirements.md"
fi
```

Input artifact must have `status: approved`. If not, tell user to complete
the upstream skill first.

### Step 3 — Load module profiles

```bash
cat "./.craftkit-project/context/profiles/{module-name}.md"
```

### Step 4 — Refresh code (pre-flight)

For each impacted module, pull the latest code before validating paths (see
the tech-spec skill's pre-flight for the pattern). If the checkout is dirty,
tell user to commit/stash changes first. Abort if inconsistent.

### Step 5 — Validate file paths

For each file in the tech spec, verify it exists (modify/delete) or its parent
dir exists (create):

```bash
ls -la {module-path}/path/to/file
```

Correct any wrong paths.

### Step 6 — Assess confidence

**Confidence gate** — escalate if any of these are unclear:
- Can every step be described with exact file paths and specific changes?
- Is step ordering unambiguous (no circular dependencies)?
- Are test requirements clear for each change?
- Are there files in the tech spec that don't exist or have moved?
- For modify actions: is the current file state understood well enough to
  describe the diff?

If not confident → write escalation file and STOP.

### Step 7 — Write execution plan

Only reached when confidence is 100%.

Write `artifacts/{TICKET}/3-execution-plan.md`:

```markdown
---
ticket: {TICKET}
title: {title}
date: {YYYY-MM-DD}
status: approved
---
# Execution Plan: {title}

## Summary

{1-2 sentences}

## Files Changed

```
{module-path}/
├── src/.../
│   ├── file_one          ← modify
│   └── new_file          ← create
└── test/.../
    └── file_one_test     ← modify
```

## Steps

### Step 1: {short description}
- **File:** `{path/to/file}`
- **Action:** create | modify | delete
- **Detail:** {Specific changes — field names, function signatures, logic.
  Enough for the implement skill to execute without ambiguity.}

### Step 2: ...

{Order steps along the dependency direction of the stack — data models →
persistence → business logic → interface layer → tests.}

## Testing Checklist

- [ ] Unit tests for {specific component}
- [ ] Integration tests for {specific endpoint/flow}
- [ ] Build passes: `{module build command from project.yaml}`

## Decisions / Assumptions

- {Assumptions made}
```

### Step 8 — Report

Print:
- Artifact path
- Status: **approved**
- Step count, files changed (by module)
- Escalation rounds completed: {N}
- External module steps flagged: `⚠ EXTERNAL — requires explicit user permission`
- Next step: run the `implement` skill
