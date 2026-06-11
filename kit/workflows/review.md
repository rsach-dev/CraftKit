---
name: review
description: "Reviews an existing branch or working tree against the ticket's requirements and execution plan, with an optional feedback-fix loop. Use to review work before opening a PR, or to apply reviewer comments. A single pass with no fixes is equivalent to running the review skill directly."
---

# review — Review Workflow

## Overview

Runs the review skill, then offers a feedback → re-review loop until the
verdict is `pass` or the user stops. Coordinator rules from the feature
workflow apply (gates, summaries, escalation handling).

## Usage

### Step 0 — Initialize

Ask the user for:
1. **Ticket ID** (e.g., `PROJ-1234`)
2. **Base branch** if not the default branch

Both `1-requirements.md` and `3-execution-plan.md` must exist with
`status: approved`. If they don't (e.g. reviewing work done outside the
pipeline), tell the user which upstream skill to run first — or, if they just
want an ad-hoc code review without artifacts, say so and proceed with the
review skill's quality checks only, marking the requirements-coverage section
"N/A (no requirements artifact)".

### Phase 1 — review

Execute `./.craftkit/skills/review/SKILL.md`. Handle escalations per the
standard pattern (STOP, wait for answers, re-run).

**Phase gate — MANDATORY PAUSE:**

If **pass**:
```
✅ Review verdict: pass → artifacts/{TICKET}/4-review.md
Options:
  [1] Ship it (run the ship skill)
  [2] Done — I'll take it from here
Your choice?
```

If **pass-with-notes** or **fail**:
```
Review verdict: {verdict} → artifacts/{TICKET}/4-review.md
Issues: {X high, Y medium, Z low}
Options:
  [1] Fix all issues from the review (feedback skill)
  [2] Fix selected issues — tell me which
  [3] Done — I'll handle the issues manually
Your choice?
```
**STOP. Wait for user.**

### Phase 2 — feedback loop (optional, repeatable)

If the user chose to fix issues, execute
`./.craftkit/skills/feedback/SKILL.md` with the chosen review comments, then
offer to re-run Phase 1. Repeat until `pass` or the user stops.

### Phase 3 — ship (optional)

If the user chose to ship, execute `./.craftkit/skills/ship/SKILL.md`.
