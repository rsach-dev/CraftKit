#!/bin/sh
# CraftKit smoke test: lints kit content, then runs a full init into a
# temporary repo and validates the result. No network access required.
set -eu

KIT_REPO=$(cd "$(dirname "$0")/.." && pwd)
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf 'ok   %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf 'FAIL %s\n' "$1"; }
check() { if eval "$2" >/dev/null 2>&1; then ok "$1"; else bad "$1"; fi; }

echo "== lint kit content =="

# Every skill has frontmatter with name + description, and the dir matches name.
for sk in "$KIT_REPO"/kit/skills/*/SKILL.md; do
  dir=$(basename "$(dirname "$sk")")
  check "skill $dir: frontmatter opens" "head -1 '$sk' | grep -qx -- '---'"
  check "skill $dir: name matches dir" "sed -n '2,5p' '$sk' | grep -q '^name: $dir$'"
  check "skill $dir: has description" "sed -n '2,5p' '$sk' | grep -q '^description:'"
done
for wf in "$KIT_REPO"/kit/workflows/*.md; do
  n=$(basename "$wf" .md)
  check "workflow $n: frontmatter name" "sed -n '2,5p' '$wf' | grep -q '^name: $n$'"
  check "workflow $n: has description" "sed -n '2,5p' '$wf' | grep -q '^description:'"
done

# Cross-references: every .craftkit path mentioned in kit content exists in kit/.
refs=$(grep -rhoE '\./\.craftkit/(skills|workflows)/[A-Za-z0-9/._-]+\.md' "$KIT_REPO/kit" | sort -u)
for r in $refs; do
  rel=${r#./.craftkit/}
  check "xref $rel" "test -f '$KIT_REPO/kit/$rel'"
done

# No leftover org-specific or legacy naming.
check "no 'fc-' references" "! grep -rn 'fc-' '$KIT_REPO/kit' '$KIT_REPO/adapters' '$KIT_REPO/bin'"

echo "== init into a temp repo =="
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
(
  cd "$TMP"
  git init -q .
  git commit -q --allow-empty -m "DEMO-1: initial commit"
  printf '{ "name": "demo", "scripts": { "build": "true", "test": "true" } }\n' > package.json
  CRAFTKIT_SRC="$KIT_REPO" sh "$KIT_REPO/bin/craftkit" init > init.log 2>&1 || { cat init.log; exit 1; }
)

check "vendored kit"            "test -f '$TMP/.craftkit/KIT_VERSION'"
check "manifest written"        "test -f '$TMP/.craftkit/MANIFEST'"
check "project.yaml generated"  "test -f '$TMP/.craftkit-project/project.yaml'"
check "ticket prefix detected"  "grep -q 'prefixes: \[DEMO\]' '$TMP/.craftkit-project/project.yaml'"
check "stack detected (npm)"    "grep -q 'npm run build' '$TMP/.craftkit-project/project.yaml'"
check "AGENTS.md generated"     "test -f '$TMP/AGENTS.md'"
check "ONBOARDING.md generated" "test -f '$TMP/ONBOARDING.md'"
check "no template placeholders left" "! grep -rn '{{[A-Z_]*}}' '$TMP/.craftkit-project/project.yaml' '$TMP/AGENTS.md' '$TMP/ONBOARDING.md'"

# Claude Code shims.
check "claude shim: feature workflow" "grep -q 'workflows/feature.md' '$TMP/.claude/commands/ck-feature.md'"
check "claude shim: tech-spec skill"  "grep -q 'skills/tech-spec/SKILL.md' '$TMP/.claude/commands/ck-tech-spec.md'"
check "claude collision: review -> workflow" "grep -q 'workflows/review.md' '$TMP/.claude/commands/ck-review.md'"
check "claude settings.json"          "test -f '$TMP/.claude/settings.json'"
check "CLAUDE.md marked block"        "grep -q 'craftkit:begin' '$TMP/CLAUDE.md'"

# Copilot shims.
check "copilot agent shim exists"     "test -f '$TMP/.github/agents/ck-bugfix.md'"
check "copilot shim has description"  "grep -q '^description: \"' '$TMP/.github/agents/ck-bugfix.md'"
check "copilot instructions block"    "grep -q 'craftkit:begin' '$TMP/.github/copilot-instructions.md'"

# pi wiring.
check "pi skills link"  "test -e '$TMP/.pi/skills' -o -f '$TMP/.pi/skills.md'"
check "pi context link" "test -e '$TMP/.pi/context' -o -f '$TMP/.pi/context.md'"

# Idempotency + repo-owned preservation.
( cd "$TMP" && echo "# team note" >> AGENTS.md && sh .craftkit/bin/craftkit sync >/dev/null 2>&1 )
check "sync idempotent"            "test -f '$TMP/.claude/commands/ck-feature.md'"
check "sync preserves AGENTS.md"   "grep -q 'team note' '$TMP/AGENTS.md'"
check "CLAUDE.md block not duplicated" "test \$(grep -c 'craftkit:begin' '$TMP/CLAUDE.md') -eq 1"

# Doctor passes on a fresh install.
check "doctor passes" "( cd '$TMP' && sh .craftkit/bin/craftkit doctor )"

# Doctor flags hand edits to the vendored kit.
( cd "$TMP" && echo "edit" >> .craftkit/workflows/feature.md )
check "doctor flags kit divergence" "( cd '$TMP' && sh .craftkit/bin/craftkit doctor 2>&1 | grep -q 'diverges' )"

echo "== result: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
