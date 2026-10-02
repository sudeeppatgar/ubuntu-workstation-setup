#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "Setting up Bash configuration..."

SHELL_DIR="$DOTFILES_DIR/shell"
BASHRC="$HOME/.bashrc"

MARKER_START="# >>> sudeep-dotfiles >>>"
MARKER_END="# <<< sudeep-dotfiles <<<"

# ------------------------------------------------
# Verify shell configuration
# ------------------------------------------------

if [[ ! -f "$SHELL_DIR/bashrc" ]]; then
    echo "ERROR: $SHELL_DIR/bashrc not found."
    exit 1
fi

# ------------------------------------------------
# Backup existing .bashrc
# ------------------------------------------------

if [[ -f "$BASHRC" ]] && ! grep -qF "$MARKER_START" "$BASHRC"; then

    BACKUP="$BASHRC.backup-$(date +%Y%m%d-%H%M%S)"

    cp "$BASHRC" "$BACKUP"

    echo "Backed up existing .bashrc to:"
    echo "  $BACKUP"

fi

# ------------------------------------------------
# Remove previous managed block
# ------------------------------------------------

if [[ -f "$BASHRC" ]] && grep -qF "$MARKER_START" "$BASHRC"; then

    awk -v start="$MARKER_START" -v end="$MARKER_END" '
        $0 == start {
            in_block = 1
            next
        }

        $0 == end {
            in_block = 0
            next
        }

        !in_block {
            print
        }
    ' "$BASHRC" > "$BASHRC.tmp"

    mv "$BASHRC.tmp" "$BASHRC"

fi

# ------------------------------------------------
# Add managed configuration
# ------------------------------------------------

cat >> "$BASHRC" <<EOF2

$MARKER_START
# Managed by ~/dotfiles
source "$SHELL_DIR/bashrc"
$MARKER_END
EOF2

echo
echo "Bash configuration installed."

echo
echo "Managed configuration:"
echo "  $SHELL_DIR/bashrc"

echo
echo "Reload your shell with:"
echo "  source ~/.bashrc"
