---
name: context-sync
description: "Scans the modules registered in project.yaml, generates or updates .craftkit-project/context/workspace.md and per-module profiles in .craftkit-project/context/profiles/. Use after craftkit init, when a new module is added, or when an existing module's patterns have changed significantly."
---

# context-sync — Update Context Docs

## Overview

Scans all modules registered in `project.yaml` and regenerates the context
files that other CraftKit skills depend on. Keeps `workspace.md` and module
profiles in sync with actual code state.

## Usage

### Step 1 — Load project config

```bash
cat "./.craftkit-project/project.yaml"
ls "./.craftkit-project/context" 2>/dev/null
```

The module registry in `project.yaml` is the source of truth for what to
scan. If a module path doesn't exist on disk, warn and skip it.

### Step 2 — For each module, extract context

For each registered module, gather:

1. **Stack info:** Read the package-manager manifest (`build.gradle`,
   `pom.xml`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, …)
   for framework and language/runtime versions
2. **Source layout:** `find {module-path}/src -type d | head -30` (or the
   module's equivalent source root)
3. **Existing docs:** Read `CLAUDE.md`, `AGENTS.md`,
   `.github/copilot-instructions.md`, `README.md` if they exist in the module
4. **Test patterns:** Skim 1–2 representative test files for framework and
   assertion style
5. **Ownership:** from `project.yaml`

Keep scans targeted — distill, don't ingest whole repos.

### Step 3 — Update workspace.md

Read the current `./.craftkit-project/context/workspace.md` (create from
scratch if absent). Compare its module table against `project.yaml` and the
scan:
- Add rows for new modules
- Update stack/path for changed modules
- Do NOT remove rows for modules that no longer exist on disk (they may be
  temporarily absent) — warn instead

`workspace.md` target shape (~40 lines max):

```markdown
# Workspace: {repo name}

## Modules

| Module | Path | Ownership | Stack | Build |
|--------|------|-----------|-------|-------|

## Ownership Rules

- team modules: full modify access
- external modules: read-only reference; changes refused unless user
  explicitly allows

## Conventions

- {distilled cross-module conventions: commit format, test style, error
  handling, logging — one bullet each}

## Artifact Pipeline

{standard table mapping phases → artifact files → skills}
```

### Step 4 — Generate/update module profiles

For each module, write
`./.craftkit-project/context/profiles/{module-name}.md`:

```markdown
# Profile: {module-name}

**Path:** `{module-path}`
**Stack:** {framework + language/runtime versions}
**Ownership:** {team | external — flag external prominently}

## Source Layout
{one line per significant directory with purpose}

## Key Patterns
{distilled from docs + code scan — interface layer, business logic,
persistence, and test patterns}

## Build
{build/test commands}

## Quality Gates
{lint/coverage constraints — only if notable}
```

Rules:
- Max ~60 lines per profile
- Distill, don't copy — extract what downstream skills actually need
- Flag external ownership prominently

### Step 5 — Report

Print:
- Number of modules scanned
- New profiles created
- Profiles updated
- Any warnings (missing modules, parse failures)

## Notes

- This skill only modifies files under `.craftkit-project/context/` — never
  touches source code or `project.yaml`
- Run after `craftkit init`, after adding a module, and after major refactors
  that change structure or conventions
