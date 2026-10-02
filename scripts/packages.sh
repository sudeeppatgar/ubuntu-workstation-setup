#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "Installing base Ubuntu packages..."

sudo apt update

sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    zip \
    tar \
    gzip \
    build-essential \
    pkg-config \
    ca-certificates \
    gnupg \
    software-properties-common \
    apt-transport-https \
    tree \
    jq \
    ripgrep \
    fd-find \
    htop \
    net-tools \
    dnsutils \
    openssh-client \
    openssl \
    vlc

echo
echo "Base packages installed successfully."

# ------------------------------------------------
# Google Chrome
# ------------------------------------------------

echo
echo "Setting up Google Chrome..."

if command -v google-chrome >/dev/null 2>&1; then
    echo "Google Chrome is already installed."
    google-chrome --version
else
    echo "Installing Google Chrome..."

    sudo install -d -m 0755 /etc/apt/keyrings

    if [[ ! -f /etc/apt/keyrings/google-chrome.gpg ]]; then
        curl -fsSL https://dl.google.com/linux/linux_signing_key.pub |
            gpg --dearmor |
            sudo tee /etc/apt/keyrings/google-chrome.gpg > /dev/null
    fi

    sudo chmod a+r /etc/apt/keyrings/google-chrome.gpg

    echo \
        "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" |
        sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

    sudo apt update
    sudo apt install -y google-chrome-stable

    echo "Google Chrome installed."
    google-chrome --version
fi

echo
echo "Package setup completed successfully."
