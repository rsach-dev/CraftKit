---
name: feedback
description: "Accepts human review comments or feedback about code produced by the implement skill and makes targeted changes to the codebase. Comments can be code-specific fixes, pattern corrections, or coding standards. When a comment describes a reusable standard (e.g. max assertions per test, naming conventions), the standard is persisted in .craftkit-project/context/coding-standards.md so all future implement runs respect it. Requires a ticket ID and one or more comments. Do NOT run this skill without user-provided inputs."
---

# feedback — Apply Review Comments & Learn Standards

## Overview

Post-implementation refinement skill. The user provides review comments (from
PR review, self-review, or team feedback) and this skill applies the changes
to the code. If a comment represents a **reusable coding standard**, it is
captured in a persistent standards file so future implementations follow it
automatically.

## Input Requirements

**This skill MUST NOT run without inputs.** The user must provide:

1. **Ticket ID** — e.g. `PROJ-1234`
2. **One or more comments** — free-text feedback about the implementation

If either is missing, print the following and **STOP**:

```
⚠ feedback requires inputs:
  1. Ticket ID (e.g. PROJ-1234)
  2. One or more review comments

Example comments:
  - "OrderMapper should use Optional.ofNullable instead of null checks"
  - "Tests should have no more than 5 assertions each"

Please provide both and re-run.
```

## Usage

### Step 1 — Parse and classify comments

Read the user's comments and classify each one as:

- **`code-fix`** — A specific change to a specific piece of code (e.g.
  "rename variable X in OrderService", "add null check in mapper")
- **`standard`** — A reusable rule that applies across the codebase now and in
  the future (e.g. "max 5 assertions per test", "DTOs must not have business
  logic")

Print the classification:

```
Comment Classification:
  1. [code-fix]  "{comment}"
  2. [standard]  "{comment}"
```

### Step 2 — Persist standards

For each comment classified as `standard`, append it to:

```bash
STANDARDS="./.craftkit-project/context/coding-standards.md"
```

Read the existing file first (create it if absent). If the standard already
exists (same intent, even if worded differently), skip it and note that it's
already tracked. Otherwise, append the new standard under the appropriate
category.

The standards file uses this format:

```markdown
# Coding Standards

Persistent coding standards learned from review feedback.
These are loaded by the implement and feedback skills to enforce consistency.

## Testing
- {standard}

## Naming & Structure
- {standard}

## Error Handling
- {standard}

## General
- {standard}
```

Place each standard under the most fitting category. Add new categories if
none fit. After appending, print:

```
📏 Standard persisted: "{standard}"
   File: .craftkit-project/context/coding-standards.md
```

### Step 3 — Load context

```bash
cat "./.craftkit-project/project.yaml"
cat "./artifacts/$TICKET/3-execution-plan.md"
cat "./.craftkit-project/context/profiles/{module}.md"
```

Load only the profiles of impacted modules. If a touched module has a
`stack_pack`, also load `./.craftkit/stacks/{stack_pack}/conventions.md` —
fixes must follow it.

### Step 4 — Locate affected files

For each `code-fix` comment, identify which files need changes. Use the
comment's context, class/function names, and the execution plan to find the
right files:

```bash
grep -rn "{identifier}" {module-path}/src -l
```

**Confidence gate:** If a comment is ambiguous about which code it refers to,
or the requested change has multiple valid implementations, ask the user
directly (these are interactive fixes — no escalation file needed for this
skill, but never guess).

### Step 5 — Apply fixes

Apply each `code-fix` following module profile conventions and all persisted
standards (including ones just added). Print `✓` per comment applied.

### Step 6 — Verify

Run each touched module's `build` command from `project.yaml`. Fix failures
caused by the changes; if a failure is unrelated or requires a judgment call,
report it to the user instead of guessing.

### Step 7 — Commit

One commit per touched module:

```bash
cd {module-path}
git add -A
git commit -m "{TICKET}: Apply review feedback"
```

### Step 8 — Report

```
Feedback Applied: {TICKET}
━━━━━━━━━━━━━━━━━━━━━━━━━━
Comments applied: {N} code fixes
Standards persisted: {M}
Builds: {pass/fail per module}

Next: re-run the review skill, or run ship if review already passed.
```
