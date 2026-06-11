---
name: triage
description: "Triages a bug from an observability trace, stack trace, error log, or raw bug description. Accepts a module name and bug input, scans the relevant codebase with targeted searches, identifies root cause candidates, and produces artifacts/{TICKET}/5-triage.md with a structured bug analysis and ranked list of possible fixes. Escalates when the search surface is too large, the root cause is ambiguous, or the trace spans multiple modules requiring human direction on where to focus."
---

# triage — Bug Triage from Trace or Description

## Overview

Takes an observability trace, stack trace, error log, or raw bug description
and triages it against the actual codebase. Identifies root cause candidates
and produces a ranked list of possible fixes. Designed to be
**token-conscious** — starts with the narrowest possible search surface and
escalates to the human for direction before expanding scope.

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.
Phase name: `triage`. Escalation file:
`artifacts/{TICKET}/escalations/triage.md`.

## Inputs

The user must provide:
1. **Ticket ID** — e.g. `PROJ-1234` (used for artifact naming)
2. **Module name** — must match a module in `project.yaml`
3. **Bug input** — one or more of:
   - Observability trace URL or pasted trace/span data
   - Stack trace
   - Error log lines
   - Raw description of the bug (symptoms, when it happens, affected users)

If any input is missing, ask the user before proceeding.

## Usage

### Step 1 — Get inputs and validate module

```bash
cat "./.craftkit-project/project.yaml"
```

If the module name doesn't match any entry in `modules`, tell the user and
list valid options. STOP.

### Step 2 — Check for existing escalations

```bash
TICKET="PROJ-XXXX"
ESCALATION="./artifacts/$TICKET/escalations/triage.md"
if [ -f "$ESCALATION" ]; then
  cat "$ESCALATION"
fi
```

If the file exists:
1. Check for any `<!-- PENDING -->` markers — if found, tell user which questions are unanswered and STOP
2. Read all answers from all rounds
3. Evaluate: do the answers give 100% confidence to produce the triage artifact? If not, append a new `## Round N` with follow-up questions and STOP
4. If confident, update frontmatter `status: resolved` and proceed to Step 7

### Step 3 — Load module profile

```bash
cat "./.craftkit-project/context/profiles/{module-name}.md"
```

Use the profile to understand structure, key patterns, and conventions. If
the module has a `stack_pack` and
`./.craftkit/stacks/{stack_pack}/references/triage.md` exists, read it for
stack-specific scan heuristics (the token budgets below still apply).

### Step 4 — Refresh code (pre-flight)

Ensure the module's checkout is on the latest default branch. If dirty, tell
the user to commit or stash first. STOP.

### Step 5 — Targeted code scan (token-conscious)

**This is the most critical step for token management.** Do NOT read entire
source trees. Follow this narrowing strategy:

#### 5a — Extract signals from the bug input

Parse the trace / stack trace / description to extract:
- **Exception/error type** (e.g. `NullPointerException`, `TypeError`)
- **Error message** (e.g. `"column 'discount' cannot be null"`)
- **File/class names** from stack frames
- **Function/method names** from stack frames
- **HTTP endpoint** (e.g. `POST /api/v1/orders`)
- **Table/column names** if present
- **Span tags** (e.g. `resource_name`, `error.type`, `error.stack`)
- **HTTP status code** (e.g. `500`, `400`)

If the bug input has no extractable signals (vague description, no trace),
escalate immediately — ask the user for at least one of: stack trace, error
message, affected endpoint, or error time window.

#### 5b — Phase 1 scan: direct hits (lowest token cost)

Search only for files/functions directly named in the trace:

```bash
# Find files matching names from the trace
grep -rn "{FunctionName}" {module-path}/src -l

# Locate the specific lines
grep -n "{functionName}" {module-path}/src/path/to/file
```

Read ONLY the relevant functions/blocks — not entire files. Use `grep -n` to
find line numbers, then read targeted line ranges.

#### 5c — Phase 2 scan: immediate callers/callees (moderate token cost)

If Phase 1 doesn't reveal the root cause:

```bash
# Find who calls the failing function
grep -rn "{functionName}\|{TypeName}" {module-path}/src -l

# Check the endpoint handler if an HTTP path is known
grep -rn "{endpoint-path}" {module-path}/src -l
```

Read only the relevant sections of discovered files.

#### 5d — Phase 3 scan: broader search (HIGH token cost — gate here)

If Phase 1 + Phase 2 are insufficient, **DO NOT proceed to a broader
search.** Instead, escalate to the human with what you've found so far and
ask for direction:

- "I've identified these {N} files as potentially related but can't isolate the root cause. Which area should I focus on?"
- "The trace suggests the error originates in {component}, but it may be caused by upstream data from {other component}. Should I investigate {A} or {B}?"
- "The stack trace exits our codebase into {library/framework}. Is this a known infrastructure issue or should I investigate our usage of {library}?"

**Token budget rule:** If at any point you've read more than **15 files** or
**1500 lines** of source code without a clear root cause candidate, STOP and
escalate. The human can narrow the scope.

#### 5e — Check tests and configuration

Once you have root cause candidates, check:

```bash
# Find related tests
grep -rn "{FunctionName}" {module-path}/{test-dir} -l

# Check config if the bug might be configuration-related
grep -rn "{relevant-config-key}" {module-path} --include="*.yml" --include="*.yaml" --include="*.properties" --include="*.json" --include="*.toml" -l | head -10
```

### Step 6 — Assess confidence

**Confidence gate** — escalate if ANY of these apply:

| Trigger | Example |
|---------|---------|
| Multiple equally likely root causes | "Could be a missing null check in `processOrder()` OR a race condition in the save path" |
| Root cause spans multiple modules | "Error in module A but triggered by malformed data from module B" |
| Bug is environment-specific | "Might only reproduce with specific infra config" |
| Cannot reproduce from code alone | "Need to know the exact request payload that triggered this" |
| Search surface exhausted without clarity | Read 15+ files and still uncertain |
| External module is involved and we're read-only | "Fix might require changes in an `ownership: external` module" |
| Business logic ambiguity | "Not clear whether `null` discount is valid or a bug in the caller" |

If not confident → write escalation file and STOP:

```bash
mkdir -p "./artifacts/$TICKET/escalations"
```

Write `artifacts/{TICKET}/escalations/triage.md` following the escalation
protocol format. Include in each question:
- What you've found so far (files read, patterns observed)
- Where you're stuck
- What the answer would unblock

Print:
```
⚠ Escalation: {N} questions need your input
→ artifacts/{TICKET}/escalations/triage.md

Fill in answers and re-run this skill.
```
**STOP. Do not produce the triage artifact.**

### Step 7 — Write triage artifact

Only reached when confidence is 100%.

```bash
mkdir -p "./artifacts/$TICKET"
```

Write `artifacts/{TICKET}/5-triage.md`:

```markdown
---
ticket: {TICKET}
module: {module-name}
date: {YYYY-MM-DD}
status: approved
severity: critical | high | medium | low
---
# Bug Triage: {TICKET}

## Bug Summary

**Module:** {module-name}
**Severity:** {critical | high | medium | low}
**Symptom:** {1-2 sentences describing what the user/system observes}
**Error:** {error type + message, or "N/A" if symptom-only}

## Input Evidence

{Paste or summarize the trace / stack trace / error log / description
provided by the user. Keep it concise — only the relevant parts.}

## Root Cause Analysis

### Identified Root Cause

{2-4 sentences explaining the root cause. Reference specific files,
functions, and line numbers.}

### Evidence Chain

1. {First signal from trace/error} → points to `{file}:{line}`
2. {What that code does and why it fails}
3. {Upstream cause if any}

### Contributing Factors

- {Any secondary issues that made this worse or harder to detect}
- {Missing validation, missing tests, misleading error messages, etc.}

## Recommended Fixes

Ordered by recommendation — most recommended first.

### Fix 1: {title} ⭐ RECOMMENDED

- **File(s):** `{path/to/file}`
- **Change:** {specific code change description}
- **Risk:** low | medium | high
- **Effort:** small | medium | large
- **Why recommended:** {why this is the best fix}

```
// Before
{relevant code snippet showing the problem}

// After
{relevant code snippet showing the fix}
```

### Fix 2: {title}

- **File(s):** `{path/to/file}`
- **Change:** {specific code change description}
- **Risk:** low | medium | high
- **Effort:** small | medium | large
- **Trade-off:** {why this is a valid but less preferred alternative}

{Continue for additional fix options. Typically 2-4 fixes.}

## Test Gaps

| Gap | Description | Recommended Test |
|-----|-------------|-----------------|
| {missing scenario} | {why it wasn't caught} | {test to add} |

## Prevention

- {What would prevent this class of bug in the future}
- {Monitoring/alerting improvements}
- {Code pattern changes}

## Scope Assessment

- **Can be fixed in {module-name} alone:** yes | no
- **Requires external module changes:** yes (specify) | no
- **Requires schema migration:** yes | no
- **Requires config change:** yes | no
```

### Step 8 — Report

Print:
- Artifact path: `artifacts/{TICKET}/5-triage.md`
- Status: **approved**
- Severity: {severity}
- Root cause: {1-sentence summary}
- Recommended fix: {Fix 1 title}
- Escalation rounds completed: {N} (or 0 if none needed)
- Files analyzed: {count}
- Next steps: "Run the implement skill to apply the recommended fix, or
  review the artifact for alternative options."

## Token Management Summary

| Action | Budget |
|--------|--------|
| Read module profile | ~40 lines |
| Phase 1 scan (direct hits) | Read ≤5 files, targeted line ranges only |
| Phase 2 scan (callers/callees) | Read ≤10 additional files, targeted sections |
| Phase 3 scan (broad) | **DO NOT proceed — escalate to human** |
| Total file reads before escalation | ≤15 files or ≤1500 lines |
| Test/config checks | ≤5 files |

**Rule:** Always prefer `grep -n` → targeted read over reading whole files.
Every file read costs tokens — justify each one.
