#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

GNOME_DIR="$DOTFILES_DIR/gnome"
EXTENSIONS_FILE="$GNOME_DIR/extensions.txt"
EXTENSIONS_BASE_URL="https://extensions.gnome.org"

echo "Setting up GNOME..."

if ! command -v gnome-extensions >/dev/null 2>&1; then
    echo "ERROR: gnome-extensions command not found."
    exit 1
fi

if ! command -v dconf >/dev/null 2>&1; then
    echo "ERROR: dconf command not found."
    exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "ERROR: curl command not found."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq command not found."
    exit 1
fi

GNOME_SHELL_VERSION="$(gnome-shell --version | awk '{print $3}')"
GNOME_MAJOR_VERSION="${GNOME_SHELL_VERSION%%.*}"

if [[ -z "$GNOME_MAJOR_VERSION" ]]; then
    echo "ERROR: Unable to determine GNOME Shell version."
    exit 1
fi

echo
echo "GNOME Shell: $GNOME_SHELL_VERSION"

install_extension() {
    local extension="$1"
    local encoded_extension
    local api_url
    local response
    local version_tag
    local download_url
    local temp_dir
    local archive

    if gnome-extensions info "$extension" >/dev/null 2>&1; then
        echo "  Already installed: $extension"
        return
    fi

    echo "  Installing: $extension"

    encoded_extension="$(printf '%s' "$extension" | jq -sRr @uri)"

    api_url="$EXTENSIONS_BASE_URL/api/v1/extensions/${encoded_extension}/versions/"

    response="$(curl -fsSL \
        -H 'Accept: application/json' \
        "$api_url")"

    version_tag="$(
        printf '%s' "$response" |
            jq -r --arg shell "$GNOME_MAJOR_VERSION" '
                .results[]
                | select(.shell_version == $shell or (.shell_version | type) == "object")
                | .pk
            ' |
            head -n 1
    )"

    if [[ -z "$version_tag" || "$version_tag" == "null" ]]; then
        echo "ERROR: No compatible version found for:"
        echo "  $extension"
        echo "  GNOME Shell: $GNOME_SHELL_VERSION"
        exit 1
    fi

    download_url="$EXTENSIONS_BASE_URL/download-extension/${encoded_extension}.shell-extension.zip?version_tag=${version_tag}"

    temp_dir="$(mktemp -d)"
    archive="$temp_dir/${extension}.shell-extension.zip"

    trap 'rm -rf "$temp_dir"' RETURN

    curl -fsSL \
        -o "$archive" \
        "$download_url"

    gnome-extensions install --force "$archive"

    rm -rf "$temp_dir"

    echo "  Installed: $extension"
}

echo
echo "Installing GNOME extensions..."

while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue

    install_extension "$extension"
done < "$EXTENSIONS_FILE"

echo
echo "Enabling GNOME extensions..."

while IFS= read -r extension; do
    [[ -z "$extension" ]] && continue

    if gnome-extensions info "$extension" >/dev/null 2>&1; then
        gnome-extensions enable "$extension" || true
        echo "  Enabled: $extension"
    else
        echo "ERROR: Extension was not installed: $extension"
        exit 1
    fi
done < "$EXTENSIONS_FILE"

echo
echo "Installing WhiteSur icon theme..."

WHITESUR_ICONS_DIR="$HOME/.local/share/icons/WhiteSur"

if [[ -d "$WHITESUR_ICONS_DIR" ]]; then
    echo "  WhiteSur icons already installed."
else
    TEMP_DIR="$(mktemp -d)"

    git clone --depth=1 \
        https://github.com/vinceliuice/WhiteSur-icon-theme.git \
        "$TEMP_DIR/WhiteSur-icon-theme"

    (
        cd "$TEMP_DIR/WhiteSur-icon-theme"
        ./install.sh
    )

    rm -rf "$TEMP_DIR"

    echo "  WhiteSur icons installed."
fi

gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur'
echo "  Icon theme: WhiteSur"

echo
echo "Restoring GNOME keyboard shortcuts..."

dconf load /org/gnome/desktop/wm/keybindings/ \
    < "$GNOME_DIR/dconf/wm-keybindings.dconf"

dconf load /org/gnome/shell/keybindings/ \
    < "$GNOME_DIR/dconf/shell-keybindings.dconf"

echo "  Window shortcuts restored."
echo "  Shell shortcuts restored."

echo
echo "Installing wallpapers..."

WALLPAPER_DIR="$HOME/.local/share/backgrounds/sudeep"
mkdir -p "$WALLPAPER_DIR"

cp "$GNOME_DIR/wallpapers/skyblue.png" \
    "$WALLPAPER_DIR/skyblue.png"

cp "$GNOME_DIR/wallpapers/wallpaper.png" \
    "$WALLPAPER_DIR/wallpaper.png"

echo "  Skyblue panorama installed."
echo "  Desktop wallpaper installed."

echo
echo "Restoring Desktop Cube configuration..."

dconf load /org/gnome/shell/extensions/desktop-cube/ \
    < "$GNOME_DIR/dconf/desktop-cube.dconf"

dconf write     /org/gnome/shell/extensions/desktop-cube/background-panorama     "'$WALLPAPER_DIR/skyblue.png'"

echo "  Desktop Cube settings restored."
echo "  Desktop Cube panorama: $WALLPAPER_DIR/skyblue.png"

echo
echo "Restoring Ubuntu desktop wallpaper..."

gsettings set org.gnome.desktop.background picture-uri     "file://$WALLPAPER_DIR/wallpaper.png"

gsettings set org.gnome.desktop.background picture-uri-dark     "file://$WALLPAPER_DIR/wallpaper.png"

echo "  Desktop wallpaper: $WALLPAPER_DIR/wallpaper.png"

echo
echo "Restoring Ubuntu Dock configuration..."

dconf load /org/gnome/shell/extensions/dash-to-dock/ \
    < "$GNOME_DIR/dconf/ubuntu-dock.dconf"

echo "  Ubuntu Dock settings restored."

echo
echo "GNOME setup completed."
echo
echo "Note:"
echo "  Clipboard Indicator uses its default configuration."
echo "  Magic Lamp uses its default configuration."
echo "  Burn My Windows is intentionally not installed."
echo "  Desktop Cube wallpaper is included and configured."
