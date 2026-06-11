---
name: onboard
description: "Interactive guided tour of CraftKit for a new engineer: walks through the repo's module registry and conventions, explains the pipeline and escalation protocol, then runs one toy ticket end-to-end through the phases in a scratch artifact directory. Use on a new engineer's first day with the repo."
---

# onboard — New Engineer Tour

## Overview

A teaching workflow. The goal is that after one session, a new engineer can
run `/ck-feature` on real work and understand every gate they're approving.
Be conversational, go one section at a time, and check understanding before
moving on. Never rush; never dump everything at once.

## Usage

### Part 1 — The lay of the land

1. Read and summarize for the user (in your own words, ≤15 lines total):
   ```bash
   cat ./AGENTS.md
   cat ./.craftkit-project/project.yaml
   ```
   Cover: what modules exist, who owns them (team vs external and what
   read-only means), the build commands, and the ticket/commit format.
2. Ask: "Any questions about the modules before we look at how the pipeline
   works?" **Wait for the user.**

### Part 2 — How the pipeline works

1. Explain the 8 phases and what artifact each produces (use the table in
   `AGENTS.md` — don't read every skill file).
2. Explain the two rules that make this safe:
   - **Human gates:** nothing auto-advances; you approve every phase.
   - **Escalation, never guessing:** show the format from
     `./.craftkit/skills/references/escalation-protocol.md` — Context, Impact,
     `<!-- PENDING -->`, append-only rounds.
3. If `./artifacts/` contains a completed ticket directory, offer to walk
   through it as a real worked example (summarize each artifact in 2-3 lines —
   do not echo full contents).
4. Ask: "Ready to try a toy run?" **Wait for the user.**

### Part 3 — Toy run (scratch, no code changes)

1. Use ticket ID `ONBOARD-1` and a deliberately *slightly ambiguous* toy
   feature for this repo (invent one relevant to its domain, e.g. "add a
   small validation rule" — something whose details are underspecified).
2. Run the requirements skill for `ONBOARD-1`. Because the description is
   ambiguous, it should **escalate** — this is the point. Show the user the
   escalation file and have them answer the questions in it, then re-run.
3. Walk the approved `artifacts/ONBOARD-1/1-requirements.md` together and
   show the `status: approved` gate.
4. Optionally (user's choice) continue to tech-spec and execution-plan for
   the toy ticket. **Do not run implement** — the toy run never touches
   source code. Stop at the plan and explain that implement/review/ship work
   the same way: skill runs, gate pauses, human approves.
5. Clean up: ask the user whether to delete `artifacts/ONBOARD-1/` or keep it
   as a reference. Delete only if they say yes.

### Part 4 — Wrap up

Print a cheat sheet:

```
You're ready. Day-to-day commands:
  /ck-feature  — build a feature (full pipeline, you approve each phase)
  /ck-bugfix   — triage and fix a bug
  /ck-review   — review a branch, optionally apply fixes
  /ck-deps     — dependency updates

When the agent escalates:
  1. Open artifacts/{TICKET}/escalations/{phase}.md
  2. Replace each <!-- PENDING --> with your answer
  3. Re-run the same command

Everything the pipeline knows lives in:
  .craftkit-project/project.yaml      — module registry + rules
  .craftkit-project/context/          — workspace + module profiles
  artifacts/{TICKET}/                 — the paper trail per ticket
See ONBOARDING.md for this cheat sheet later.
```

## Rules

- One part at a time; wait for the user between parts.
- The toy run must never modify source code or push anything.
- Real escalation beats explanation — let the user experience the
  answer-and-rerun loop rather than just describing it.
