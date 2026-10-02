#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "Setting up VS Code..."

VSCODE_DIR="$DOTFILES_DIR/vscode"
USER_VSCODE_DIR="$HOME/.config/Code/User"
BACKUP_DIR="$HOME/.config/Code/User.backup-$(date +%Y%m%d-%H%M%S)"

# ------------------------------------------------
# Install / update VS Code
# ------------------------------------------------

echo
echo "Configuring Microsoft VS Code repository..."

sudo apt update
sudo apt install -y wget

sudo install -m 0755 -d /etc/apt/keyrings

if [[ ! -f /etc/apt/keyrings/microsoft.asc ]]; then
    sudo wget -q \
        https://packages.microsoft.com/keys/microsoft.asc \
        -O /etc/apt/keyrings/microsoft.asc
fi

sudo chmod a+r /etc/apt/keyrings/microsoft.asc

if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.asc] https://packages.microsoft.com/repos/code stable main" |
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
fi

sudo apt update
sudo apt install -y code

echo "VS Code: $(code --version | head -n 1)"

# ------------------------------------------------
# VS Code configuration
# ------------------------------------------------

mkdir -p "$USER_VSCODE_DIR"

BACKUP_NEEDED=false

if [[ -f "$USER_VSCODE_DIR/settings.json" ]] && \
   [[ -f "$VSCODE_DIR/settings.json" ]] && \
   ! cmp -s "$USER_VSCODE_DIR/settings.json" "$VSCODE_DIR/settings.json"; then
    BACKUP_NEEDED=true
fi

if [[ -f "$USER_VSCODE_DIR/keybindings.json" ]] && \
   [[ -f "$VSCODE_DIR/keybindings.json" ]] && \
   ! cmp -s "$USER_VSCODE_DIR/keybindings.json" "$VSCODE_DIR/keybindings.json"; then
    BACKUP_NEEDED=true
fi

if [[ "$BACKUP_NEEDED" == "true" ]]; then
    mkdir -p "$BACKUP_DIR"

    [[ -f "$USER_VSCODE_DIR/settings.json" ]] &&
        cp "$USER_VSCODE_DIR/settings.json" "$BACKUP_DIR/settings.json"

    [[ -f "$USER_VSCODE_DIR/keybindings.json" ]] &&
        cp "$USER_VSCODE_DIR/keybindings.json" "$BACKUP_DIR/keybindings.json"

    echo
    echo "Existing VS Code configuration backed up to:"
    echo "  $BACKUP_DIR"
fi

if [[ -f "$VSCODE_DIR/settings.json" ]]; then
    cp "$VSCODE_DIR/settings.json" "$USER_VSCODE_DIR/settings.json"
    echo "Installed VS Code settings."
fi

if [[ -f "$VSCODE_DIR/keybindings.json" ]]; then
    cp "$VSCODE_DIR/keybindings.json" "$USER_VSCODE_DIR/keybindings.json"
    echo "Installed VS Code keybindings."
fi

# ------------------------------------------------
# VS Code extensions
# ------------------------------------------------

if [[ -f "$VSCODE_DIR/extensions.txt" ]]; then
    echo
    echo "Installing VS Code extensions..."

    while IFS= read -r extension || [[ -n "$extension" ]]; do
        [[ -z "$extension" ]] && continue
        [[ "$extension" =~ ^[[:space:]]*# ]] && continue

        echo "  Installing: $extension"
        code --install-extension "$extension"
    done < "$VSCODE_DIR/extensions.txt"
fi

echo
echo "VS Code setup completed."
