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

# Stack packs: metadata is sound and context caps are respected.
for pk in "$KIT_REPO"/kit/stacks/*/; do
  [ -d "$pk" ] || continue
  n=$(basename "$pk")
  check "pack $n: pack.yaml name matches dir" "grep -q '^name: $n$' '$pk/pack.yaml'"
  check "pack $n: has description" "grep -q '^description:' '$pk/pack.yaml'"
  [ -f "$pk/conventions.md" ] && \
    check "pack $n: conventions within cap" "[ \$(wc -l < '$pk/conventions.md') -le 80 ]"
  for r in "$pk"references/*.md; do
    [ -f "$r" ] || continue
    check "pack $n: $(basename "$r") within cap" "[ \$(wc -l < '$r') -le 120 ]"
  done
done

# Every /ck-<name> mentioned anywhere in docs resolves to a workflow or skill.
cmds=$(grep -rhoE '/ck-[a-z][a-z-]*[a-z]' "$KIT_REPO/kit" "$KIT_REPO/docs" "$KIT_REPO/README.md" "$KIT_REPO/ARCHITECTURE.md" 2>/dev/null | sort -u)
for c in $cmds; do
  n=${c#/ck-}
  check "command $c resolves" "test -f '$KIT_REPO/kit/workflows/$n.md' -o -f '$KIT_REPO/kit/skills/$n/SKILL.md'"
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
  mkdir -p .github/agents && touch .github/agents/ck-legacy.md   # pre-0.3 shim to migrate
  CRAFTKIT_SRC="$KIT_REPO" sh "$KIT_REPO/bin/craftkit" init --harnesses all < /dev/null > init.log 2>&1 || { cat init.log; exit 1; }
)

check "vendored kit"            "test -f '$TMP/.craftkit/KIT_VERSION'"
check "manifest written"        "test -f '$TMP/.craftkit/MANIFEST'"
check "project.yaml generated"  "test -f '$TMP/.craftkit-project/project.yaml'"
check "ticket prefix detected"  "grep -q 'prefixes: \[DEMO\]' '$TMP/.craftkit-project/project.yaml'"
check "harnesses=all recorded"  "grep -q 'harnesses: \[claude-code, copilot-cli, pi\]' '$TMP/.craftkit-project/project.yaml'"
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

# Copilot CLI skill shims (.github/skills/<name>/SKILL.md format).
check "copilot skill shim exists"     "test -f '$TMP/.github/skills/ck-bugfix/SKILL.md'"
check "copilot shim has name"         "grep -q '^name: ck-bugfix$' '$TMP/.github/skills/ck-bugfix/SKILL.md'"
check "copilot shim has description"  "grep -q '^description: \"' '$TMP/.github/skills/ck-bugfix/SKILL.md'"
check "copilot collision: review -> workflow" "grep -q 'workflows/review.md' '$TMP/.github/skills/ck-review/SKILL.md'"
check "copilot instructions block"    "grep -q 'craftkit:begin' '$TMP/.github/copilot-instructions.md'"
check "legacy agent shims migrated"   "! ls '$TMP/.github/agents/'ck-*.md"

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

# Installer (offline via CRAFTKIT_SRC).
check "installer installs craftkit" "CRAFTKIT_SRC='$KIT_REPO' CRAFTKIT_INSTALL_DIR='$TMP/bin' sh '$KIT_REPO/install.sh' && test -x '$TMP/bin/craftkit'"
check "installed CLI runs"          "'$TMP/bin/craftkit' help"

# Doctor flags hand edits to the vendored kit.
( cd "$TMP" && echo "edit" >> .craftkit/workflows/feature.md )
check "doctor flags kit divergence" "( cd '$TMP' && sh .craftkit/bin/craftkit doctor 2>&1 | grep -q 'diverges' )"

echo "== init into a gradle/spring temp repo =="
TMP2=$(mktemp -d); trap 'rm -rf "$TMP" "$TMP2"' EXIT
(
  cd "$TMP2"
  git init -q .
  git commit -q --allow-empty -m "JAVA-9: initial commit"
  printf 'plugins { id "org.springframework.boot" version "3.3.0" }\n' > build.gradle
  CRAFTKIT_SRC="$KIT_REPO" sh "$KIT_REPO/bin/craftkit" init --harnesses all < /dev/null > init.log 2>&1 || { cat init.log; exit 1; }
)
check "stacks vendored"                 "test -f '$TMP2/.craftkit/stacks/java21-spring-gradle/conventions.md'"
check "gradle fixture: pack detected"   "grep -q 'stack_pack: java21-spring-gradle' '$TMP2/.craftkit-project/project.yaml'"
check "npm fixture: no pack assigned"   "! grep -q 'stack_pack: java' '$TMP/.craftkit-project/project.yaml'"
check "craftkit stacks lists the pack"  "( cd '$TMP2' && sh .craftkit/bin/craftkit stacks | grep -q 'java21-spring-gradle —' )"
check "doctor validates active pack"    "( cd '$TMP2' && sh .craftkit/bin/craftkit doctor | grep -q \"stack pack 'java21-spring-gradle' installed\" )"

echo "== init with --harnesses claude-code =="
TMP3=$(mktemp -d); trap 'rm -rf "$TMP" "$TMP2" "$TMP3"' EXIT
(
  cd "$TMP3"
  git init -q .
  git commit -q --allow-empty -m "SEL-1: initial commit"
  printf '{ "name": "sel", "scripts": { "build": "true", "test": "true" } }\n' > package.json
  CRAFTKIT_SRC="$KIT_REPO" sh "$KIT_REPO/bin/craftkit" init --harnesses claude-code < /dev/null > init.log 2>&1 || { cat init.log; exit 1; }
)
check "selection recorded in project.yaml" "grep -q 'harnesses: \[claude-code\]' '$TMP3/.craftkit-project/project.yaml'"
check "claude shims generated"             "test -f '$TMP3/.claude/commands/ck-feature.md'"
check "ck-init shim generated"             "grep -q 'skills/init/SKILL.md' '$TMP3/.claude/commands/ck-init.md'"
check "no copilot shims"                   "! test -d '$TMP3/.github/skills'"
check "no copilot instructions"            "! test -f '$TMP3/.github/copilot-instructions.md'"
check "no pi wiring"                       "! test -e '$TMP3/.pi/skills' && ! test -f '$TMP3/.pi/skills.md'"
check "doctor passes with one harness"     "( cd '$TMP3' && sh .craftkit/bin/craftkit doctor )"
check "sync stays scoped"                  "( cd '$TMP3' && sh .craftkit/bin/craftkit sync >/dev/null 2>&1 && ! test -d '$TMP3/.github/skills' )"

# Re-running init adds a harness (selections merge into project.yaml).
( cd "$TMP3" && CRAFTKIT_SRC="$KIT_REPO" sh "$KIT_REPO/bin/craftkit" init --harnesses pi < /dev/null > reinit.log 2>&1 ) || cat "$TMP3/reinit.log"
check "re-init merges harness"             "grep -q 'harnesses: \[claude-code, pi\]' '$TMP3/.craftkit-project/project.yaml'"
check "re-init wires new harness"          "test -e '$TMP3/.pi/skills' -o -f '$TMP3/.pi/skills.md'"
check "re-init keeps old harness"          "test -f '$TMP3/.claude/commands/ck-feature.md'"
check "re-init still no copilot"           "! test -d '$TMP3/.github/skills'"

check "init requires a harness"            "! ( cd '$TMP3' && rm -rf .craftkit-project && CRAFTKIT_SRC='$KIT_REPO' sh '$KIT_REPO/bin/craftkit' init < /dev/null >/dev/null 2>&1 )"
check "init rejects unknown harness"       "! ( cd '$TMP3' && CRAFTKIT_SRC='$KIT_REPO' sh '$KIT_REPO/bin/craftkit' init --harnesses bogus < /dev/null >/dev/null 2>&1 )"

echo "== update detects harnesses on pre-0.3 repos =="
# Simulate a pre-0.3 install: project.yaml without a harnesses: key. update
# must infer the enabled harnesses from the files present, not wire all three.
(
  cd "$TMP3"
  CRAFTKIT_SRC="$KIT_REPO" sh "$KIT_REPO/bin/craftkit" init --harnesses claude-code,pi < /dev/null > init.log 2>&1 || { cat init.log; exit 1; }
  grep -v '^harnesses:' .craftkit-project/project.yaml > p.tmp && mv p.tmp .craftkit-project/project.yaml
  CRAFTKIT_SRC="$KIT_REPO" sh .craftkit/bin/craftkit update > update.log 2>&1 || { cat update.log; exit 1; }
)
check "update backfills harnesses key"   "grep -q 'harnesses: \[claude-code, pi\]' '$TMP3/.craftkit-project/project.yaml'"
check "update skips absent harness"      "! test -d '$TMP3/.github'"
check "update keeps present harnesses"   "test -f '$TMP3/.claude/commands/ck-feature.md' -a -e '$TMP3/.pi/skills'"
check "update: doctor passes"            "( cd '$TMP3' && sh .craftkit/bin/craftkit doctor )"

# A machine-wide CLI that differs from the repo-vendored copy must delegate to
# it (otherwise `craftkit update` looks like a no-op for new commands).
cp "$TMP3/.craftkit/bin/craftkit" "$TMP3/vendored-cli.bak"
printf '#!/bin/sh\necho "vendored-cli $*"\n' > "$TMP3/.craftkit/bin/craftkit"
check "stale CLI delegates to vendored"  "( cd '$TMP3' && sh '$KIT_REPO/bin/craftkit' version | grep -q 'vendored-cli version' )"
mv "$TMP3/vendored-cli.bak" "$TMP3/.craftkit/bin/craftkit"
check "identical CLI does not delegate"  "( cd '$TMP3' && CRAFTKIT_SRC='$KIT_REPO' sh '$KIT_REPO/bin/craftkit' version >/dev/null )"

echo "== craftkit remove =="
# TMP2 has all three harnesses enabled; peel one off, then uninstall.
( cd "$TMP2" && sh .craftkit/bin/craftkit remove copilot-cli > remove.log 2>&1 ) || cat "$TMP2/remove.log"
check "remove: copilot shims gone"        "! test -d '$TMP2/.github/skills'"
check "remove: copilot instructions gone" "! test -f '$TMP2/.github/copilot-instructions.md'"
check "remove: .github dir cleaned up"    "! test -d '$TMP2/.github'"
check "remove: harnesses list updated"    "grep -q 'harnesses: \[claude-code, pi\]' '$TMP2/.craftkit-project/project.yaml'"
check "remove: other harnesses untouched" "test -f '$TMP2/.claude/commands/ck-feature.md' -a -e '$TMP2/.pi/skills'"
check "remove: doctor still passes"       "( cd '$TMP2' && sh .craftkit/bin/craftkit doctor )"
check "remove rejects unknown harness"    "! ( cd '$TMP2' && sh .craftkit/bin/craftkit remove bogus >/dev/null 2>&1 )"

( cd "$TMP2" && echo '# team note' >> CLAUDE.md )   # team content must survive the block strip
( cd "$TMP2" && sh .craftkit/bin/craftkit remove all > remove-all.log 2>&1 ) || cat "$TMP2/remove-all.log"
check "remove all: kit gone"              "! test -d '$TMP2/.craftkit'"
check "remove all: project config gone"   "! test -d '$TMP2/.craftkit-project'"
check "remove all: claude shims gone"     "! test -d '$TMP2/.claude'"
check "remove all: pi wiring gone"        "! test -d '$TMP2/.pi'"
check "remove all: AGENTS.md gone"        "! test -f '$TMP2/AGENTS.md'"
check "remove all: ONBOARDING.md gone"    "! test -f '$TMP2/ONBOARDING.md'"
check "remove all: team CLAUDE.md kept"   "grep -q 'team note' '$TMP2/CLAUDE.md' && ! grep -q 'craftkit:begin' '$TMP2/CLAUDE.md'"

echo "== result: $PASS passed, $FAIL failed =="
[ "$FAIL" -eq 0 ]
