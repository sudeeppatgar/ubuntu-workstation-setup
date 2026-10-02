#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "Setting up Node.js..."

# ------------------------------------------------
# Node.js LTS repository
# ------------------------------------------------

echo
echo "Configuring NodeSource LTS repository..."

if [[ -f /etc/apt/sources.list.d/nodesource.list ]]; then
    echo "NodeSource repository is already configured."
else
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
fi

# ------------------------------------------------
# Check and install Node.js
# ------------------------------------------------

echo
echo "Checking Node.js..."

sudo apt update

AVAILABLE_VERSION="$(apt-cache policy nodejs | awk '/Candidate:/ {print $2}')"

if [[ -z "$AVAILABLE_VERSION" || "$AVAILABLE_VERSION" == "(none)" ]]; then
    echo "Unable to determine the Node.js LTS package version."
    exit 1
fi

if command -v node >/dev/null 2>&1; then

    CURRENT_VERSION="$(node -v)"
    CURRENT_PACKAGE_VERSION="$(dpkg-query -W -f='${Version}' nodejs 2>/dev/null || true)"

    echo "Installed Node.js: $CURRENT_VERSION"
    echo "Available Node.js: $AVAILABLE_VERSION"

    if [[ "$CURRENT_PACKAGE_VERSION" == "$AVAILABLE_VERSION" ]]; then
        echo "Node.js is already up to date."
    else
        echo "Updating Node.js to the current LTS release..."
        sudo apt install -y nodejs
    fi

else

    echo "Node.js is not installed."
    echo "Installing the current LTS release..."

    sudo apt install -y nodejs

fi

# ------------------------------------------------
# Verify Node.js and npm
# ------------------------------------------------

echo
echo "Node.js:"
node -v

echo
echo "npm:"
npm -v

# ------------------------------------------------
# pnpm
# ------------------------------------------------

echo
echo "Configuring pnpm..."

PNPM_PATH="$(command -v pnpm || true)"

if [[ -n "$PNPM_PATH" ]]; then
    echo "Existing pnpm found:"
    echo "  $PNPM_PATH"
    echo "  $(pnpm --version)"

    if [[ "$PNPM_PATH" == "/usr/bin/pnpm" ]] && \
       [[ -L "$PNPM_PATH" ]] && \
       readlink "$PNPM_PATH" | grep -q "corepack"; then

        echo "Corepack-managed pnpm detected."
        echo "Removing Corepack pnpm shim..."
        sudo rm -f "$PNPM_PATH"

        if [[ -L /usr/bin/pnpx ]]; then
            echo "Removing Corepack pnpx shim..."
            sudo rm -f /usr/bin/pnpx
        fi
    fi
fi

echo "Installing latest stable pnpm..."
sudo npm install --global pnpm@latest

echo
echo "pnpm:"
pnpm --version

# ------------------------------------------------
# OpenCode
# ------------------------------------------------

echo
echo "Installing OpenCode..."
sudo npm install --global opencode-ai

# ------------------------------------------------
# Verification
# ------------------------------------------------

echo
echo "Node.js setup completed."

echo
echo "Node.js:  $(node -v)"
echo "npm:      $(npm -v)"
echo "pnpm:     $(pnpm --version)"
