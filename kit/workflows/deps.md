---
name: deps
description: "Runs the standalone dependency-update pipeline for one module or all team-owned modules: version bumps with framework-anchor guardrails, build verification, commit, and an offer to ship. Use for routine dependency maintenance."
---

# deps — Dependency Update Workflow

## Overview

Thin wrapper around the deps-update skill with a ship gate at the end.
Coordinator rules from the feature workflow apply (gates, summaries,
escalation handling).

## Usage

### Step 0 — Initialize

Ask the user for:
1. **Ticket ID** (e.g., `PROJ-1234`)
2. **Module name** — or `all` for every team-owned module

### Phase 1 — deps-update

Execute `./.craftkit/skills/deps-update/SKILL.md`. Handle escalations per the
standard pattern (STOP, wait for answers, re-run).

**Phase gate — MANDATORY PAUSE:**
```
✅ Dependency update complete
   → artifacts/{TICKET}/6-deps-update.md

Summary:
- Anchors: {anchor old → new, majors unchanged}
- Updated: {N} dependencies, {M} pins removed, {K} deferred
- Build: {PASS/FAIL per module}
- Escalation rounds: {N}

Options:
  [1] Ship it (push branch + PR description)
  [2] Review the artifact / diff first
  [3] Stop here — commit stays local

Your choice?
```
**STOP. Wait for user.**

### Phase 2 — ship (optional)

If the user chose [1], execute `./.craftkit/skills/ship/SKILL.md` for the
updated module(s), then print the final report with branch names and the PR
description.

If `all` was requested, run the gate + ship per module so a failure in one
module never blocks shipping the others.
