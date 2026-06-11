# Installing CraftKit in a Multi-Repo / Multi-Service Workspace

CraftKit installs into **one** git repository and orchestrates work across
**many** modules. A "module" in `project.yaml` can be:

- the repo itself (single-service repo),
- a subdirectory of a monorepo, or
- a **separately cloned repository** sitting inside a workspace repo.

This guide covers the third shape — a dedicated *workspace repo* that tracks
the pipeline (skills, config, artifacts) while the service codebases are
cloned alongside and gitignored.

## When to use a workspace repo

Use this shape when your team owns several services in separate repositories
and you want one place for:

- a single shared `project.yaml` (module registry, ownership, conventions),
- the artifact paper trail across all services (`artifacts/{TICKET}/`),
- cross-service features (one ticket whose plan touches three repos).

## Layout

```
my-team-workspace/            ← the git repo CraftKit installs into
├── .craftkit/                ← vendored kit
├── .craftkit-project/
│   ├── project.yaml          ← registers every service
│   └── context/              ← workspace.md + one profile per service
├── artifacts/                ← pipeline artifacts for ALL services
├── AGENTS.md · ONBOARDING.md · CLAUDE.md
├── .gitignore                ← ignores internal/ and external/
├── internal/                 ← team-owned service clones (gitignored)
│   ├── order-service/        ← its own git repo
│   └── billing-service/      ← its own git repo
└── external/                 ← read-only reference clones (gitignored)
    └── partner-gateway/
```

The workspace repo tracks only the workflow setup; the service clones are
plain `git clone`s that each carry their own remotes, branches, and commits.

## Step-by-step setup

### 1. Create the workspace repo and clone services

```bash
mkdir my-team-workspace && cd my-team-workspace && git init
mkdir internal external
git clone git@github.com:org/order-service.git    internal/order-service
git clone git@github.com:org/billing-service.git  internal/billing-service
git clone git@github.com:org/partner-gateway.git  external/partner-gateway
printf 'internal/\nexternal/\n' > .gitignore
```

### 2. Install CraftKit

```bash
craftkit init        # pick your harness(es) at the prompt
```

Detection will see no manifest at the workspace root — that's fine; the
generated `project.yaml` is a single-module placeholder you replace next.

### 3. Register every service in `project.yaml`

```yaml
modules:
  - name: order-service
    path: internal/order-service
    ownership: team
    stack: "Spring Boot / Java 21 / Gradle"
    build: "./gradlew build"
    test: "./gradlew test"
  - name: billing-service
    path: internal/billing-service
    ownership: team
    stack: "Node.js / npm"
    build: "npm run build"
    test: "npm test"
  - name: partner-gateway
    path: external/partner-gateway
    ownership: external        # read-only: skills refuse to modify it
    stack: "Go"
    build: "go build ./..."
    test: "go test ./..."
```

Rules of thumb:

- **`path`** is relative to the workspace root. Skills `cd` into it for
  builds, diffs, branches, and commits — each module keeps its own git life.
- **`ownership: external`** marks reference-only clones. Plans that touch
  them trigger an explicit permission stop; `deps-update` and `ship` refuse
  them outright.
- `ticket.prefixes` and `commit_format` are shared across all modules.

### 4. Sync and generate profiles

```bash
craftkit sync          # regenerate shims after editing project.yaml
```

Then, in your agent harness, run `/ck-init`. It verifies the registry you
just wrote (paths exist, build/test commands work), assigns stack packs,
writes `.craftkit-project/context/workspace.md` plus one ~60-line profile
per service, and runs the doctor. (You can also write the registry in step 3
with broad strokes and let `/ck-init` fill in the details.) Later, when only
the profiles are stale, `/ck-context-sync` regenerates just those.

### 5. Commit the workspace

```bash
git add -A && git commit -m "PROJ-1: CraftKit workspace setup"
```

Commit `.craftkit/`, `.craftkit-project/`, `artifacts/`, the generated docs,
and the harness shims. The service clones stay gitignored.

## How the pipeline behaves across services

- **Requirements/tech-spec** identify *which* modules a ticket impacts; only
  those profiles are loaded thereafter.
- **Implement** makes changes per module and creates **one batch commit per
  module** (`{TICKET}: description`), inside each service's own clone.
- **Pre-flight refresh:** every code-reading skill first
  fetches/checkouts/pulls the module's default branch and refuses dirty
  checkouts — keep your service clones clean.
- **Ship** pushes one feature branch per modified module and produces one PR
  description per module.
- **Artifacts are workspace-level:** a cross-service ticket has one
  `artifacts/{TICKET}/` directory covering all impacted modules.

## Day-2 operations

| Situation | What to do |
|-----------|-----------|
| New service added | `git clone` into `internal/`, add a `modules:` entry, `craftkit sync`, run `/ck-context-sync` |
| Service conventions changed | re-run `/ck-context-sync` |
| Kit upgrade | `craftkit update` (only `.craftkit/` is replaced) |
| A teammate clones the workspace | they `git clone` the workspace, clone the services into `internal/`/`external/`, done — config and shims are already committed |

## Monorepos

A monorepo is the simpler cousin: same `project.yaml` shape, but `path`
points at subdirectories of the *same* git repo (`path: services/orders`).
Everything above applies except the per-module git mechanics — batch commits
land in the one shared repo, and `ship` pushes a single branch.
