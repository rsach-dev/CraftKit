#!/bin/sh
# CraftKit installer — puts the `craftkit` command on your PATH.
#
#   curl -fsSL https://raw.githubusercontent.com/rsach-dev/CraftKit/main/install.sh | sh
#
# Options (env vars):
#   CRAFTKIT_INSTALL_DIR  install location (default: ~/.local/bin)
#   CRAFTKIT_VERSION      git ref to install from (default: main)
#   CRAFTKIT_SRC          local CraftKit checkout to install from (offline)
set -eu

RAW_BASE="https://raw.githubusercontent.com/rsach-dev/CraftKit"
REF="${CRAFTKIT_VERSION:-main}"
INSTALL_DIR="${CRAFTKIT_INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$INSTALL_DIR/craftkit"

say() { printf '%s\n' "$*"; }
die() { printf 'craftkit installer: %s\n' "$*" >&2; exit 1; }

mkdir -p "$INSTALL_DIR" || die "cannot create $INSTALL_DIR"

if [ -n "${CRAFTKIT_SRC:-}" ]; then
  [ -f "$CRAFTKIT_SRC/bin/craftkit" ] || die "no bin/craftkit in CRAFTKIT_SRC=$CRAFTKIT_SRC"
  cp "$CRAFTKIT_SRC/bin/craftkit" "$TARGET"
elif command -v curl >/dev/null 2>&1; then
  curl -fsSL "$RAW_BASE/$REF/bin/craftkit" -o "$TARGET" || die "download failed ($RAW_BASE/$REF/bin/craftkit)"
elif command -v wget >/dev/null 2>&1; then
  wget -q "$RAW_BASE/$REF/bin/craftkit" -O "$TARGET" || die "download failed ($RAW_BASE/$REF/bin/craftkit)"
else
  die "need curl or wget (or set CRAFTKIT_SRC to a local checkout)"
fi

chmod +x "$TARGET"
head -2 "$TARGET" | grep -q craftkit || die "downloaded file does not look like the craftkit CLI"

say "Installed: $TARGET"
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) say ""
     say "NOTE: $INSTALL_DIR is not on your PATH. Add this to your shell profile:"
     say "  export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
esac
say ""
say "Get started in any repository:"
say "  cd <your-repo> && craftkit init"
