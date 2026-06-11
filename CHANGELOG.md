# Changelog

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
