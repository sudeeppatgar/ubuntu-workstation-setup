#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo
echo "=============================================="
echo "   Sudeep's Development Workstation Setup"
echo "=============================================="
echo
echo "Dotfiles: $DOTFILES_DIR"
echo

# ------------------------------------------------
# Check operating system
# ------------------------------------------------

if [[ ! -f /etc/os-release ]]; then
    echo "ERROR: Cannot determine operating system."
    exit 1
fi

source /etc/os-release

if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "ERROR: This installer currently supports Ubuntu only."
    echo "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

echo "Detected: $PRETTY_NAME"
echo

# ------------------------------------------------
# Check architecture
# ------------------------------------------------

ARCH="$(dpkg --print-architecture)"

if [[ "$ARCH" != "amd64" ]]; then
    echo "ERROR: This installer currently supports amd64."
    echo "Detected architecture: $ARCH"
    exit 1
fi

echo "Architecture: $ARCH"
echo

# ------------------------------------------------
# Require sudo
# ------------------------------------------------

if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is required."
    exit 1
fi

echo "Sudo access: OK"
echo

# ------------------------------------------------
# Installation modules
# ------------------------------------------------

MODULES=(
    packages.sh
    docker.sh
    node.sh
    vscode.sh
    git.sh
    github.sh
    shell.sh
    gnome.sh
    workspace.sh
)

for module in "${MODULES[@]}"; do
    if [[ ! -f "$DOTFILES_DIR/scripts/$module" ]]; then
        echo "ERROR: Installation module not found:"
        echo "  $DOTFILES_DIR/scripts/$module"
        exit 1
    fi
done

echo "Installation modules: OK"
echo

run_module() {
    local module="$1"

    echo
    echo "----------------------------------------------"
    echo "Running: $module"
    echo "----------------------------------------------"
    echo

    DOTFILES_DIR="$DOTFILES_DIR" bash "$DOTFILES_DIR/scripts/$module"
}

for module in "${MODULES[@]}"; do
    run_module "$module"
done

# ------------------------------------------------
# Finished
# ------------------------------------------------

echo
echo "=============================================="
echo "   Workstation setup completed"
echo "=============================================="
echo
echo "Run this to verify the installation:"
echo
echo "    ./doctor.sh"
echo
