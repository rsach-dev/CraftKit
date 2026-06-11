# Usage Guide: `/ck-bugfix`

Take a bug from evidence (trace, stack trace, error log, or description) to a
shipped fix: triage → lite plan → implement → review → ship.

## When to use it

- Something is broken and you have *any* evidence: an observability trace, a
  stack trace, error log lines, or even just reproducible symptoms.
- Use `/ck-triage` alone instead if you only want the root-cause analysis
  (e.g. to decide priority) without fixing yet — the artifact is reusable;
  `/ck-bugfix` will pick it up later and skip straight past triage.

## What you need before starting

| Input | Required | Notes |
|-------|----------|-------|
| Ticket ID | yes | e.g. `PROJ-1234` |
| Module name | yes | Must match a `modules:` entry in `project.yaml` |
| Bug evidence | yes | Trace, stack trace, log lines, or a symptom description. More signal = fewer escalations |

## What happens, phase by phase

| # | Phase | Produces | You approve |
|---|-------|----------|-------------|
| 1 | triage | `artifacts/{TICKET}/5-triage.md` | the root cause + **which fix** (ranked options with risk/effort) |
| 2 | execution-plan (lite) | `3-execution-plan.md` | steps for the chosen fix, incl. closing the test gaps triage found |
| 3 | implement | code + commit per module | build results |
| 4 | review | `4-review.md` | verdict against "bug gone + test gaps closed" |
| 5 | ship | pushed branch + PR description | final PR text |

The triage gate is the important one: you pick **Fix 1 (recommended)** or any
alternative before a line of code changes.

## Worked example

```
/ck-bugfix
> Ticket: PROJ-2231
> Module: order-service
> Bug: 500s on POST /api/v1/orders since yesterday's deploy. Stack trace:
> java.lang.NullPointerException: discount
>     at OrderMapper.toEntity(OrderMapper.java:42) ...
```

Triage scans narrowly (the named class first, then callers — never the whole
repo), produces a root cause with an evidence chain, 2–4 ranked fixes, the
test gap that let it through, and a prevention note. You pick a fix; the rest
runs like a small feature.

## How triage stays cheap

Triage is deliberately token-conscious: direct-hit search → immediate
callers → **stop**. If it has read ~15 files without certainty it escalates
and asks you to narrow the scope rather than reading the codebase. Giving it
a precise signal up front (exact error + endpoint) usually means zero
escalations.

## When it escalates

Common triage escalations and what to answer:

- *Multiple plausible root causes* → say which component owns the invariant.
- *Root cause spans modules* → tell it which side to fix.
- *Needs the triggering payload* → paste a sample request/event.
- *Fix would land in an `ownership: external` module* → decide: coordinate
  externally, or approve a defensive fix on our side.

## Resuming

Same as the feature workflow — artifacts carry all state:

```
Resume the bugfix workflow for PROJ-2231 at phase implement
```

A completed `5-triage.md` is never recomputed; the workflow goes straight to
planning the chosen fix.
