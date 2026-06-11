---
name: init
description: "Finishes CraftKit setup after `craftkit init`: reviews and completes project.yaml (modules, build/test commands, stack packs, harnesses), fills in AGENTS.md/ONBOARDING.md placeholders, and generates the context files (workspace.md + module profiles). Use right after installing CraftKit into a repo, or to repair an incomplete setup."
---

# init — Finish CraftKit Setup

## Overview

`craftkit init` (the shell command) vendors the kit and scaffolds config from
heuristics. This skill does the part that needs judgment: verifying the
detected values against the actual repo, registering every module, assigning
stack packs, and generating the context files downstream skills depend on.

## Usage

### Step 0 — Preflight

```bash
ls "./.craftkit" "./.craftkit-project" 2>/dev/null
sh ./.craftkit/bin/craftkit doctor || true
```

If `.craftkit/` is missing, stop and tell the user to run `craftkit init`
first (see ONBOARDING.md or the CraftKit README) — this skill configures an
installed kit; it does not vendor one.

### Step 1 — Complete project.yaml

Read `./.craftkit-project/project.yaml` and verify every detected value
against the repo:

1. **Modules:** the scaffold registers a single module at `.`. If this is a
   monorepo (multiple `build.gradle`/`pom.xml`/`package.json`/`go.mod`/… in
   subdirectories, a `settings.gradle` with includes, npm/pnpm workspaces),
   register one entry per module with its real `path`, `stack`, `build`, and
   `test` values. Mark vendored or upstream code `ownership: external`.
2. **Build/test commands:** confirm they exist (check `package.json` scripts,
   Gradle tasks, Makefile targets). Fix any `echo 'set …'` placeholders.
3. **Ticket prefix:** check `git log --oneline -50` — does the detected
   prefix match what the team actually uses? Fix `prefixes` and `system`
   (jira | github | linear) if not.
4. **Stack packs:** list available packs (`ls ./.craftkit/stacks/` and read
   each `pack.yaml` description). Assign a `stack_pack` to every module it
   matches; leave empty when none fits.
5. **Rules:** set `protected_files` to the repo's real lint/config files,
   list `framework_anchors` (e.g. spring-boot, react), and sanity-check
   `coverage_min`.
6. **Harnesses:** confirm the `harnesses:` list matches what the team uses.

If a value cannot be determined with confidence (e.g. which modules are
external, the real coverage gate), ask the user — do not guess.

### Step 2 — Sync shims if config changed

If you changed `harnesses:` or anything affecting shims:

```bash
sh ./.craftkit/bin/craftkit sync
```

### Step 3 — Generate context files

Read and follow `./.craftkit/skills/context-sync/SKILL.md` to generate
`./.craftkit-project/context/workspace.md` and a profile per module under
`./.craftkit-project/context/profiles/`.

### Step 4 — Fill documentation placeholders

Skim `AGENTS.md` and `ONBOARDING.md` for scaffold values that no longer match
the completed `project.yaml` (module lists, commands) and any obvious
template-ish placeholders; update them. Keep team-authored sections intact.

### Step 5 — Validate and report

```bash
sh ./.craftkit/bin/craftkit doctor
```

Then summarize: modules registered, stack packs assigned, profiles generated,
doctor result, and anything left for the team to review (especially values
you were unsure about). Remind the user to review and commit:
`.craftkit/`, `.craftkit-project/`, `AGENTS.md`, `ONBOARDING.md`, and the
generated harness files.

## Notes

- This skill modifies only `.craftkit-project/`, `AGENTS.md`,
  `ONBOARDING.md`, and (via `craftkit sync`) generated shims — never source
  code and never files under `.craftkit/`.
- Safe to re-run: it converges on the current repo state.
