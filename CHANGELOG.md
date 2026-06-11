# Changelog

## 0.4.1 — 2026-06-11

- Fix: the machine-wide `craftkit` (from install.sh) now delegates to the
  repo-vendored `.craftkit/bin/craftkit` when the two differ, so
  `craftkit update` takes effect immediately — a stale PATH copy no longer
  hides new commands


## 0.4.0 — 2026-06-11

Harness removal + safer updates on older repos.

- New `craftkit remove <harness>[,…]` command: deletes a harness's generated
  files (shims, marked blocks, symlinks) and updates `harnesses:` in
  project.yaml; `craftkit remove all` uninstalls CraftKit from the repo,
  keeping `artifacts/`, team-authored content in CLAUDE.md /
  copilot-instructions.md, and any AGENTS.md/ONBOARDING.md that predate it
- Fix: an explicit empty `harnesses: []` is no longer treated as "all"
- Fix: on pre-0.3 repos (project.yaml without a `harnesses:` key),
  `craftkit update`/`sync` now detect the enabled harnesses from the files
  present instead of regenerating all three; `update` backfills the
  `harnesses:` key with the detected list


## 0.3.1 — 2026-06-11

Documentation pass: crisper setup instructions.

- README: single "Get started" path (install → `craftkit init` → `/ck-init`);
  alternatives moved out
- New docs/installation.md: install options, harness selection/add/remove,
  what each harness generates, updating and version pinning
- multi-repo guide: setup flow uses `/ck-init`; context-sync kept for
  profile refresh
- ONBOARDING template: points at the repo's `harnesses:` list instead of
  assuming all three harnesses
- install.sh: post-install hint mentions the harness prompt and `/ck-init`


## 0.3.0 — 2026-06-11

Harness selection + agent-side setup skill.

- `craftkit init` now requires a harness choice (claude-code, copilot-cli,
  pi): interactive runs are prompted; non-interactive runs must pass
  `--harnesses a,b` (or `--harnesses all`)
- Re-running `craftkit init` merges new selections into the existing
  `harnesses:` list — adding a harness later is `craftkit init --harnesses pi`
- `project.yaml`: new `harnesses:` list records the choice; `sync` runs only
  the enabled adapters and `doctor` checks only their shims
- Copilot CLI adapter now emits native skill shims
  (`.github/skills/ck-*/SKILL.md`, per GitHub's "Add skills to Copilot CLI"
  guide) instead of `.github/agents/ck-*.md` custom agents; legacy agent
  shims are removed on sync
- New `init` skill (`/ck-init`): finishes setup after `craftkit init` —
  completes project.yaml (modules, commands, stack packs), fills AGENTS.md /
  ONBOARDING.md placeholders, generates context files via context-sync, runs
  doctor


## 0.2.0 — 2026-06-10

Stack packs: per-module stack opinion without context bloat.

- New `kit/stacks/` layer: packs supply small, single-consumer context files
  (conventions for implement/review/feedback; deps-update playbook; triage
  heuristics; profile template for context-sync), each with a line cap
- First pack: `java21-spring-gradle` (Java 21 / Spring Boot 3.x / Gradle)
- `project.yaml`: per-module `stack_pack:` field; `craftkit init` auto-detects
  Gradle + Spring Boot and pre-fills it
- CLI: new `craftkit stacks` command; `doctor` validates referenced packs;
  packs vendored to `.craftkit/stacks/` and updated with the kit
- Skills load only their own pack file, on demand, for impacted modules only;
  precedence: coding-standards > module profile > pack conventions
- docs/stack-packs.md: activation + authoring guide (with context budget rules)
- Fix: init no longer aborts on BSD grep exit-2 when probing optional files


## 0.1.0 — 2026-06-10

Initial release.

- 11 phase skills: requirements, tickets, tech-spec, execution-plan,
  implement, review, feedback, ship, triage, deps-update, context-sync
- 5 workflows: feature, bugfix, deps, review, onboard
- Shared references: escalation protocol, artifact conventions
- `craftkit` CLI: init, sync, update, doctor, version
- Harness adapters: Claude Code, pi, GitHub Copilot CLI
- Templates: project.yaml, AGENTS.md, ONBOARDING.md
