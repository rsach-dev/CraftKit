# CraftKit

A portable, versioned kit of agent **skills** and **workflows** that any
repository can adopt with one command. CraftKit makes coding-agent–driven
development structured, auditable, and easy to teach: every feature flows
through human-gated phases, every phase leaves a reviewable markdown artifact,
and the agent **escalates instead of guessing**.

Works identically across **pi**, **Claude Code**, and **GitHub Copilot CLI** —
skills are harness-agnostic markdown; each harness gets thin generated shims.

## Install

Put the `craftkit` command on your PATH (installs to `~/.local/bin` by default):

```bash
curl -fsSL https://raw.githubusercontent.com/rsach-dev/CraftKit/main/install.sh | sh
```

Then, in any repository:

```bash
cd <your-repo> && craftkit init
```

Alternatives:

```bash
# one-shot, no install:
curl -fsSL https://raw.githubusercontent.com/rsach-dev/CraftKit/main/bin/craftkit | sh -s init
# from a local checkout (offline):
CRAFTKIT_SRC=/path/to/CraftKit /path/to/CraftKit/bin/craftkit init
```

`init` vendors the kit into `.craftkit/`, detects your stack (Gradle, Maven,
npm, Cargo, Go, Python), generates `.craftkit-project/project.yaml`,
`AGENTS.md`, and `ONBOARDING.md`, and wires up the harnesses you choose —
it prompts interactively (claude-code, copilot-cli, pi); non-interactive runs
must pass `craftkit init --harnesses claude-code,pi` (or `--harnesses all`).
The choice is recorded as `harnesses:` in `project.yaml`; re-run
`craftkit init` later to add another harness (selections merge), or edit the
list + `craftkit sync`. Then:

1. In your agent harness, run `/ck-init` — it completes `project.yaml`
   (modules, stack packs, commands), generates module profiles, and runs the
   doctor
2. Run `/ck-onboard` for the guided tour

## Everyday commands

| Command | What it does |
|---------|--------------|
| `/ck-feature` | Full pipeline: requirements → tech-spec → plan → implement → review → ship, pausing for your approval at every phase |
| `/ck-bugfix` | Triage a trace/error → plan → fix → review → ship |
| `/ck-review` | Review a branch against the ticket's artifacts, with a fix loop |
| `/ck-deps` | Dependency updates with framework-anchor guardrails |
| `/ck-onboard` | Interactive tour for new engineers |

Usage guides: [feature](docs/workflows/feature.md) ·
[bugfix](docs/workflows/bugfix.md) · [deps](docs/workflows/deps.md) ·
[review](docs/workflows/review.md) · [onboard](docs/workflows/onboard.md)

Individual phases are also available (`/ck-requirements`, `/ck-tickets`,
`/ck-tech-spec`, `/ck-execution-plan`, `/ck-implement`, `/ck-feedback`,
`/ck-ship`, plus standalone `/ck-triage` and `/ck-deps-update`) for resuming
mid-pipeline; the review phase runs via `/ck-review`.

Installing in a workspace with several services/repos? See
[docs/multi-repo-workspace.md](docs/multi-repo-workspace.md).

## How it works

- **One source of truth.** Skills live in `.craftkit/skills/*/SKILL.md` as
  plain imperative markdown. Harness integration is one-line generated shims
  (`.claude/commands/`, `.pi/`, `.github/skills/`) — regenerate any time with
  `craftkit sync`.
- **Artifacts, not vibes.** Each phase writes
  `artifacts/{TICKET}/N-*.md` with `status: approved` frontmatter; downstream
  skills refuse unapproved inputs. The artifact trail doubles as training
  material for new engineers.
- **Escalation protocol.** When a skill lacks 100% confidence it writes
  structured questions (with Context and Impact) to
  `artifacts/{TICKET}/escalations/{phase}.md` and stops. You answer, re-run,
  and it continues. No partial artifacts, ever.
- **Repo contract.** Everything repo-specific (modules, build commands,
  ticket format, protected files) lives in
  `.craftkit-project/project.yaml` — the same skills work in any repo.
- **Stack packs.** Opt a module into stack-specific opinion
  (`stack_pack: java21-spring-gradle`) and the skills load small, targeted
  convention/playbook files for that stack — one file per skill, on demand,
  so context stays compact. See [docs/stack-packs.md](docs/stack-packs.md).

## Maintenance

```bash
.craftkit/bin/craftkit sync     # regenerate shims after editing project.yaml
.craftkit/bin/craftkit update   # upgrade the vendored kit (repo-owned files untouched)
.craftkit/bin/craftkit doctor   # validate the installation
```

Customize via `project.yaml` first; for deeper changes, place a full skill
replacement in `.craftkit-project/overrides/<skill>/SKILL.md` (shims will
point there after `sync`). Never edit `.craftkit/` directly — it is replaced
wholesale on update, and `doctor` will warn if it has diverged.

## Repository layout (this repo)

```
kit/skills/        11 phase skills + shared references
kit/workflows/     feature, bugfix, deps, review, onboard
kit/stacks/        stack packs (java21-spring-gradle, …)
kit/templates/     project.yaml, AGENTS.md, ONBOARDING.md
adapters/          shim generators: claude-code, pi, copilot-cli
bin/craftkit       POSIX-sh CLI: init, sync, update, doctor
install.sh         curl-able installer: puts `craftkit` on your PATH
docs/              usage guides: multi-repo workspaces + one per workflow
tests/smoke.sh     content lint + end-to-end init test
ARCHITECTURE.md    full design document
```

## Development

```bash
sh tests/smoke.sh
```

License: MIT
