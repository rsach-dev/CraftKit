# Usage Guide: `/ck-review`

Review implemented work against the ticket's requirements and execution plan,
with an optional fix loop — repeat feedback → re-review until `pass`.

## When to use it

- Before opening a PR for work done via `/ck-feature` or `/ck-bugfix`
  (especially in a fresh conversation after implement — recommended).
- To apply a human reviewer's PR comments (the feedback loop applies them and
  can persist reusable standards).
- For an **ad-hoc** quality review of a branch that wasn't built through the
  pipeline — requirements coverage is marked N/A and you still get build,
  lint, coverage, and issue analysis.

## What you need before starting

| Input | Required | Notes |
|-------|----------|-------|
| Ticket ID | yes | |
| `1-requirements.md` + `3-execution-plan.md` approved | for full review | Without them, only the ad-hoc quality review runs |
| Base branch | if not the default branch | The diff is computed against it |

## What happens

1. **review skill**: refreshes the module, diffs against the base branch,
   runs the full build, then checks
   - **requirements coverage** — each acceptance criterion mapped to code
     *and* a covering test (✅ / ⚠️ / ❌),
   - **plan adherence** — planned vs. actual files, unplanned changes,
   - **code quality** — lint, tests, coverage ≥ `rules.coverage_min`,
   and writes `artifacts/{TICKET}/4-review.md` with a verdict:
   `pass` | `pass-with-notes` | `fail`.
2. **Gate:** on pass → ship or stop. On notes/fail → fix all, fix selected,
   or handle manually.
3. **feedback loop** (optional, repeatable): each comment is classified as a
   one-off `code-fix` or a reusable `standard`. Standards are appended to
   `.craftkit-project/context/coding-standards.md` and enforced by **all
   future implement runs** — this is how the pipeline learns your team's
   taste. Fixes are applied, builds re-run, and you can re-review.
4. **ship** (optional) once you're satisfied.

## Worked example — applying PR comments

```
/ck-review
> Ticket: PROJ-1234
> Comments from the PR:
> - "OrderMapper should use Optional.ofNullable instead of null checks"
> - "Tests should have no more than 5 assertions each"
```

Comment 1 → `code-fix`, applied to the mapper. Comment 2 → `standard`,
persisted to coding-standards.md *and* applied to the new tests. Build rerun,
re-review offered.

## When it escalates

The review skill never fudges a verdict. It escalates when:

- an acceptance criterion is satisfiable under one reading but not another —
  you say which reading was intended;
- tests exist but may not cover the edge cases a criterion implies;
- the implementation deviates from the plan but might still satisfy the
  requirement differently;
- a metric is exactly borderline.

Answer in `artifacts/{TICKET}/escalations/review.md` and re-run.

## Tips

- A single pass with no fixes is exactly the review phase skill — the
  workflow only adds the loop and the ship hand-off.
- The review artifact is the PR's best companion — link it; it shows
  criterion-by-criterion evidence.
- Seed `coding-standards.md` proactively with your team's known rules; you
  don't have to wait for review comments.
