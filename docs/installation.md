# Installation & Setup Reference

The short version is in the [README](../README.md): install the CLI, run
`craftkit init`, then `/ck-init` in your agent harness. This page covers
everything beyond that.

## Installing the CLI

`install.sh` puts `craftkit` on your PATH (default: `~/.local/bin`):

```bash
curl -fsSL https://raw.githubusercontent.com/rsach-dev/CraftKit/main/install.sh | sh
```

Options (env vars):

| Variable | Effect |
|----------|--------|
| `CRAFTKIT_INSTALL_DIR` | install location (default `~/.local/bin`) |
| `CRAFTKIT_VERSION` | git ref to install from (default `main`) |
| `CRAFTKIT_SRC` | install from a local CraftKit checkout (offline) |

No install at all — run init one-shot:

```bash
curl -fsSL https://raw.githubusercontent.com/rsach-dev/CraftKit/main/bin/craftkit | sh -s init
```

Offline / air-gapped — point init at a local checkout:

```bash
CRAFTKIT_SRC=/path/to/CraftKit /path/to/CraftKit/bin/craftkit init
```

Once a repo is initialized, the CLI is also vendored at
`.craftkit/bin/craftkit`, so teammates don't need to install anything.

## `craftkit init` and harness selection

`init` requires you to choose at least one harness. Run interactively, it
prompts:

```text
Which agent harnesses should CraftKit wire up?
  1) claude-code
  2) copilot-cli
  3) pi
Enable (names or numbers, comma-separated, or "all"):
```

Non-interactive runs (CI, scripts, piped stdin) must pass the choice
explicitly:

```bash
craftkit init --harnesses claude-code          # one harness
craftkit init --harnesses claude-code,pi       # several
craftkit init --harnesses all                  # all of them
```

The selection is recorded in `.craftkit-project/project.yaml`:

```yaml
harnesses: [claude-code, pi]
```

`craftkit sync` regenerates shims only for the listed harnesses, and
`craftkit doctor` validates only those.

### What each harness gets

| Harness | Generated files |
|---------|----------------|
| `claude-code` | `.claude/commands/ck-*.md` slash commands, `.claude/settings.json` (created if absent), a marked block in `CLAUDE.md` |
| `copilot-cli` | `.github/skills/ck-*/SKILL.md` native skills, a marked block in `.github/copilot-instructions.md` |
| `pi` | `.pi/{skills,workflows,context}` symlinks into the kit |

All harnesses share `AGENTS.md` as the harness-neutral entry point.

### Adding or removing a harness later

Add — re-run init; selections merge into the existing list:

```bash
craftkit init --harnesses pi      # adds pi, keeps what was enabled
```

Remove — edit the `harnesses:` list in `project.yaml`, run
`craftkit sync`, and delete that harness's generated files (see table above).

## After init: `/ck-init`

`craftkit init` works from heuristics; `/ck-init` (run inside your agent
harness) finishes the job with judgment: registers all modules in monorepos,
verifies build/test commands, assigns stack packs, generates
`.craftkit-project/context/` profiles, and runs the doctor. Re-run it any
time the setup feels incomplete — it converges on the current repo state.

## What to commit

`.craftkit/`, `.craftkit-project/`, `AGENTS.md`, `ONBOARDING.md`, plus the
generated files of the harnesses you enabled.

## Updating and pinning

```bash
.craftkit/bin/craftkit update              # upgrade to the latest kit
.craftkit/bin/craftkit update --to 0.3.0   # pin a specific version (git tag vX.Y.Z)
.craftkit/bin/craftkit version             # show the installed kit version
```

Updates replace `.craftkit/` wholesale and re-sync shims; repo-owned files
(`.craftkit-project/`, `AGENTS.md`, `ONBOARDING.md`, `artifacts/`) are never
touched. `craftkit doctor` warns if `.craftkit/` has hand edits (they'd be
lost on update — use `.craftkit-project/overrides/` instead).
