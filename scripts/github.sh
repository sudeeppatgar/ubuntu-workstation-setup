#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "Setting up GitHub..."

# ------------------------------------------------
# Install GitHub CLI
# ------------------------------------------------

if command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI is already installed."
else
    echo "Installing GitHub CLI..."

    sudo apt update
    sudo apt install -y gh
fi

echo
echo "GitHub CLI:"
gh --version | head -n 1

# ------------------------------------------------
# SSH directory
# ------------------------------------------------

SSH_DIR="$HOME/.ssh"
PERSONAL_KEY="$SSH_DIR/id_ed25519_personal"
SSH_CONFIG="$SSH_DIR/config"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ------------------------------------------------
# Generate personal SSH key
# ------------------------------------------------

if [[ -f "$PERSONAL_KEY" ]]; then
    echo
    echo "Personal SSH key already exists:"
    echo "  $PERSONAL_KEY"
else
    echo
    echo "Personal GitHub SSH key does not exist."

    read -r -p "Create a personal GitHub SSH key now? [y/N]: " CREATE_KEY

    if [[ "$CREATE_KEY" =~ ^[Yy]$ ]]; then
        ssh-keygen \
            -t ed25519 \
            -f "$PERSONAL_KEY" \
            -C "$(git config --global --get user.email || echo 'github-personal')"

        chmod 600 "$PERSONAL_KEY"
        chmod 644 "${PERSONAL_KEY}.pub"

        echo "Personal GitHub SSH key created:"
        echo "  $PERSONAL_KEY"
    else
        echo "Skipping personal GitHub SSH key creation."
    fi
fi

# ------------------------------------------------
# SSH config
# ------------------------------------------------

touch "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

if grep -q "^Host github-personal$" "$SSH_CONFIG"; then
    echo
    echo "SSH host 'github-personal' already configured."
else
    cat >> "$SSH_CONFIG" <<'SSH'

Host github-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_personal
    IdentitiesOnly yes
SSH

    echo
    echo "Added SSH host: github-personal"
fi

# ------------------------------------------------
# SSH key fingerprint
# ------------------------------------------------

if [[ -f "${PERSONAL_KEY}.pub" ]]; then
    echo
    echo "SSH key fingerprint:"
    ssh-keygen -lf "${PERSONAL_KEY}.pub"
fi

# ------------------------------------------------
# GitHub authentication status
# ------------------------------------------------

echo
echo "GitHub authentication:"

if gh auth status >/dev/null 2>&1; then
    echo "GitHub CLI is already authenticated."
else
    echo "GitHub CLI is not authenticated."
    echo
    echo "Authentication must be completed interactively."
    echo "Run:"
    echo
    echo "  gh auth login"
fi

# ------------------------------------------------
# Public key
# ------------------------------------------------

if [[ -f "${PERSONAL_KEY}.pub" ]]; then
    echo
    echo "If this SSH key is not yet added to GitHub,"
    echo "add the following public key to your GitHub account:"
    echo
    cat "${PERSONAL_KEY}.pub"
    echo
fi

echo "GitHub setup completed."
