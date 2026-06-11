#!/bin/sh
# CraftKit adapter: Claude Code
# Generates .claude/commands/ck-*.md shims and a marked block in CLAUDE.md.
# Idempotent — safe to re-run via `craftkit sync`. Never edit shims by hand.
set -eu

REPO_ROOT="${1:-$(pwd)}"
KIT_DIR="$REPO_ROOT/.craftkit"
CMD_DIR="$REPO_ROOT/.claude/commands"

[ -d "$KIT_DIR/skills" ] || { echo "claude-code adapter: $KIT_DIR/skills not found" >&2; exit 1; }

mkdir -p "$CMD_DIR"
rm -f "$CMD_DIR"/ck-*.md

# Workflows own the /ck-<name> shim on name collisions with skills.
for wf in "$KIT_DIR"/workflows/*.md; do
  [ -f "$wf" ] || continue
  name=$(basename "$wf" .md)
  printf 'Read and follow `./.craftkit/workflows/%s.md`.\n' "$name" > "$CMD_DIR/ck-$name.md"
done

for sk in "$KIT_DIR"/skills/*/SKILL.md; do
  [ -f "$sk" ] || continue
  name=$(basename "$(dirname "$sk")")
  [ "$name" = "references" ] && continue
  [ -f "$KIT_DIR/workflows/$name.md" ] && continue  # workflow owns this name
  printf 'Read and follow `./.craftkit/skills/%s/SKILL.md`.\n' "$name" > "$CMD_DIR/ck-$name.md"
done

# Honor repo-local skill overrides.
if [ -d "$REPO_ROOT/.craftkit-project/overrides" ]; then
  for ov in "$REPO_ROOT"/.craftkit-project/overrides/*/SKILL.md; do
    [ -f "$ov" ] || continue
    name=$(basename "$(dirname "$ov")")
    printf 'Read and follow `./.craftkit-project/overrides/%s/SKILL.md`.\n' "$name" > "$CMD_DIR/ck-$name.md"
  done
fi

# settings.json: create a minimal default if absent; never overwrite.
SETTINGS="$REPO_ROOT/.claude/settings.json"
if [ ! -f "$SETTINGS" ]; then
  cat > "$SETTINGS" <<'EOF'
{
  "permissions": {
    "deny": [
      "Agent"
    ]
  }
}
EOF
fi

# CLAUDE.md: maintain a regenerable marked block.
CLAUDE_MD="$REPO_ROOT/CLAUDE.md"
BLOCK=$(cat <<'EOF'
<!-- craftkit:begin (generated — do not edit; run `craftkit sync`) -->
## CraftKit

This repo uses CraftKit. Read `AGENTS.md` for the module registry, pipeline,
and critical rules — all rules there apply.

- Commands: `/ck-feature`, `/ck-bugfix`, `/ck-deps`, `/ck-review`,
  `/ck-onboard`, plus individual phase skills (`/ck-requirements`, …).
- Use only Read, Write, Edit, and Bash tools unless the user explicitly
  requests otherwise. No subagents, no MCP, no web access inside skills.
- Be minimal: load only what the current phase requires; never load all
  skills or artifacts speculatively.
- Artifacts must have `status: approved` before a downstream skill consumes
  them. Follow `.craftkit/skills/references/escalation-protocol.md` exactly.
<!-- craftkit:end -->
EOF
)
TMP=$(mktemp)
if [ -f "$CLAUDE_MD" ] && grep -q '<!-- craftkit:begin' "$CLAUDE_MD"; then
  awk '/<!-- craftkit:begin/{skip=1} !skip{print} /<!-- craftkit:end -->/{skip=0}' "$CLAUDE_MD" > "$TMP"
else
  [ -f "$CLAUDE_MD" ] && cat "$CLAUDE_MD" > "$TMP" || printf '# CLAUDE.md\n\n' > "$TMP"
fi
printf '%s\n' "$BLOCK" >> "$TMP"
mv "$TMP" "$CLAUDE_MD"

echo "claude-code adapter: $(ls "$CMD_DIR"/ck-*.md | wc -l | tr -d ' ') shims, CLAUDE.md block updated"
