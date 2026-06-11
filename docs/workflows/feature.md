# Usage Guide: `/ck-feature`

Build a feature end-to-end: requirements → tech spec → execution plan →
implement → review → ship, with you approving every phase boundary.

## When to use it

- You have a ticket and a description (even a rough one — Slack thread,
  meeting notes, a paragraph) and want it taken to a pushed branch + PR.
- Prefer the individual phase commands instead when you only need one phase
  (e.g. just a tech spec for an estimate).

## What you need before starting

| Input | Required | Notes |
|-------|----------|-------|
| Ticket ID | yes | Must use a prefix from `project.yaml` (e.g. `PROJ-1234`) |
| Feature description | yes for phase 1 | Any raw form; the requirements skill structures it |
| Clean module checkouts | yes | Skills refuse dirty working trees |

## What happens, phase by phase

| # | Phase | Produces | You approve |
|---|-------|----------|-------------|
| 1 | requirements | `artifacts/{TICKET}/1-requirements.md` | problem statement, acceptance criteria, scope, impacted modules |
| 2 | tickets *(optional)* | copy-paste ticket text | the breakdown before it goes in your tracker |
| 3 | tech-spec | `2-tech-spec.md` | approach, file-level impact, API/schema changes, risks |
| 4 | execution-plan | `3-execution-plan.md` | ordered steps with exact file paths |
| 5 | implement | code + one commit per module | build results before review |
| 6 | review | `4-review.md` (pass / pass-with-notes / fail) | the verdict and any issues |
| 7 | feedback *(optional)* | targeted fixes | repeat until satisfied |
| 8 | ship | pushed branch + PR description | the final PR text |

At each gate the workflow prints a ≤10-line summary and numbered options,
then **stops**. Nothing advances without your choice; nothing is pushed
before phase 8.

## Worked example

```
/ck-feature
> Ticket: PROJ-1234
> Description: When a customer removes the last item from a cart, the cart
> should be deleted and the promo code released. See thread: ...
> Scope: full pipeline
```

Typical session: phase 1 escalates two questions about promo-code edge cases
→ you answer them in `artifacts/PROJ-1234/escalations/requirements.md` →
re-run → approve requirements → approve spec → approve plan → implement runs
builds → you start a fresh conversation for review (recommended) → pass →
ship.

## When it escalates

Any phase that lacks 100% confidence writes
`artifacts/{TICKET}/escalations/{phase}.md` and stops. Answer each
`<!-- PENDING -->`, then tell the workflow to continue (it re-runs the same
phase with your answers). See
`.craftkit/skills/references/escalation-protocol.md`.

## Resuming

State lives entirely in `artifacts/` and git — conversations are disposable.

```
Resume the feature workflow for PROJ-1234 at phase review
```

The workflow checks which artifacts exist and are `approved`, then jumps to
the right phase. **Always start a fresh conversation after implement** — the
workflow will recommend it; take the recommendation.

## Tips

- Force a phase to re-run by editing its artifact's `status:` away from
  `approved`.
- If the plan flags changes in an `ownership: external` module, the workflow
  stops immediately — decide whether to skip those steps, take
  responsibility, or abort.
- Reviewer pushed back on the PR? Run `/ck-review` with their comments — the
  feedback skill applies them and can persist reusable standards.
