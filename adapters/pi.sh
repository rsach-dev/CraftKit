#!/bin/sh
# CraftKit adapter: pi
# Points pi's skill discovery and on-demand context at the kit:
#   .pi/skills    -> .craftkit/skills      (symlink)
#   .pi/workflows -> .craftkit/workflows   (symlink)
#   .pi/context   -> .craftkit-project/context (symlink)
# Falls back to pointer files where symlinks are unsupported.
# Idempotent — safe to re-run via `craftkit sync`.
set -eu

REPO_ROOT="${1:-$(pwd)}"
KIT_DIR="$REPO_ROOT/.craftkit"
PI_DIR="$REPO_ROOT/.pi"

[ -d "$KIT_DIR/skills" ] || { echo "pi adapter: $KIT_DIR/skills not found" >&2; exit 1; }

mkdir -p "$PI_DIR"
mkdir -p "$REPO_ROOT/.craftkit-project/context/profiles"

link() { # $1=link-path $2=relative-target
  # Refuse to clobber a real (non-symlink) directory the team may own.
  if [ -e "$1" ] && [ ! -L "$1" ]; then
    echo "pi adapter: $1 exists and is not a symlink — leaving it alone (point it at $2 manually)" >&2
    return 0
  fi
  rm -f "$1"
  if ln -s "$2" "$1" 2>/dev/null; then
    :
  else
    # Symlinks unsupported (e.g. some Windows setups): write a pointer file.
    printf 'CraftKit pointer: use `%s` (symlinks unsupported on this filesystem).\n' "$2" > "$1.md"
  fi
}

link "$PI_DIR/skills"    "../.craftkit/skills"
link "$PI_DIR/workflows" "../.craftkit/workflows"
link "$PI_DIR/context"   "../.craftkit-project/context"

echo "pi adapter: .pi/{skills,workflows,context} wired to the kit"
