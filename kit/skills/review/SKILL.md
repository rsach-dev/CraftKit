---
name: review
description: "Reviews implementation against structured requirements and execution plan. Reads requirements, execution plan, and git diff, runs builds, checks acceptance criteria coverage, and produces artifacts/{TICKET}/4-review.md with a pass/fail verdict, issues found, and suggested fixes. Escalates when acceptance criteria interpretation is ambiguous or the pass/fail judgment requires human input."
---

# review — Review Implementation Against Requirements

## Overview

Verifies implementation matches requirements and execution plan. Runs builds,
checks acceptance criteria, identifies gaps. Escalates when criteria
interpretation is ambiguous or the verdict requires human judgment.

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.
Phase name: `review`. Escalation file:
`artifacts/{TICKET}/escalations/review.md`.

## Usage

### Step 0 — Load project config

```bash
cat "./.craftkit-project/project.yaml"
```

Note module paths, build commands, and `rules.coverage_min`.

### Step 1 — Check for existing escalations

```bash
TICKET="PROJ-XXXX"
ESCALATION="./artifacts/$TICKET/escalations/review.md"
if [ -f "$ESCALATION" ]; then
  cat "$ESCALATION"
fi
```

If exists: check `<!-- PENDING -->` → unanswered = STOP. All answered →
evaluate → append new round or proceed.

### Step 2 — Read artifacts

```bash
cat "./artifacts/$TICKET/1-requirements.md"
cat "./artifacts/$TICKET/3-execution-plan.md"
```

Both must exist with `status: approved`.

### Step 3 — Refresh code (pre-flight)

For each impacted module, fetch the latest default branch so diffs and builds
reflect the most current code state.

### Step 4 — Get the diff

```bash
cd {module-path}
git diff {default-branch} --stat
git diff {default-branch}
```

If not comparing against the default branch, ask user for the base branch.

### Step 5 — Run builds

```bash
cd {module-path} && {build command from project.yaml}
```

Record pass/fail. Capture lint, test, and coverage results where the build
produces them.

### Step 6 — Check acceptance criteria

For each criterion from `1-requirements.md`:
1. Find corresponding implementation in the diff
2. Verify tests exist that cover it
3. Mark as: ✅ met | ⚠️ partial | ❌ missing

**Confidence gate:** For any criterion where the mapping between requirement
and implementation is ambiguous — escalate. Do NOT mark ⚠️ or ✅ if you're
unsure whether the implementation actually satisfies the intent.

Escalation triggers:
- A criterion could be interpreted multiple ways and the implementation
  satisfies one but not another
- Tests exist but may not cover the actual edge cases implied by the criterion
- Implementation deviates from the plan but might still satisfy the
  requirement differently
- Quality metrics are borderline (e.g., coverage at exactly the minimum)

If not confident in the verdict → write escalation file and STOP.

### Step 7 — Check plan adherence

Compare execution plan steps against actual changes:
- Were all planned files modified?
- Were any unplanned files changed?
- Do changes match planned actions?

### Step 8 — Write review artifact

Only reached when confidence is 100%.

Write `artifacts/{TICKET}/4-review.md`:

```markdown
---
ticket: {TICKET}
date: {YYYY-MM-DD}
verdict: pass | pass-with-notes | fail
---
# Review: {title}

## Requirements Coverage

| # | Acceptance Criteria | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | {criterion} | ✅/⚠️/❌ | {file or test} |

## Plan Adherence

| Step | Description | Status |
|------|-------------|--------|
| 1 | {desc} | ✅ done / ⚠️ deviated / ❌ missing |

Unplanned changes:
- {files not in plan}

## Code Quality

- [x/] Lint/static analysis passes
- [x/] All tests pass
- [x/] Coverage ≥ {rules.coverage_min}%

## Issues Found

### Issue 1: {title}
- **Severity:** high | medium | low
- **File:** `{path}`
- **Description:** {what's wrong}
- **Fix:** {how to fix}

## Summary

{2-3 sentences.}
Verdict: **{verdict}**
Escalation rounds: {N}
```

### Step 9 — Offer fixes

If issues found:
```
Found {N} issues ({X high, Y medium, Z low}).
Would you like me to fix them? (yes/no/select)
```

If yes, apply fixes via the `feedback` skill conventions, re-run build.

### Step 10 — Report

Print verdict, issues count, artifact path. If passing: "Ready for PR — run
the ship skill."
