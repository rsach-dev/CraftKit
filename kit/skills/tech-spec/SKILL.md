---
name: tech-spec
description: "Builds a technical specification and module impact document from a structured requirements artifact. Loads module profiles for impacted modules, scans actual repo code to validate design, and produces artifacts/{TICKET}/2-tech-spec.md with approach, module impact, data flow, API changes, schema changes, risk assessment, and testing strategy. Escalates to human when design decisions or technical assumptions need confirmation."
---

# tech-spec — Build Tech Spec + Module Impact

## Overview

Translates requirements into a technical design document. Loads only impacted
module profiles, scans source code to validate assumptions. Will not produce
the spec until there is 100% confidence — escalates when design decisions,
data ownership, or API contracts are ambiguous.

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.
Phase name: `tech-spec`. Escalation file:
`artifacts/{TICKET}/escalations/tech-spec.md`.

## Usage

### Step 0 — Load project config

```bash
cat "./.craftkit-project/project.yaml"
```

Note module paths, ownership, and build commands.

### Step 1 — Check for existing escalations

```bash
TICKET="PROJ-XXXX"
ESCALATION="./artifacts/$TICKET/escalations/tech-spec.md"
if [ -f "$ESCALATION" ]; then
  cat "$ESCALATION"
fi
```

If exists: check `<!-- PENDING -->` → unanswered = STOP. All answered →
evaluate → append new round or proceed.

### Step 2 — Read requirements

```bash
cat "./artifacts/$TICKET/1-requirements.md"
```

Requirements must have `status: approved`. If not, tell user to complete the
`requirements` skill first.

### Step 3 — Load impacted module profiles

From the requirements' "Impacted Modules" table, load each profile:

```bash
cat "./.craftkit-project/context/profiles/{module-name}.md"
```

Only load profiles for impacted modules. If a profile doesn't exist, run a
brief targeted scan of the module instead (and suggest `context-sync`).

### Step 4 — Refresh code (pre-flight)

For each impacted module that is its own git checkout, pull the latest code:

```bash
cd {module-path}
git fetch origin
git checkout {default-branch}
git pull origin {default-branch}
```

If the module lives inside the current repo, ensure the working tree is on the
latest default branch instead. If the checkout is dirty, tell user to commit
or stash changes first. Abort if state is inconsistent.

### Step 5 — Scan actual code

For each impacted module, validate assumptions:
- List the source tree to verify structure (e.g. `find {module-path}/src -type d | head -30`)
- `grep -rn "keyword" {module-path}/src -l` — find relevant files
- Read key files that will be modified
- Check existing tests for patterns

Keep scans targeted — don't read entire modules.

### Step 6 — Assess confidence

**Confidence gate** — escalate if any of these are unclear:
- Is there a single clear technical approach, or are there competing options?
- Are all API contracts (request/response shapes) known?
- Are schema changes well-defined (column types, constraints, migrations)?
- Is data flow through the system unambiguous?
- Are integration points with other modules/services understood?
- Are there edge cases with unclear expected behavior?
- For `ownership: external` modules: is the change feasible without breaking
  their contracts?

If not confident → write escalation file and STOP. Include what you found in
code scans as context in the questions.

### Step 7 — Write tech spec

Only reached when confidence is 100%.

Write `artifacts/{TICKET}/2-tech-spec.md`:

```markdown
---
ticket: {TICKET}
title: {title from requirements}
date: {YYYY-MM-DD}
status: approved
modules: [{comma-separated module names}]
---
# Tech Spec: {title}

## Approach Summary

{1-2 paragraphs explaining the technical approach. Reference specific
files/patterns.}

## Module Impact

### {module-name}

| File | Action | Description |
|------|--------|-------------|
| `path/to/file` | modify | {what changes} |
| `path/to/new_file` | create | {purpose} |

Key decisions:
- {Why this approach over alternatives}

{Repeat for each impacted module}

## Data Flow

{Text diagram showing how data moves through the system.}

## API Changes

| Method | Endpoint | Change |
|--------|----------|--------|
| {GET/POST/...} | {/api/v1/...} | {describe} |

{Omit if no API changes}

## Schema Changes

{Table/column or data model changes, migrations needed. Omit if none.}

## Risk / Rollback

- {What could go wrong}
- {How to roll back}

## Testing Strategy

- Unit: {what to test}
- Integration: {what to test}
- Manual: {verification steps}
```

### Step 8 — Report

Print:
- Artifact path
- Status: **approved**
- Modules impacted (with ownership flags)
- Escalation rounds completed: {N}
- Next step: run the `execution-plan` skill
