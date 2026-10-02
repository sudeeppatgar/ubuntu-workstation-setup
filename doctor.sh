#!/usr/bin/env bash

set -u

echo
echo "=============================================="
echo "   Development Workstation Health Check"
echo "=============================================="
echo

PASS=0
WARN=0
FAIL=0

check_command() {
    local name="$1"
    local command_name="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        echo "✓ $name: $(command -v "$command_name")"
        PASS=$((PASS + 1))
    else
        echo "✗ $name: not found"
        FAIL=$((FAIL + 1))
    fi
}

check_path() {
    local name="$1"
    local path="$2"

    if [[ -e "$path" ]]; then
        echo "✓ $name: $path"
        PASS=$((PASS + 1))
    else
        echo "✗ $name: missing"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Core tools ==="

check_command "Git" git
check_command "GitHub CLI" gh
check_command "Node.js" node
check_command "npm" npm
check_command "pnpm" pnpm
check_command "OpenCode" opencode
check_command "VS Code" code
check_command "Google Chrome" google-chrome
check_command "VLC" vlc
check_command "Docker" docker
check_command "SSH" ssh

echo
echo "=== Docker ==="

if command -v docker >/dev/null 2>&1; then
    if docker info >/dev/null 2>&1; then
        echo "✓ Docker daemon: accessible"
        PASS=$((PASS + 1))
    else
        echo "⚠ Docker daemon: not accessible from current shell"
        echo "  You may need to log out and log back in after docker-group setup."
        WARN=$((WARN + 1))
    fi

    if docker compose version >/dev/null 2>&1; then
        echo "✓ Docker Compose: available"
        PASS=$((PASS + 1))
    else
        echo "✗ Docker Compose: unavailable"
        FAIL=$((FAIL + 1))
    fi

    if docker network inspect dev-network >/dev/null 2>&1; then
        echo "✓ Docker network: dev-network"
        PASS=$((PASS + 1))
    else
        echo "⚠ Docker network: dev-network not found"
        WARN=$((WARN + 1))
    fi
fi

echo
echo "=== Git ==="

GIT_NAME="$(git config --global --get user.name || true)"
GIT_EMAIL="$(git config --global --get user.email || true)"

if [[ -n "$GIT_NAME" ]]; then
    echo "✓ Git name: $GIT_NAME"
    PASS=$((PASS + 1))
else
    echo "✗ Git name: not configured"
    FAIL=$((FAIL + 1))
fi

if [[ -n "$GIT_EMAIL" ]]; then
    echo "✓ Git email: $GIT_EMAIL"
    PASS=$((PASS + 1))
else
    echo "✗ Git email: not configured"
    FAIL=$((FAIL + 1))
fi

echo
echo "=== GitHub / SSH ==="

if [[ -f "$HOME/.ssh/id_ed25519_personal" ]]; then
    echo "✓ Personal SSH key exists"
    PASS=$((PASS + 1))
else
    echo "ℹ Personal SSH key: not configured"
fi

if [[ -f "$HOME/.ssh/config" ]] &&
   grep -q "^Host github-personal$" "$HOME/.ssh/config"; then
    echo "✓ github-personal SSH host configured"
    PASS=$((PASS + 1))
else
    echo "ℹ github-personal SSH host: not configured"
fi

if command -v gh >/dev/null 2>&1; then
    if gh auth status >/dev/null 2>&1; then
        echo "✓ GitHub CLI: authenticated"
        PASS=$((PASS + 1))
    else
        echo "⚠ GitHub CLI: not authenticated"
        WARN=$((WARN + 1))
    fi
else
    echo "⚠ GitHub CLI: unavailable"
    WARN=$((WARN + 1))
fi

echo
echo "=== Dotfiles ==="

check_path "Git config" "$HOME/dotfiles/git/gitconfig"
check_path "Global Git ignore" "$HOME/dotfiles/git/gitignore_global"
check_path "Shell config" "$HOME/dotfiles/shell/bashrc"
check_path "Shell aliases" "$HOME/dotfiles/shell/aliases"
check_path "Shell exports" "$HOME/dotfiles/shell/exports"
check_path "Shell functions" "$HOME/dotfiles/shell/functions"
check_path "Shell prompt" "$HOME/dotfiles/shell/prompt"

echo
echo "=== VS Code ==="

check_path "VS Code settings" "$HOME/dotfiles/vscode/settings.json"
check_path "VS Code keybindings" "$HOME/dotfiles/vscode/keybindings.json"
check_path "VS Code extensions list" "$HOME/dotfiles/vscode/extensions.txt"

echo
echo "=== Docker configuration ==="

check_path "Docker Compose" "$HOME/dotfiles/docker/compose.yml"
check_path "Docker daemon config" "$HOME/dotfiles/docker/daemon.json"
check_path "Docker env example" "$HOME/dotfiles/docker/.env.example"

if [[ -f "$HOME/dotfiles/docker/.env" ]]; then
    echo "✓ Docker local environment: configured"
    PASS=$((PASS + 1))

    PERMISSIONS="$(stat -c '%a' "$HOME/dotfiles/docker/.env")"
    if [[ "$PERMISSIONS" == "600" ]]; then
        echo "✓ Docker local environment permissions: 600"
        PASS=$((PASS + 1))
    else
        echo "⚠ Docker local environment permissions: $PERMISSIONS (expected 600)"
        WARN=$((WARN + 1))
    fi
else
    echo "⚠ Docker local environment: not configured"
    WARN=$((WARN + 1))
fi

echo
echo "=== GNOME ==="

if command -v gnome-shell >/dev/null 2>&1; then
    check_command "GNOME Extensions" gnome-extensions
    check_command "DConf" dconf

    while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue

    if gnome-extensions info "$extension" >/dev/null 2>&1; then
        echo "✓ GNOME extension installed: $extension"
        ((PASS+=1))
    else
        echo "✗ GNOME extension missing: $extension"
        ((FAIL+=1))
        continue
    fi

    if gnome-extensions list --enabled | grep -Fxq "$extension"; then
        echo "✓ GNOME extension enabled: $extension"
        ((PASS+=1))
    else
        echo "✗ GNOME extension disabled: $extension"
        ((FAIL+=1))
    fi
done < "$HOME/dotfiles/gnome/extensions.txt"

    check_path "Desktop Cube config" "$HOME/dotfiles/gnome/dconf/desktop-cube.dconf"
    check_path "Window shortcuts config" "$HOME/dotfiles/gnome/dconf/wm-keybindings.dconf"
    check_path "Shell shortcuts config" "$HOME/dotfiles/gnome/dconf/shell-keybindings.dconf"
    check_path "Desktop Cube wallpaper" "$HOME/dotfiles/gnome/wallpapers/skyblue.png"
    check_path "Ubuntu wallpaper" "$HOME/dotfiles/gnome/wallpapers/wallpaper.png"
else
    echo "⚠ GNOME Shell not detected"
    ((WARN+=1))
fi

echo
echo "=== Workspace ==="

check_path "Work workspace" "$HOME/Workspace/Work"
check_path "Personal workspace" "$HOME/Workspace/Personal"
check_path "Learning workspace" "$HOME/Workspace/Learning"
check_path "Archive workspace" "$HOME/Workspace/Archive"
check_path "Boeing workspace" "$HOME/Workspace/Boeing"

echo
echo "=============================================="
echo "Passed:   $PASS"
echo "Warnings: $WARN"
echo "Failed:   $FAIL"
echo "=============================================="
echo

if [[ "$FAIL" -eq 0 ]]; then
    echo "Workstation health check completed successfully."
    exit 0
else
    echo "Some checks failed. Review the output above."
    exit 1
fi
