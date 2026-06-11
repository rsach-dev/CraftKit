---
name: feature
description: "Orchestrates the full CraftKit development pipeline (requirements → tech-spec → execution-plan → implement → review → ship) for a given ticket. Runs each phase sequentially, pausing for human approval between phases and escalating when any phase raises questions. Manages token budget conservatively — checkpoints after each phase and pauses if consumption is high. Use when you want to run the full pipeline end-to-end with human-in-the-loop gating."
---

# feature — Development Pipeline Workflow

## Overview

Drives the full 8-phase feature development pipeline as a human operator
would — invoking each skill in sequence, pausing for human approval at every
phase gate, and escalating whenever a skill raises questions or token
consumption becomes concerning.

**Philosophy:** This workflow is a conservative coordinator, not an autonomous
executor. It treats every phase boundary as a mandatory human checkpoint. It
never silently proceeds to the next phase. It contains no domain logic — it
only sequences skills and gates.

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.

## Token Budget Management

The workflow must be **aggressively conservative** with token consumption:

1. **Never load files speculatively.** Only read artifacts and profiles when the current phase requires them.
2. **Summarize, don't echo.** After each phase completes, print a short summary (≤10 lines) — never dump the full artifact contents into the conversation.
3. **Phase isolation.** Each phase is a self-contained unit. Do not carry forward large intermediate context between phases. Re-read only the specific artifact needed by the next phase.
4. **Budget checkpoints.** After each phase, assess token consumption. If the conversation has grown large (many phases completed, large code scans, multiple escalation rounds), pause and tell the user:
   ```
   ⏸ Token checkpoint: This conversation has grown large after {N} phases.
   Recommendation: Start a new conversation and resume with:
     "Resume the feature workflow for {TICKET} at phase {next-phase}"
   The pipeline state is fully captured in artifacts/ — nothing is lost.
   ```
5. **Mandatory pause after implement.** The implement phase is the most token-intensive (code generation, builds, iteration). After it completes, ALWAYS recommend starting a fresh conversation for review.
6. **Escalation rounds count.** After 3+ escalation rounds in a single phase, recommend a fresh conversation for that phase alone.

## Pipeline

```
Phase 1: requirements     → artifacts/{TICKET}/1-requirements.md
Phase 2: tickets          → stdout (ticket text) — OPTIONAL
Phase 3: tech-spec        → artifacts/{TICKET}/2-tech-spec.md
Phase 4: execution-plan   → artifacts/{TICKET}/3-execution-plan.md
Phase 5: implement        → code changes + batch commit
Phase 6: review           → artifacts/{TICKET}/4-review.md
Phase 7: feedback         → targeted code fixes (0-N rounds) — OPTIONAL
Phase 8: ship             → branch push + PR description
```

## Usage

### Step 0 — Initialize

Ask the user for:
1. **Ticket ID** (e.g., `PROJ-1234`) — required
2. **Raw feature description** — required for Phase 1, or indicate that `1-requirements.md` already exists
3. **Pipeline scope** — full pipeline or partial? Ask: _"Run the full pipeline, or start/resume from a specific phase?"_

Check for existing artifacts to detect resume state:

```bash
TICKET="PROJ-XXXX"
echo "=== Existing artifacts ==="
ls -la "./artifacts/$TICKET/" 2>/dev/null || echo "No artifacts yet"
echo "=== Existing escalations ==="
ls -la "./artifacts/$TICKET/escalations/" 2>/dev/null || echo "No escalations"
```

If artifacts exist, determine the last completed phase and suggest resuming
from the next one.

### Phase execution pattern (applies to every phase)

1. **Gate check:** Does the phase's artifact already exist with
   `status: approved`? YES → skip the phase, print "{Phase} already
   approved", go to its gate.
2. **Execute:** Read and follow the phase's skill definition — load only the
   current phase's skill:
   ```bash
   cat "./.craftkit/skills/{skill-name}/SKILL.md"
   ```
3. **Handle escalation:** If the skill produces an escalation file instead of
   the artifact:
   ```
   ⚠ Phase {N} ({Phase}) needs your input.
   → artifacts/{TICKET}/escalations/{phase}.md

   Please answer the questions in that file, then tell me to continue.
   ```
   **STOP. Wait for user.** When the user says to continue, re-run the skill
   (it will read the answers).
4. **Phase gate — MANDATORY PAUSE:** print the phase summary and options, then
   **STOP and wait for the user to choose.**

### Phase 1 — requirements

Gate output:
```
✅ Phase 1 complete: Requirements approved
   → artifacts/{TICKET}/1-requirements.md

Summary:
- Title: {title}
- Acceptance criteria: {count}
- Impacted modules: {list}
- Escalation rounds: {N}

Next phase: Tech Spec
Options:
  [1] Proceed to Tech Spec
  [2] Generate ticket text first (tickets skill)
  [3] Review the requirements artifact before continuing
  [4] Stop here — I'll resume later

Your choice?
```

### Phase 2 — tickets (OPTIONAL)

Only if the user chose option [2]. After completion, return to the Phase 1
gate and offer options [1], [3], [4].

### Phase 3 — tech-spec

Gate output:
```
✅ Phase 3 complete: Tech Spec approved
   → artifacts/{TICKET}/2-tech-spec.md

Summary:
- Approach: {1-sentence summary}
- Modules impacted: {list with ownership flags}
- External module changes: {yes/no — flag if yes}
- API changes: {count}
- Schema changes: {yes/no}
- Escalation rounds: {N}

⚠ Token checkpoint: {assess and recommend fresh conversation if needed}

Next phase: Execution Plan
Options:
  [1] Proceed to Execution Plan
  [2] Review the tech spec artifact before continuing
  [3] Stop here — I'll resume later

Your choice?
```

### Phase 4 — execution-plan

Gate output:
```
✅ Phase 4 complete: Execution Plan approved
   → artifacts/{TICKET}/3-execution-plan.md

Summary:
- Steps: {count}
- Files changed: {count by module}
- External module changes: {list if any — ⚠ REQUIRES PERMISSION}
- Escalation rounds: {N}

⚠ IMPORTANT: The next phase (Implement) is token-intensive.
   Consider whether to proceed now or start a fresh conversation.

Next phase: Implement
Options:
  [1] Proceed to Implement
  [2] Review the execution plan artifact before continuing
  [3] Stop here — I'll resume in a fresh conversation
      (Recommended if this conversation is already long)

Your choice?
```

### Phase 5 — implement

Gate output (always recommend a fresh conversation):
```
✅ Phase 5 complete: Implementation done
   Changes committed to local branches.

Summary:
- Modules modified: {list}
- Files changed: {count}
- Build status: {pass/fail per module}
- Escalation rounds: {N}

⏸ Token checkpoint: Implementation phase is complete.
   STRONGLY RECOMMENDED: Start a new conversation for the Review phase.
   Run: "Resume the feature workflow for {TICKET} at phase review"
   All state is saved in artifacts/ and git branches.

Options:
  [1] Proceed to Review (in this conversation)
  [2] Stop here — I'll start a fresh conversation for Review (recommended)

Your choice?
```

### Phase 6 — review

Gate output:
```
✅ Phase 6 complete: Review finished
   → artifacts/{TICKET}/4-review.md

Summary:
- Verdict: {pass/pass-with-notes/fail}
- Issues: {count by severity}
- Escalation rounds: {N}
```

If **pass**:
```
Options:
  [1] Proceed to Ship
  [2] Stop here — I'll review the artifact first

Your choice?
```

If **pass-with-notes** or **fail**:
```
Options:
  [1] Apply fixes with the feedback skill (provide comments)
  [2] Review the issues and decide manually
  [3] Override and ship anyway (not recommended for fail)
  [4] Stop here

Your choice?
```

### Phase 7 — feedback (OPTIONAL, REPEATABLE)

Only if the user chose to apply fixes.

```
What feedback/comments should I apply? (paste review comments, or say "fix all issues from review")
```
**STOP. Wait for user to provide comments**, then execute the feedback skill.
After applying fixes, offer to re-run review or proceed to ship.

### Phase 8 — ship

Execute the ship skill, then print the final report:

```
🚀 Pipeline complete for {TICKET}

Phases completed:
  ✅ Requirements  → artifacts/{TICKET}/1-requirements.md
  ✅ Tech Spec     → artifacts/{TICKET}/2-tech-spec.md
  ✅ Exec Plan     → artifacts/{TICKET}/3-execution-plan.md
  ✅ Implement     → committed to branch
  ✅ Review        → artifacts/{TICKET}/4-review.md (verdict: {verdict})
  ✅ Ship          → pushed + PR description generated

Total escalation rounds across all phases: {N}
```

## Resuming a Pipeline

When a user says "Resume the feature workflow for {TICKET} at phase {phase}":

1. Read existing artifacts to rebuild state: `ls -la "./artifacts/$TICKET/"`
2. Verify all upstream artifacts have `status: approved`
3. Check for pending escalations in the target phase
4. Jump directly to the requested phase above
5. Do NOT re-read or re-summarize completed phase artifacts — trust that they
   exist and are approved

## Rules

1. **Never skip a gate.** Every phase boundary requires explicit human approval to proceed.
2. **Never run two phases without pausing.** Even if the user says "run everything", pause at each gate.
3. **Escalations within a phase are handled inline.** The workflow waits for answers before retrying the phase.
4. **Summarize, don't dump.** Phase completion messages show key metrics, never full artifact contents.
5. **Token consciousness.** Actively monitor conversation length and recommend breaks.
6. **External module guard.** If any phase flags external module modifications, escalate immediately — don't wait for the phase gate.
7. **Artifact integrity.** Never manually create or modify artifacts — only the phase skills write artifacts.
8. **One phase at a time.** Load only the current phase's skill definition. Don't pre-load future phases.
