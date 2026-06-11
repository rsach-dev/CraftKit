# CraftKit

A portable, versioned kit of agent **skills** and **workflows** that any
repository can adopt with one command. CraftKit makes coding-agent–driven
development structured, auditable, and easy to teach: every feature flows
through human-gated phases, every phase leaves a reviewable markdown artifact,
and the agent **escalates instead of guessing**.

Works identically across **pi**, **Claude Code**, and **GitHub Copilot CLI** —
skills are harness-agnostic markdown; each harness gets thin generated shims.

## Install (in any repo)

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/craftkit/main/bin/craftkit | sh -s init
# or from a local checkout:
CRAFTKIT_SRC=/path/to/craftkit /path/to/craftkit/bin/craftkit init
```

`init` vendors the kit into `.craftkit/`, detects your stack (Gradle, Maven,
npm, Cargo, Go, Python), generates `.craftkit-project/project.yaml`,
`AGENTS.md`, and `ONBOARDING.md`, and wires up all three harnesses. Then:

1. Review `.craftkit-project/project.yaml`
2. In your agent harness, run `/ck-context-sync` to generate module profiles
3. Run `/ck-onboard` for the guided tour

## Everyday commands

| Command | What it does |
|---------|--------------|
| `/ck-feature` | Full pipeline: requirements → tech-spec → plan → implement → review → ship, pausing for your approval at every phase |
| `/ck-bugfix` | Triage a trace/error → plan → fix → review → ship |
| `/ck-review` | Review a branch against the ticket's artifacts, with a fix loop |
| `/ck-deps` | Dependency updates with framework-anchor guardrails |
| `/ck-onboard` | Interactive tour for new engineers |

Individual phases are also available (`/ck-requirements`, `/ck-tech-spec`,
`/ck-implement`, …) for resuming mid-pipeline.

## How it works

- **One source of truth.** Skills live in `.craftkit/skills/*/SKILL.md` as
  plain imperative markdown. Harness integration is one-line generated shims
  (`.claude/commands/`, `.pi/`, `.github/agents/`) — regenerate any time with
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
kit/templates/     project.yaml, AGENTS.md, ONBOARDING.md
adapters/          shim generators: claude-code, pi, copilot-cli
bin/craftkit       POSIX-sh CLI: init, sync, update, doctor
tests/smoke.sh     content lint + end-to-end init test
ARCHITECTURE.md    full design document
```

## Development

```bash
sh tests/smoke.sh
```

License: MIT
