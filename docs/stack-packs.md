# Stack Packs

Stack packs make CraftKit's output **opinionated about a particular stack**
without bloating skill context or forking the skills. The skills stay
stack-neutral; a pack supplies small, targeted context files that individual
skills load **on demand, one file per skill**.

## Why packs instead of stack-specific skills

- **Quality:** "constructor injection via `@RequiredArgsConstructor`, AssertJ
  only, embedded Postgres for DB tests" produces far better code than
  "follow module conventions".
- **No bloat:** each pack file has exactly one consumer and a line cap. A
  skill never loads the whole pack — only its own file, only for modules
  that opted in.
- **Mixed workspaces keep working:** packs are set **per module**, so a
  Spring Boot service and a plain-Java job in the same workspace each get
  the right treatment (or none).

## Activating a pack

Per module, in `.craftkit-project/project.yaml`:

```yaml
modules:
  - name: order-service
    path: internal/order-service
    stack_pack: java21-spring-gradle   # ← opt in
```

`craftkit init` auto-detects and pre-fills this where it can (e.g. a Gradle
build mentioning spring-boot). `craftkit stacks` lists installed packs;
`craftkit doctor` fails if a referenced pack isn't installed. Leave it empty
for generic behavior.

Packs ship with the kit (`.craftkit/stacks/`) and are versioned/updated with
it — `craftkit update` upgrades pack content like any other kit file.

## What's in a pack, and who reads it

```
.craftkit/stacks/<pack>/
├── pack.yaml                       metadata + detection hints
├── conventions.md                  ← implement, review, feedback   (~60 lines)
└── references/
    ├── deps-update.md              ← deps-update only             (~100 lines)
    ├── triage.md                   ← triage only                   (~60 lines)
    └── profile-template.md         ← context-sync only             (~50 lines)
```

Every file is optional — a pack can ship only `conventions.md`. Skills probe
for their one file and silently proceed without it.

Precedence when guidance conflicts:
**repo coding-standards** (learned via feedback) > **module profile** >
**pack conventions** > generic skill text.

## Available packs

| Pack | Stack |
|------|-------|
| `java21-spring-gradle` | Java 21 · Spring Boot 3.x · Gradle (JUnit 5, Mockito, AssertJ, Lombok, JPA, checkstyle/PMD/JaCoCo gates) |

## Authoring a new pack

1. Create `kit/stacks/<name>/pack.yaml` with `name`, `description`, and
   `detect` hints; copy the consumer/cap table comment from the
   `java21-spring-gradle` pack.
2. Write only the files your stack benefits from. Hard rules:
   - **One consumer per file.** If two skills need it, it's two files.
   - **Respect the caps** (conventions ~60 lines, references ≤100). If you
     exceed them, you're copying documentation instead of distilling opinion.
   - **Imperative and specific.** "Use `assertThatThrownBy`, never
     `@Test(expected=...)`" — not background explanation.
   - **No repo-specific facts.** Those belong in `project.yaml` and module
     profiles; packs describe the *stack*, not your codebase.
3. Add the pack's detection to `bin/craftkit` `detect_repo()` if it can be
   auto-suggested.
4. Run `sh tests/smoke.sh` — pack structure and caps are enforced there.

Repo-local variants: a repo can't add packs under `.craftkit/` (replaced on
update). For repo-specific opinion, extend the module profiles or
`coding-standards.md`; for a reusable stack, contribute the pack upstream.
