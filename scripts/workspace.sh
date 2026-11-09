#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "Setting up workspace directories..."

WORKSPACE="$HOME/Workspace"

mkdir -p \
    "$WORKSPACE/Work" \
    "$WORKSPACE/Personal" \
    "$WORKSPACE/Learning" \
    "$WORKSPACE/Archive"

echo
echo "Workspace ready:"
echo
echo "  $WORKSPACE/Work"
echo "  $WORKSPACE/Personal"
echo "  $WORKSPACE/Learning"
echo "  $WORKSPACE/Archive"
