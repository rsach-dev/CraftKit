# Usage Guide: `/ck-deps`

Routine dependency maintenance for one module or all team-owned modules:
discover newer versions, bump safely, verify with a full build, commit, and
optionally ship.

## When to use it

- Scheduled dependency hygiene (e.g. monthly bumps, CVE-driven updates).
- **Not** for framework major migrations — that's feature work
  (`/ck-feature`); this workflow refuses major bumps of framework anchors by
  design.

## What you need before starting

| Input | Required | Notes |
|-------|----------|-------|
| Ticket ID | yes | Used for the branch, commit, and artifact |
| Module name or `all` | yes | `all` = every `ownership: team` module, processed independently |
| `rules.framework_anchors` configured | recommended | e.g. `[spring-boot]`, `[react]` — see below |

## The guardrails (what it will and won't do)

| It will | It won't |
|---------|----------|
| Bump anchors to the latest **minor/patch** within the current major | Cross an anchor's **major** version, ever |
| Bump everything else to the latest stable | Pick RCs, betas, milestones, snapshots |
| Remove version pins that shadow a BOM/platform | Remove a pin that looks deliberate (it asks first) |
| Edit version strings and regenerate lockfiles | Restructure build files, change scopes, touch lint/coverage/test config |
| Step a breaking library back and defer it | "Fix" your code to chase a dependency |

**Framework anchors** are the libraries whose major version defines your
platform (Spring Boot, React, Django, …). List them in `project.yaml` under
`rules.framework_anchors`; companions (e.g. Spring Cloud) are matched to the
anchor via the official compatibility matrix or escalated.

## What happens

1. **deps-update skill** runs per module: inventory manifests → discover
   latest versions via the package manager's own report (no web access) →
   build the update table → apply → full build → one commit on a
   `{TICKET}-deps-update` branch → `artifacts/{TICKET}/6-deps-update.md`.
2. **Gate:** you see anchors old→new, counts of updated/pin-removed/deferred,
   and build status, then choose: ship now, inspect the diff first, or stop
   with the commit local.
3. **ship** (if chosen) pushes the branch and generates the PR description.

The artifact's **Deferred Updates** table is the to-do list it leaves behind:
every bump it skipped and why (needs next anchor major, needs code migration,
pre-release only).

## Worked example

```
/ck-deps
> Ticket: PROJ-3105
> Module: all
```

Three modules processed one at a time, each with its own branch, commit,
artifact, and ship decision — a build failure in one never blocks the others.

## When it escalates

- A version pin looks deliberate (predates the BOM, has a comment) — confirm
  whether to keep or drop it.
- Anchor↔companion compatibility can't be determined locally — supply the
  matrix version.
- The registry is unreachable — supply target versions manually.
- An anchor minor bump breaks the build — decide: defer the anchor, or
  authorize code changes (which become implement-skill work).

## Tips

- Nothing is pushed unless you choose ship at the gate; "stop here" leaves a
  clean local branch you can inspect with `git diff {default-branch}`.
- Re-run on the same ticket later — already-current dependencies are no-ops.
- Source code is never read by this workflow; if a decision seems to need
  code analysis, that's exactly when it escalates.
