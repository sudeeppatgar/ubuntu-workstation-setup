#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "Setting up Git..."

GLOBAL_GITIGNORE="$DOTFILES_DIR/git/gitignore_global"

# ------------------------------------------------
# Install / update Git
# ------------------------------------------------

echo
echo "Installing / updating Git..."

sudo apt update
sudo apt install -y git

echo "Git version: $(git --version)"

# ------------------------------------------------
# Git identity
# ------------------------------------------------

CURRENT_NAME="$(git config --global --get user.name || true)"
CURRENT_EMAIL="$(git config --global --get user.email || true)"

if [[ -z "$CURRENT_NAME" ]]; then
    read -r -p "Enter your Git name: " GIT_NAME
    git config --global user.name "$GIT_NAME"
else
    echo "Git name already configured: $CURRENT_NAME"
fi

if [[ -z "$CURRENT_EMAIL" ]]; then
    read -r -p "Enter your Git email: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
else
    echo "Git email already configured: $CURRENT_EMAIL"
fi

# ------------------------------------------------
# Git defaults
# ------------------------------------------------

git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global merge.conflictStyle zdiff3
git config --global color.ui auto
git config --global fetch.prune true

# ------------------------------------------------
# Git aliases
# ------------------------------------------------

git config --global alias.st status
git config --global alias.br branch
git config --global alias.co checkout
git config --global alias.sw switch
git config --global alias.ci commit
git config --global alias.last 'log -1 HEAD'
git config --global alias.graph 'log --graph --oneline --decorate --all'

# ------------------------------------------------
# Global Git ignore
# ------------------------------------------------

if [[ -f "$GLOBAL_GITIGNORE" ]]; then
    git config --global core.excludesfile "$GLOBAL_GITIGNORE"
    echo "Global Git ignore configured."
fi

# ------------------------------------------------
# Git credential helper
# ------------------------------------------------

echo
echo "Checking Git credential helper..."

GIT_EXEC_PATH="$(git --exec-path)"
CREDENTIAL_HELPER="$GIT_EXEC_PATH/git-credential-libsecret"
LIBSECRET_SOURCE="$(dpkg -L git 2>/dev/null \
    | grep '/contrib/credential/libsecret/git-credential-libsecret.c$' \
    | head -n 1 || true)"

if [[ -x "$CREDENTIAL_HELPER" ]]; then

    echo "Git credential helper already installed."

else

    echo "Installing libsecret dependencies..."

    sudo apt install -y \
        libsecret-1-0 \
        libsecret-1-dev

    if [[ -z "$LIBSECRET_SOURCE" || ! -f "$LIBSECRET_SOURCE" ]]; then
        echo "ERROR: git-credential-libsecret source was not found:"
        echo "  $LIBSECRET_SOURCE"
        exit 1
    fi

    echo "Building git-credential-libsecret..."

    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT

    cp "$LIBSECRET_SOURCE" "$TEMP_DIR/git-credential-libsecret.c"

    # pkg-config output must be split into separate compiler flags
    # shellcheck disable=SC2046
    cc \
        "$TEMP_DIR/git-credential-libsecret.c" \
        -o "$TEMP_DIR/git-credential-libsecret" \
        $(pkg-config --cflags --libs libsecret-1)

    sudo install -m 0755 \
        "$TEMP_DIR/git-credential-libsecret" \
        "$CREDENTIAL_HELPER"

    echo "Git credential helper installed:"
    echo "  $CREDENTIAL_HELPER"

fi

git config --global credential.helper libsecret

# ------------------------------------------------
# Verification
# ------------------------------------------------

echo
echo "Git setup completed."

echo
echo "Git identity:"
git config --global --get user.name
git config --global --get user.email

echo
echo "Credential helper:"
git config --global --get credential.helper

echo
echo "Credential helper binary:"
if [[ -x "$CREDENTIAL_HELPER" ]]; then
    echo "  $CREDENTIAL_HELPER"
else
    echo "  ERROR: helper not found"
    exit 1
fi
