# Escalation Protocol

Shared protocol used by all CraftKit skills. When a skill cannot proceed with
100% confidence, it generates an escalation artifact for human input instead of
guessing.

## Flow

```
Skill invoked
  ↓
Check for escalation file → exists?
  ├─ YES → read answers → all answered?
  │   ├─ YES → evaluate → confident?
  │   │   ├─ YES → proceed to produce artifact
  │   │   └─ NO  → append new round of questions → STOP
  │   └─ NO  → tell user which questions are unanswered → STOP
  └─ NO  → analyze inputs → confident?
      ├─ YES → proceed to produce artifact
      └─ NO  → create escalation file with round 1 → STOP
```

## Escalation File

**Path:** `artifacts/{TICKET}/escalations/{phase}.md`
(artifact dir is configurable via `escalation.dir_pattern` in `.craftkit-project/project.yaml`)

Phases: `requirements`, `tickets`, `tech-spec`, `execution-plan`, `implement`,
`review`, `triage`, `deps-update`

**Format:**

```markdown
---
ticket: {TICKET}
phase: {phase}
status: pending | resolved
---
# Escalations: {Phase Title}

## Round 1

### Q1: {specific question}
**Context:** {why this answer matters for the artifact — 1 sentence}
**Impact:** {what decision this unblocks}
**Answer:**
<!-- PENDING -->

### Q2: ...

---

## Round 2

{Generated after human answers Round 1 — new questions may arise from answers}

### Q3: {follow-up question}
**Context:** ...
**Impact:** ...
**Answer:**
<!-- PENDING -->
```

## Rules

1. **Never produce the phase artifact while escalations are pending.** The
   escalation file `status` must be `resolved` (all questions answered AND no
   new questions generated) before writing the output artifact.

2. **Questions must be specific and actionable.** Never ask vague questions
   like "can you clarify the requirements?" Instead: "Should the `discount`
   field default to `0` or `null` when the client omits it from the payload?"

3. **Every question needs Context and Impact.** The human must understand why
   the question matters and what decision it unblocks.

4. **Answers trigger re-evaluation.** When the skill re-runs and reads answers,
   it must evaluate whether those answers introduce new ambiguities. One answer
   may spawn 0–N new questions. This is expected and correct.

5. **Round numbering is append-only.** Never modify or delete previous rounds.
   Each new set of questions gets a new `## Round N` section appended.

6. **Mark `<!-- PENDING -->` for unanswered questions.** The human replaces
   this marker with their answer. The skill detects unanswered questions by
   scanning for `<!-- PENDING -->`.

7. **Resolve when confident.** When all questions are answered and no new
   questions arise, update frontmatter `status: resolved` and proceed to
   produce the artifact.

8. **Confidence is binary.** There is no "mostly confident." Either the skill
   has 100% clarity to produce the artifact correctly, or it escalates.
   Partial artifacts are never written.

## What Triggers Escalation

| Phase | Escalation Triggers |
|-------|-------------------|
| requirements | Ambiguous scope, unclear acceptance criteria, missing context on business rules, unknown module boundaries |
| tickets | Unclear ticket boundaries, dependency ordering ambiguity, sizing uncertainty for complex work |
| tech-spec | Multiple valid approaches with no clear winner, unclear data ownership, unknown API contracts, missing schema info |
| execution-plan | Ambiguous step ordering, unclear file-level change scope, test strategy gaps |
| implement | Unclear business logic, conflicting patterns in codebase, missing test data/fixtures, ambiguous edge cases |
| review | Acceptance criteria interpreted differently than intended, unclear pass/fail threshold for edge cases |
| triage | Multiple equally likely root causes, search surface too large (>15 files), root cause spans multiple modules, environment-specific bugs, cannot reproduce from code alone |
| deps-update | Deliberate version pins, unclear framework compatibility, breaking API changes in a target version |

## Human Workflow

1. Skill runs → generates `artifacts/{TICKET}/escalations/{phase}.md`
2. Skill prints: "⚠ Escalation: N questions need your input → `artifacts/{TICKET}/escalations/{phase}.md`"
3. Human opens file, replaces each `<!-- PENDING -->` with their answer
4. Human re-runs the same skill
5. Skill reads answers → may produce artifact or append new round
6. Repeat until `status: resolved`
