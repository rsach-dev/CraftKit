---
name: deps-update
description: "Updates a module's dependency versions in its package-manager manifest (Gradle, Maven, npm, pip, cargo, go modules). Framework anchors declared in project.yaml (e.g. Spring Boot, React) are restricted to minor/patch bumps — never a major bump. All other libraries may move to their latest stable versions as long as they are compatible with the anchors. Verifies with a full build and commits per module. Escalates when version conflicts, breaking API changes, or compatibility ambiguity cannot be resolved with 100% confidence."
---

# deps-update — Dependency Updates

## Overview

Takes a module name (or `all` for every team-owned module) and updates its
dependency versions. This skill is the **sole sanctioned exception** to the
"never modify protected files" rule — it may edit package-manager manifests
and lockfiles (`build.gradle`, `pom.xml`, `package.json`, `requirements.txt`,
`Cargo.toml`, `go.mod`, version catalogs, …) **only to change dependency/
plugin versions**. It must never weaken or alter lint, static-analysis,
coverage, or any quality-gate configuration.

## Hard Constraints

| Constraint | Rule |
|------------|------|
| **Framework anchors** (from `project.yaml` `rules.framework_anchors`) | **NEVER bump the major version.** If current is `3.x`, the target must stay `3.y.z` — even if a newer major is available. |
| Anchor minor/patch | Allowed — bump to the latest minor/patch within the same major. |
| Anchor companions (e.g. Spring Cloud for Spring Boot) | Must match the chosen anchor version per the official compatibility matrix. If unsure of the matching version, escalate. |
| All other libraries | No version limits, **but** they must be compatible with the updated anchors. |
| BOM/platform-managed dependencies | If a library's version is managed by a platform/BOM, **remove the explicit version pin** rather than bumping it — unless the pin exists to override a known issue (check git blame/comments; if unclear, escalate). |
| Language/runtime version | Never change the language toolchain or runtime version. |
| Quality gates | Never touch lint, static-analysis, coverage, or test configuration. |
| External modules | `ownership: external` is read-only. Refuse and tell the user if asked. |
| Pre-releases | Skip release candidates, milestones, alphas, betas, snapshots (`-RC`, `-M`, `-alpha`, `-beta`, `-SNAPSHOT`, `next`, `canary`). |

## Escalation Protocol

Read and follow `./.craftkit/skills/references/escalation-protocol.md`.
Phase name: `deps-update`. Escalation file:
`artifacts/{TICKET}/escalations/deps-update.md`.

## Inputs

The user must provide:
1. **Ticket ID** — e.g. `PROJ-1234` (artifact naming + commit prefix)
2. **Module name** — must match a **team-owned** module in `project.yaml`,
   or `all` for every team-owned module

If any input is missing, ask the user before proceeding.

## Usage

### Step 1 — Validate inputs

```bash
cat "./.craftkit-project/project.yaml"
```

- If the module is not in the registry, list valid options and STOP.
- If the module is `ownership: external`, refuse — external modules are
  read-only. STOP.
- Note the module's package manager from its manifest files, and the
  configured `rules.framework_anchors`.

### Step 2 — Check for existing escalations

```bash
TICKET="PROJ-XXXX"
ESCALATION="./artifacts/$TICKET/escalations/deps-update.md"
if [ -f "$ESCALATION" ]; then cat "$ESCALATION"; fi
```

If the file exists:
1. Any `<!-- PENDING -->` markers → tell the user which questions are unanswered, STOP.
2. Read all answers from all rounds. If they don't give 100% confidence, append a new `## Round N` with follow-ups and STOP.
3. If confident, set frontmatter `status: resolved` and continue from where the escalation paused.

### Step 3 — Refresh code (pre-flight)

Ensure the module is on the latest default branch and the working tree is
clean (dirty → tell the user to commit/stash; STOP). Then create a working
branch:

```bash
cd {module-path}
git checkout -b "{TICKET}-deps-update"
```

### Step 4 — Inventory current dependencies

Read **only** the manifest/lock files — not source code. Record:
- Current version of every framework anchor → derive each **major version ceiling**
- Every explicitly pinned dependency and plugin version
- Which pins shadow a platform/BOM-managed version

Capture the current resolved dependency tree to a temp file for the
before/after diff (e.g. `./gradlew dependencies`, `mvn dependency:tree`,
`npm ls --all`, `pip freeze`, `cargo tree`, `go list -m all` — pipe through
`head`, never dump full reports into the conversation).

### Step 5 — Discover latest available versions

Do NOT use web tools. Use the package manager's own outdated/update report
against its already-configured registries:

| Ecosystem | Command |
|-----------|---------|
| Gradle | `dependencyUpdates` via the versions plugin applied through an **init script** (never modify the build file to add a plugin) |
| Maven | `mvn versions:display-dependency-updates` |
| npm/pnpm/yarn | `npm outdated` / `pnpm outdated` |
| pip | `pip list --outdated` |
| cargo | `cargo update --dry-run` |
| go | `go list -u -m all` |

If the registry is unreachable (offline/proxy-restricted environment),
escalate asking the user to supply target versions.

From the report, build the **update table**:

| Dependency | Current | Latest | Target | Reason |
|------------|---------|--------|--------|--------|

Target selection rules:
- **Framework anchors:** latest version with the **same major**. If the
  report only shows a new major, find the latest within the current major
  line. Never select across the major boundary.
- **Anchor companions:** the version documented as compatible with the target
  anchor. If you cannot determine this from the report or local docs, escalate.
- **Platform/BOM-managed libs with explicit pins:** target = "remove pin".
- **Everything else:** latest stable release (no pre-releases).

### Step 6 — Confidence gate

Escalate (write the escalation file and STOP) if ANY apply:

| Trigger | Example |
|---------|---------|
| A pinned version appears to deliberately override the platform/BOM | Pin predates the managed version, with a comment or suspicious history |
| A library's latest major has breaking API changes used by this module | e.g. major bump of a serialization or HTTP client lib |
| Companion compatibility with the target anchor version is unclear | No matrix info available locally |
| The latest version of a lib only supports a newer anchor major | Compatible ceiling unclear |
| A shared manifest/catalog spans modules with different anchor majors | A bump in one breaks another |

Each question must include `**Context:**` and `**Impact:**` per the protocol.

### Step 7 — Apply updates

Edit version strings **only** — in manifests, version properties, and version
catalogs. Do not restructure the build file, reorder dependencies, change
dependency scopes/configurations, or touch anything unrelated to versions.
Regenerate the lockfile with the package manager (never hand-edit lockfiles).

### Step 8 — Verify

```bash
cd {module-path} && {build command from project.yaml}
```

- **Build passes** → proceed to Step 9.
- **Compile/test failure caused by a non-anchor library bump** → step that
  library back one major at a time (max 2 attempts). Fix the version, **never
  the quality-gate configs**, and never "fix" code to chase a dependency — if
  a code change would be required to adopt a version, exclude that bump and
  record it in the artifact's `Deferred` section, or escalate if the user
  likely wants the code migration.
- **Failure caused by an anchor minor bump** → escalate with the failure
  output; the human decides between deferring the anchor bump or authorizing
  code changes (code migration is implement-skill territory, not this skill).

After a passing build, capture the resolved dependency tree again and diff it
against the "before" capture (pipe through `head -200`).

### Step 9 — Commit

Single batch commit per module — version files only, do **not** push (pushing
and PR creation is the ship skill's job):

```bash
cd {module-path}
git add {manifest, lockfile, and version-catalog files only}
git commit -m "{TICKET}: Update dependencies ({anchor} {old} -> {new})"
```

### Step 10 — Write artifact

```bash
mkdir -p "./artifacts/$TICKET"
```

Write `artifacts/{TICKET}/6-deps-update.md`:

```markdown
---
ticket: {TICKET}
module: {module-name}
date: {YYYY-MM-DD}
status: approved
anchors: "{anchor}: {old} -> {new}"
---
# Dependency Update: {TICKET}

## Summary

{1-2 sentences: how many dependencies updated, anchor old -> new (same
major), build result.}

## Framework Anchors

| Anchor | Before | After |
|--------|--------|-------|
| {name} | {x.y.z} | {x.y'.z'} (major {x} unchanged) |

## Updated Dependencies

| Dependency | Before | After | Notes |
|------------|--------|-------|-------|

## Pins Removed (now platform-managed)

| Dependency | Removed Pin | Managed Version |
|------------|------------|-----------------|

## Deferred Updates

| Dependency | Latest | Reason Deferred |
|------------|--------|-----------------|
{e.g. "requires {anchor} next major", "requires code migration", "RC only"}

## Verification

- Build: PASS
- Resolved dependency tree diff reviewed: yes
```

### Step 11 — Report

Print:
- Artifact path: `artifacts/{TICKET}/6-deps-update.md`
- Anchors: `{old} → {new}` (majors unchanged)
- Updated: {N} dependencies, {M} pins removed, {K} deferred
- Build: PASS
- Escalation rounds completed: {N} (or 0)
- Next steps: "Run the ship skill with {TICKET} to push and open the PR."

If the user asked for `all`, repeat Steps 3–11 per team-owned module, one
branch and one commit each.

## Token Management Summary

| Action | Budget |
|--------|--------|
| Manifest/lockfile reads | All manifest files of the target module (small) |
| Source code reads | **None** — this skill never reads `src/`. If a decision needs source analysis, escalate. |
| Package-manager reports | Pipe through `head`/`diff`; never dump full reports into context |
