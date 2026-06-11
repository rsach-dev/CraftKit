# CraftKit — Architecture

> An open-source, portable, versioned kit of agent skills and workflows that any
> repository can pull and initialize with a single command. Works identically
> across **pi**, **Claude Code**, and **GitHub Copilot CLI**, and makes coding
> agent–driven development structured, auditable, and easy to teach.

---

## 1. Goals

| # | Goal | Consequence for the design |
|---|------|---------------------------|
| G1 | Any repo can adopt the kit with one init command | Kit is a self-contained git repo + bootstrap script; no central server required |
| G2 | One skill definition, three harnesses (pi, Claude Code, Copilot CLI) | Skills are harness-agnostic markdown; harness compatibility is achieved through thin, **generated** adapter shims |
| G3 | Higher-level commands for everyday work | A `workflows/` layer composes skills into intents (`/ck-feature`, `/ck-bugfix`, `/ck-deps`, `/ck-review`) so engineers don't need to know phase names |
| G4 | Trainable for new engineers | Every run leaves a readable artifact trail; the escalation protocol forces explicit Q&A instead of silent guessing; an onboarding doc ships with the kit |
| G5 | Upgradable without losing local customization | Strict separation of **kit-owned** files (overwritten on update) and **repo-owned** files (generated once, never overwritten) |

### Non-goals

- Not a runtime or daemon. The kit is files: markdown + a small bootstrap script.
- Not a replacement for CI. Skills run inside an engineer's agent session.
- No telemetry or server component in v1.

---

## 2. Core Idea: One Source of Truth, Thin Adapters

Skills live once under `skills/<name>/SKILL.md`, and each harness gets a
one-line shim that says *"Read and follow `./.craftkit/skills/<name>/SKILL.md`"*.
The skill body is plain imperative markdown (steps, bash snippets, output
templates) that any capable coding agent can execute — that is what makes
tri-harness support cheap.

```
                       ┌────────────────────────────────┐
                       │   .craftkit/skills/*/SKILL.md  │   single source of truth
                       │   .craftkit/workflows/*.md     │   (kit-owned, versioned)
                       │   .craftkit/references/*.md    │
                       └───────────────┬────────────────┘
                                       │  craftkit init / craftkit sync (generates shims)
            ┌──────────────────────────┼──────────────────────────┐
            ▼                          ▼                          ▼
   .claude/commands/*.md       .pi/ (native discovery      .github/agents/*.md
   .claude/settings.json        of skills/ + context)      copilot-instructions.md
        Claude Code                     pi                  GitHub Copilot CLI
```

Adapters are **generated, never hand-edited**. Regenerating them is idempotent
(`craftkit sync`), which is also how harness support evolves: a new harness = a
new generator, zero changes to skill content.

---

## 3. Repository Layouts

### 3.1 The kit repo (`craftkit`, this repo)

```
craftkit/
├── ARCHITECTURE.md                ← this document
├── LICENSE                        ← permissive OSS license (MIT or Apache-2.0)
├── VERSION                        ← semver, single line (e.g. 1.4.0)
├── CHANGELOG.md
├── bin/
│   └── craftkit                   ← POSIX-sh bootstrap/CLI (init, sync, update, doctor)
├── kit/                           ← everything copied into consumer repos
│   ├── skills/
│   │   ├── requirements/SKILL.md
│   │   ├── tickets/SKILL.md
│   │   ├── tech-spec/SKILL.md
│   │   ├── execution-plan/SKILL.md
│   │   ├── implement/SKILL.md
│   │   ├── review/SKILL.md
│   │   ├── feedback/SKILL.md
│   │   ├── ship/SKILL.md
│   │   ├── triage/SKILL.md
│   │   ├── deps-update/SKILL.md
│   │   ├── context-sync/SKILL.md
│   │   └── references/
│   │       ├── escalation-protocol.md
│   │       └── artifact-conventions.md
│   ├── workflows/                 ← higher-level commands (see §5)
│   │   ├── feature.md             ← /ck-feature  (full 8-phase pipeline)
│   │   ├── bugfix.md              ← /ck-bugfix   (triage → plan → implement → ship)
│   │   ├── deps.md                ← /ck-deps     (dependency updates)
│   │   ├── review.md              ← /ck-review   (review-only)
│   │   └── onboard.md             ← /ck-onboard  (interactive new-engineer tour)
│   ├── stacks/                    ← stack packs (see §5.5)
│   │   └── java21-spring-gradle/
│   │       ├── pack.yaml
│   │       ├── conventions.md
│   │       └── references/{deps-update,triage,profile-template}.md
│   └── templates/
│       ├── project.yaml.tmpl      ← per-repo config template
│       ├── AGENTS.md.tmpl
│       └── ONBOARDING.md.tmpl
├── adapters/                      ← shim generators, one per harness
│   ├── claude-code.sh
│   ├── pi.sh
│   └── copilot-cli.sh
└── tests/
    └── smoke.sh                   ← lints frontmatter, checks cross-references, runs init into a tmp repo
```

### 3.2 A consumer repo after `craftkit init`

```
any-repo/
├── .craftkit/                     ← KIT-OWNED (vendored copy of kit/, overwritten by `craftkit update`)
│   ├── KIT_VERSION                ← pinned kit version this repo is on
│   ├── skills/…
│   ├── workflows/…
│   ├── stacks/…
│   └── templates/…
├── .craftkit-project/             ← REPO-OWNED (generated once by init, then yours)
│   ├── project.yaml               ← stack, build commands, conventions, ownership (see §6)
│   ├── context/
│   │   ├── workspace.md           ← module registry + conventions (~40 lines)
│   │   └── profiles/*.md          ← per-module coding patterns, regenerated by context-sync
│   └── overrides/                 ← optional skill overrides (see §8.3)
├── artifacts/                     ← pipeline output, one dir per ticket (gitignore optional, per team)
│   └── {TICKET}/
│       ├── 1-requirements.md … 4-review.md
│       └── escalations/{phase}.md
├── AGENTS.md                      ← generated; harness-neutral entry point (pi + Copilot read this natively)
├── ONBOARDING.md                  ← generated; new-engineer guide
├── .claude/
│   ├── commands/ck-*.md           ← generated shims
│   └── settings.json              ← merged, not overwritten
├── .pi/ → (symlink or pointer into .craftkit-project/context)
└── .github/
    ├── copilot-instructions.md    ← generated; points at AGENTS.md + workflow index
    └── agents/ck-*.md             ← generated Copilot custom-agent shims
```

**Ownership rule (the contract that makes updates safe):**

| Path | Owner | On `craftkit update` |
|------|-------|----------------------|
| `.craftkit/` | kit | replaced wholesale |
| Generated shims (`.claude/commands/ck-*`, `.github/agents/ck-*`, `copilot-instructions.md` craftkit block) | kit | regenerated |
| `.craftkit-project/`, `AGENTS.md`, `ONBOARDING.md`, `artifacts/` | repo | never touched (init writes them only if absent) |

---

## 4. The `craftkit` CLI

A single dependency-free shell script, installed by the bootstrap one-liner:

```bash
# put `craftkit` on your PATH (one time):
curl -fsSL https://raw.githubusercontent.com/rsach-dev/CraftKit/main/install.sh | sh
# in any repo root:
craftkit init
# or one-shot without installing:
curl -fsSL https://raw.githubusercontent.com/rsach-dev/CraftKit/main/bin/craftkit | sh -s init
# or, once vendored:
.craftkit/bin/craftkit <command>
```

| Command | What it does |
|---------|--------------|
| `craftkit init` | Clones/copies the kit at the latest tag into `.craftkit/`; **detects the repo** (Gradle/Maven/npm/cargo/multi-module, test runner, commit conventions from git log); fills `project.yaml`, `AGENTS.md`, `ONBOARDING.md` from templates; runs all adapter generators; prints next steps. Interactive prompts only where detection fails. |
| `craftkit sync` | Regenerates harness shims from `.craftkit/` + `project.yaml`. Run after editing `project.yaml` or adding overrides. |
| `craftkit update [--to X.Y.Z]` | Replaces `.craftkit/` with the requested kit version, re-runs `sync`, prints the CHANGELOG delta. Repo-owned files untouched. |
| `craftkit doctor` | Validates the install: shims in sync, `project.yaml` schema, dangling artifact references, harness configs present. |

Why shell and not node/python: `sh` and `git` exist on every developer machine;
init must work before any toolchain is set up — including in a freshly cloned
repo on a new engineer's first day.

---

## 5. Command Layers: Workflows over Skills

Engineers (especially new ones) should express **intent**, not pipeline phases.
The kit therefore exposes two tiers, both available as slash commands in every
harness:

### Tier 1 — Workflows (the everyday surface)

| Command | Composes | When to use |
|---------|----------|-------------|
| `/ck-feature` | requirements → [tickets] → tech-spec → execution-plan → implement → review → [feedback]* → ship, with a **mandatory human gate at every phase boundary** | "Build this feature" |
| `/ck-bugfix` | triage → execution-plan(lite) → implement → review → ship | "This is broken" |
| `/ck-deps` | deps-update (standalone) | Routine dependency bumps |
| `/ck-review` | review (+ optional feedback loop) | Review an existing branch/PR |
| `/ck-onboard` | Guided tour: reads AGENTS.md, walks one toy ticket end-to-end through the pipeline against a scratch artifact dir | New engineer's first day |

Workflows are themselves markdown documents (`.craftkit/workflows/*.md`)
following an orchestrator pattern: gate-check existing artifacts to support
**resume**, load one phase's skill at a time, summarize instead of echoing,
monitor token budget, and always pause at phase gates. A workflow never contains
domain logic — it only sequences skills and gates.

### Tier 2 — Skills (the building blocks)

Individual phases remain directly invokable (`/ck-tech-spec`, …) for power
users resuming mid-pipeline or running a single phase. Workflows and skills
share one flat `/ck-<name>` namespace; where a name appears in both tiers
(`review`), the workflow owns the shim and a single pass through it is
equivalent to running the phase skill. Each skill:

- has YAML frontmatter (`name`, `description`) — the only structured metadata harnesses need;
- consumes exactly one upstream artifact and produces exactly one output;
- enforces the **artifact status gate**: refuses input artifacts without `status: approved`;
- follows the shared **escalation protocol** (binary confidence: produce the artifact with 100% clarity, or write `artifacts/{TICKET}/escalations/{phase}.md` and stop).

The escalation protocol and artifact conventions live in
`kit/skills/references/` — they are the kit's most valuable assets for
trainability (see §9).

### 5.5 — Stack Packs (opinion without bloat)

Skills are stack-neutral, which caps output quality: "follow module
conventions" produces weaker code than stack-specific rules. Stack packs add
that opinion as **layered context, not forked skills**:

- A pack (`kit/stacks/<name>/`) is a handful of small markdown files, each
  with **exactly one consumer skill and a line cap**: `conventions.md`
  (~60 lines → implement/review/feedback), `references/deps-update.md`
  (≤100 → deps-update), `references/triage.md` (~60 → triage),
  `references/profile-template.md` (~50 → context-sync). All files optional.
- Modules opt in per-module via `stack_pack:` in `project.yaml`; `craftkit
  init` pre-fills it from detection. Mixed-stack workspaces work naturally —
  each module loads only its own pack, or none.
- **Context budget is the design constraint:** a skill never loads a whole
  pack, only its single file, only for impacted modules. Precedence:
  repo coding-standards > module profile > pack conventions > skill text.
- Packs are kit content: versioned, vendored to `.craftkit/stacks/`, updated
  with `craftkit update`, validated by `doctor`, listed by `craftkit stacks`.

First pack: `java21-spring-gradle` (Java 21 / Spring Boot 3.x / Gradle).
Authoring rules live in `docs/stack-packs.md`.

---

## 6. `project.yaml` — The Per-Repo Contract

Skills must work in *any* repo, so everything repo-specific is externalized into
one file the skills read at the start of every run:

```yaml
# .craftkit-project/project.yaml
kit_version: 1.4.0
ticket:
  prefixes: [PROJ]
  commit_format: "{TICKET}: {description}"
modules:
  - name: api-service
    path: .                        # or subdir for monorepos / workspace repos
    ownership: team                # team | external (external ⇒ read-only)
    stack: "Spring Boot / Java 21 / Gradle"
    build: "./gradlew build"
    test: "./gradlew test"
rules:
  protected_files:                 # never modified by any skill
    - "build.gradle"               # (deps-update has a scoped exemption for versions)
    - "config/lint/**"
  coverage_min: 80
artifacts:
  dir: artifacts
escalation:
  dir_pattern: "artifacts/{TICKET}/escalations"
```

`craftkit init` auto-fills this by inspecting the repo; the team reviews and
commits it. Skills reference `project.yaml` instead of hardcoded paths/commands —
this is the single mechanism that makes the same skill content portable across
wildly different repos.

---

## 7. Harness Adapters

All three adapters are generators that read `kit/skills` + `kit/workflows` +
`project.yaml` and emit native config. Skill bodies are never duplicated — shims
are one-liners pointing at `.craftkit/`.

### 7.1 Claude Code (`adapters/claude-code.sh`)

- Emits `.claude/commands/ck-<name>.md`, each containing exactly:
  `Read and follow ./.craftkit/<skills|workflows>/<name>/…`.
- Merges (never overwrites) `.claude/settings.json`: deny subagent spawning by
  default, plus any team additions preserved.
- Appends a marked, regenerable block to `CLAUDE.md` (or creates it) that says:
  read `AGENTS.md`, tool constraints, command index. Block delimited by
  `<!-- craftkit:begin --> … <!-- craftkit:end -->` so `sync` can replace it
  without clobbering team content.

### 7.2 pi (`adapters/pi.sh`)

- pi discovers skills natively from a skills directory; the adapter writes the
  pi config pointing skill discovery at `.craftkit/skills/` and
  `.craftkit/workflows/`.
- Wires `.pi/context/` to `.craftkit-project/context/` (symlink where supported,
  generated pointer file otherwise) so `workspace.md` + `profiles/` serve as
  pi's on-demand context.

### 7.3 GitHub Copilot CLI (`adapters/copilot-cli.sh`)

- Copilot CLI reads `AGENTS.md` natively — the generated `AGENTS.md` is the
  primary integration point and carries the command index, critical rules, and
  pipeline overview.
- Emits `.github/agents/ck-<name>.md` custom-agent shims (frontmatter
  `name`/`description` + the same one-line "read and follow" body) so workflows
  and skills are invokable by name.
- Maintains a marked block in `.github/copilot-instructions.md` mirroring the
  CLAUDE.md block (tool constraints, "load on demand", escalation pointer).

**Lowest-common-denominator rule:** skill bodies may only assume the agent can
(a) read/write files, (b) run shell commands, (c) follow markdown instructions.
No harness-specific tools (subagents, MCP, web) are ever referenced inside a
skill — that constraint is what keeps the three harnesses behaviorally
equivalent.

---

## 8. Versioning, Distribution, Customization

### 8.1 Versioning

- Kit is versioned with **semver git tags**; `VERSION` + `CHANGELOG.md` in-repo.
- Consumer repos pin a version in `.craftkit/KIT_VERSION` and upgrade
  deliberately via `craftkit update`. No floating "latest" — pipeline behavior
  must be reproducible and reviewable in PRs (the vendored `.craftkit/` diff
  *is* the review).
- Breaking changes (artifact schema, escalation format, `project.yaml` schema)
  ⇒ major bump + migration notes in CHANGELOG; `craftkit doctor` flags schema
  drift.

### 8.2 Distribution

Vendoring (copy into `.craftkit/`) over git submodules or package managers:
submodules confuse half of every team, and package managers assume a toolchain.
Vendored markdown is greppable, reviewable in PRs, and works offline. The kit is
small (tens of KB of markdown), so duplication cost is negligible.

### 8.3 Per-repo customization

Three sanctioned mechanisms, in order of preference:

1. **`project.yaml`** — for anything parameterizable (commands, paths, rules).
2. **`.craftkit-project/overrides/<skill>/SKILL.md`** — full replacement of a
   skill; `craftkit sync` points that skill's shims at the override and `doctor`
   warns that it has diverged from the kit version.
3. **Upstreaming** — teams that grow generally useful skills PR them into
   `craftkit` for everyone.

Editing files under `.craftkit/` directly is unsupported (lost on update);
`doctor` detects it via a manifest checksum and warns.

---

## 9. Trainability for New Engineers

The kit is a training tool as much as an automation tool:

1. **`/ck-onboard`** — interactive workflow that walks a new engineer through
   the repo (`AGENTS.md`, module registry, conventions) and then runs one toy
   ticket through all 8 phases in a scratch artifact dir, explaining each gate.
2. **Artifact trail as curriculum** — every real feature leaves
   `1-requirements.md → 2-tech-spec.md → 3-execution-plan.md → 4-review.md` in
   `artifacts/`. Reading a senior engineer's completed ticket dir is a worked
   example of how the team decomposes work.
3. **Escalation files as institutional memory** — the append-only Q&A rounds in
   `escalations/*.md` capture *why* decisions were made, with explicit
   Context/Impact per question. New engineers see the questions experts ask.
4. **Human gates teach judgment** — workflows never auto-advance; the engineer
   approves every phase, so juniors review (and learn from) every intermediate
   artifact rather than receiving a finished PR.
5. **`ONBOARDING.md`** — generated per-repo quick-start: install, first command,
   command index, "what to do when the agent escalates".

---

## 10. Critical Rules (Kit-Wide Invariants)

Enforced by every skill and stated in every generated harness config:

1. **Never guess — escalate.** Binary confidence; no partial artifacts.
2. **`ownership: external` modules are read-only.** Stop and ask before any change.
3. **Pull latest before analyzing code.** Refuse to analyze dirty/stale checkouts.
4. **Never weaken quality gates.** `protected_files` are untouchable; fix code, not configs (single scoped exemption: `deps-update` may bump versions).
5. **Artifact status gates.** Downstream skills refuse artifacts without `status: approved`.
6. **Load context on demand.** `workspace.md` + impacted-module profiles + the one upstream artifact — nothing speculative.
7. **Batch commits** per module with the `commit_format` from `project.yaml`.
8. **Token consciousness.** Workflows checkpoint after each phase and recommend fresh sessions after implement-class phases; all state lives in `artifacts/`, so resume is lossless.

---

## 11. Rollout Path

1. Author the phase skills and the shared references (escalation protocol,
   artifact conventions), keeping all repo-specific facts behind `project.yaml`
   lookups.
2. Build `workflows/feature.md` as the orchestrator skeleton (gating, resume,
   token budget) and derive the lighter workflows from it.
3. Implement `bin/craftkit` (init/sync/update/doctor) and the three adapter
   generators; cover with `tests/smoke.sh` (init into a tmp repo, verify shims).
4. Dogfood on one real repo per shape — a single-module service, a monorepo, and
   a non-JVM stack — before tagging v1.0.

## 12. Open Questions (to resolve before v1.0)

- **Copilot CLI agent-file format drift** — Copilot's custom-agent/instructions
  surface is evolving faster than pi/Claude Code; the adapter should be the only
  file touched when it changes. Validate against the current Copilot CLI release
  during dogfooding.
- **Monorepo artifact placement** — one `artifacts/` at repo root vs. per-module;
  default root, allow override in `project.yaml`.
- **Should `artifacts/` be committed?** Committing gives audit + training value;
  some repos may prefer gitignore. Made configurable; default **commit**.
- **License choice** — MIT (simplest) vs. Apache-2.0 (patent grant); decide
  before first public tag.
- **Ticket-system neutrality** — `tickets` should emit generic ticket text
  with pluggable formats (Jira, GitHub Issues, Linear) selected in
  `project.yaml`.
