---
name: bugfix
description: "Orchestrates the bug-fix pipeline (triage → lite execution plan → implement → review → ship) for a given ticket. Pauses for human approval between phases, escalates when any phase raises questions. Use when something is broken and you have a trace, stack trace, error log, or bug description."
---

# bugfix — Bug Fix Workflow

## Overview

Drives a bug from triage to shipped fix, with a mandatory human gate at every
phase boundary. Follows the same coordinator rules as the feature workflow:
no domain logic, summarize don't echo, one phase's skill loaded at a time,
token checkpoints, and the escalation protocol
(`./.craftkit/skills/references/escalation-protocol.md`) throughout.

## Pipeline

```
Phase 1: triage           → artifacts/{TICKET}/5-triage.md
Phase 2: execution-plan   → artifacts/{TICKET}/3-execution-plan.md (lite — from the chosen fix)
Phase 3: implement        → code changes + batch commit
Phase 4: review           → artifacts/{TICKET}/4-review.md
Phase 5: ship             → branch push + PR description
```

## Usage

### Step 0 — Initialize

Ask the user for:
1. **Ticket ID** (e.g., `PROJ-1234`)
2. **Module name** (must match `project.yaml`)
3. **Bug input** — trace, stack trace, error log, or description

Check `./artifacts/$TICKET/` for existing artifacts to detect resume state,
exactly as in the feature workflow.

### Phase 1 — triage

Execute `./.craftkit/skills/triage/SKILL.md`. Handle escalations per the
standard pattern (STOP, wait for answers, re-run).

**Phase gate — MANDATORY PAUSE:**
```
✅ Phase 1 complete: Triage approved
   → artifacts/{TICKET}/5-triage.md

Summary:
- Severity: {severity}
- Root cause: {1 sentence}
- Recommended fix: {Fix 1 title} (risk: {risk}, effort: {effort})
- Alternative fixes: {count}

Options:
  [1] Plan the recommended fix (Fix 1)
  [2] Plan a different fix — tell me which
  [3] Review the triage artifact before continuing
  [4] Stop here — triage only

Your choice?
```
**STOP. Wait for user.**

### Phase 2 — execution-plan (lite)

Execute `./.craftkit/skills/execution-plan/SKILL.md` using the triage
artifact's chosen fix as input (instead of a tech spec — note the chosen fix
explicitly when following the skill). Acceptance criteria for the plan come
from the triage artifact: the bug no longer reproduces, and the test gaps
identified in triage are closed.

**Phase gate — MANDATORY PAUSE** with step count, files changed, and the
standard options (proceed / review artifact / stop).

### Phase 3 — implement

Execute `./.craftkit/skills/implement/SKILL.md`.

**Phase gate — MANDATORY PAUSE** with build status per module. Recommend a
fresh conversation before review if the conversation has grown long.

### Phase 4 — review

Execute `./.craftkit/skills/review/SKILL.md`. The acceptance criteria are the
triage artifact's expected outcome + closed test gaps. Handle
pass / pass-with-notes / fail gates exactly as in the feature workflow
(feedback loop available on issues).

### Phase 5 — ship

Execute `./.craftkit/skills/ship/SKILL.md`, then print:

```
🚀 Bug fix complete for {TICKET}
  ✅ Triage     → artifacts/{TICKET}/5-triage.md ({severity})
  ✅ Plan       → artifacts/{TICKET}/3-execution-plan.md
  ✅ Implement  → committed
  ✅ Review     → artifacts/{TICKET}/4-review.md (verdict: {verdict})
  ✅ Ship       → pushed + PR description generated
```

## Rules

All rules from the feature workflow apply: never skip a gate, never run two
phases without pausing, summarize don't dump, external module guard, artifact
integrity, one phase at a time.
