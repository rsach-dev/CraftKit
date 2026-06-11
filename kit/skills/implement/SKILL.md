---
name: implement
description: "Executes a step-by-step implementation plan from artifacts/{TICKET}/3-execution-plan.md. Reads module profiles for coding conventions, implements each step in order, runs builds to verify, and batch commits at end. Refuses changes to external-ownership modules unless the user explicitly allows. Escalates when implementation encounters ambiguous logic, unclear edge cases, or conflicting codebase patterns."
---

# implement — Execute Plan

## Overview

Takes an execution plan and implements it step by step. Follows
module-specific coding conventions. Verifies with builds. Batch commits at
end. Escalates mid-implementation when business logic is ambiguous or
codebase conflicts arise.

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.
Phase name: `implement`. Escalation file:
`artifacts/{TICKET}/escalations/implement.md`.

**Implementation-specific escalation behavior:** Unlike planning skills,
escalations here pause implementation mid-stream. Completed steps are
preserved. When the user answers and re-runs, the skill resumes from the step
that triggered escalation.

## Usage

### Step 0 — Load project config

```bash
cat "./.craftkit-project/project.yaml"
```

Note module paths/ownership, `rules.protected_files`, `ticket.commit_format`,
and per-module `build` commands. Also load persisted standards if present:

```bash
cat "./.craftkit-project/context/coding-standards.md" 2>/dev/null
```

For each impacted module with a `stack_pack` in `project.yaml`, also load its
conventions (and nothing else from the pack):

```bash
cat "./.craftkit/stacks/{stack_pack}/conventions.md"
```

Precedence on conflict: coding-standards > module profile > pack conventions.

### Step 1 — Read execution plan

```bash
TICKET="PROJ-XXXX"
cat "./artifacts/$TICKET/3-execution-plan.md"
```

Plan must have `status: approved`. If missing, tell user to run the
`execution-plan` skill first.

### Step 2 — Check for existing escalations

```bash
ESCALATION="./artifacts/$TICKET/escalations/implement.md"
if [ -f "$ESCALATION" ]; then
  cat "$ESCALATION"
fi
```

If exists:
- Check for `<!-- PENDING -->` → unanswered = STOP
- Read answers → evaluate confidence for the blocked step
- If new questions arise from answers → append new round and STOP
- If resolved → update `status: resolved`, note which step to resume from,
  continue implementation

### Step 3 — Check for external module changes

Scan the plan for any files under modules with `ownership: external`. If
found:

**STOP.** Print:
```
⚠ This plan includes changes to external modules:
  - {file paths}

External modules are read-only by default. Do you want to:
  1. Skip external steps and implement team-owned changes only
  2. Proceed with ALL changes (you take responsibility)
  3. Abort
```

Wait for user response.

### Step 4 — Load module profiles

```bash
cat "./.craftkit-project/context/profiles/{module-name}.md"
```

### Step 5 — Refresh code (pre-flight)

For each impacted module, ensure you're on the latest default branch before
implementing. If the checkout is dirty or has merge conflicts, tell user to
clean it up first. Abort if state is inconsistent.

### Step 6 — Implement step by step

For each step in the plan:

1. Read the current file (if modify/delete)
2. **Confidence check for this step:** Can you implement it with zero
   assumptions?
   - If YES → implement, print `✓ Step N: {description}`
   - If NO → write/append escalation file with specific questions about this
     step. Record which step is blocked. STOP.
3. Implement the change following module profile conventions and any persisted
   coding standards

Escalation triggers during implementation:
- Business logic with multiple valid interpretations
- Existing code patterns that conflict with the plan
- Missing test data or fixtures referenced in the plan
- Edge cases not covered by the execution plan
- Unclear null handling, error conditions, or defaults

### Step 7 — Build verification

After all steps for a module, run its `build` command from `project.yaml`:

```bash
cd {module-path} && {build command}
```

If the build fails:
- Attempt to fix (imports, type mismatches, test failures)
- Re-run build
- If still failing after 2 attempts → escalate with build error details

### Step 8 — Batch commit

After all steps pass and builds succeed, one commit per module using
`ticket.commit_format`:

```bash
cd {module-path}
git add -A
git commit -m "{TICKET}: {title from plan}"
```

### Step 9 — Report

```
Implementation Complete: {TICKET}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Steps: {N done} / {N total}
Escalation rounds: {N}
Modules modified:
  ✓ {module}: build passing
Commits:
  {module}: {hash} — {message}

Next: run the review skill to verify against requirements
```

## Rules

- **Never modify files in `ownership: external` modules without explicit user
  permission**
- **Never modify `rules.protected_files`** from `project.yaml` (build configs,
  lint/quality-gate configs) — fix the code to satisfy the rules, never weaken
  the rules
- **Always follow** module profile patterns and persisted coding standards
- **Commit messages** use `ticket.commit_format`
- **Batch commit** per module at end, not per step
- **Escalate, don't guess** — if implementation requires an assumption about
  business logic, escalate
