# Artifact Conventions

Shared conventions for all pipeline artifacts produced by CraftKit skills.

## Location

Artifacts live under the directory configured in
`.craftkit-project/project.yaml` (`artifacts.dir`, default `artifacts/`),
one directory per ticket:

```
artifacts/{TICKET}/
├── 1-requirements.md      ← requirements skill
├── 2-tech-spec.md         ← tech-spec skill
├── 3-execution-plan.md    ← execution-plan skill
├── 4-review.md            ← review skill
├── 5-triage.md            ← triage skill (standalone)
├── 6-deps-update.md       ← deps-update skill (standalone)
└── escalations/
    └── {phase}.md         ← human Q&A files (see escalation-protocol.md)
```

`{TICKET}` is a ticket ID using one of the prefixes configured in
`project.yaml` (`ticket.prefixes`), e.g. `PROJ-1234`.

## Frontmatter

Every artifact starts with YAML frontmatter. Minimum fields:

```yaml
---
ticket: {TICKET}
title: {concise title}
date: {YYYY-MM-DD}
status: approved
---
```

The review artifact uses `verdict: pass | pass-with-notes | fail` instead of
`status`.

## Status Gate

- A skill writes its artifact **only** when it has 100% confidence (see
  `escalation-protocol.md`). A written artifact therefore always carries
  `status: approved`.
- Downstream skills **must refuse** to consume an upstream artifact whose
  `status` is not `approved` — they instruct the user to complete the upstream
  phase first.
- Humans may flip an artifact back from `approved` (e.g. to `draft`) to force a
  phase to re-run; skills treat a non-approved artifact as missing.

## Content Rules

1. **No open questions inside artifacts.** All questions are resolved via the
   escalation protocol *before* the artifact is written.
2. **Artifacts are self-contained.** A reader (or a downstream skill) needs no
   conversation history — only the artifact and its upstream artifacts.
3. **Summarize in chat, never echo.** After writing an artifact, print a short
   summary (≤10 lines) and the path — never dump the full contents into the
   conversation.
4. **Skills own their artifacts.** Workflows and humans never hand-write or
   edit phase artifacts (except the status field); only the producing skill
   writes them.
5. **Escalation files are append-only.** See `escalation-protocol.md`.
