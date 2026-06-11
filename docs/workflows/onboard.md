# Usage Guide: `/ck-onboard`

An interactive, ~20-minute guided tour for an engineer who has never used
CraftKit (or never used it in this repo). No source code is touched, nothing
is pushed.

## When to use it

- A new engineer's first session in the repo.
- An existing engineer's first contact with CraftKit.
- A refresher after the kit or the module registry changed substantially.

## What you need before starting

- A cloned repo with CraftKit installed (`craftkit doctor` passes).
- Ideally, module profiles already generated (`/ck-context-sync`) and at
  least one completed `artifacts/{TICKET}/` directory to use as a worked
  example — not required, but it makes Part 2 much better.

## What happens

The tour runs in four parts, pausing for you between each:

1. **The lay of the land** — the agent summarizes `AGENTS.md` and
   `project.yaml`: what modules exist, team vs. external ownership (and what
   read-only means), build commands, ticket/commit format.
2. **How the pipeline works** — the 8 phases and their artifacts, plus the
   two safety rules: human gates (nothing auto-advances) and the escalation
   protocol (the agent asks instead of guessing). If a finished ticket
   exists in `artifacts/`, it's walked through as a real example.
3. **Toy run** — the heart of the tour. Using ticket `ONBOARD-1` and a
   deliberately under-specified toy feature, the requirements skill runs and
   **escalates on purpose**. You open the escalation file, replace
   `<!-- PENDING -->` markers with answers, re-run, and watch the approved
   artifact appear. Optionally continue through tech-spec and execution-plan.
   The toy run stops before implement — it never modifies source code.
4. **Wrap up** — a cheat sheet of the day-to-day commands and where
   everything lives (also in `ONBOARDING.md` for later).

## Why the toy escalation matters

The answer-and-rerun loop is the one CraftKit habit that doesn't exist in
ad-hoc agent usage, and reading about it doesn't stick. Experiencing it on a
throwaway ticket means the first *real* escalation feels routine instead of
like an error.

## After the tour

- Keep or delete `artifacts/ONBOARD-1/` (the tour asks; keeping it gives the
  next newcomer an example).
- Suggested first real task: a small ticket via `/ck-bugfix` or a
  single-module `/ck-feature`, reading each artifact fully before approving
  its gate — that reading *is* the training.
- Browse a senior engineer's completed `artifacts/{TICKET}/` directory,
  including `escalations/` — it records the questions experts asked and the
  decisions made, with reasoning.
