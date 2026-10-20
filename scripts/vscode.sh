```bash
#!/usr/bin/env bash

set -euo pipefail

echo "Setting up Microsoft VS Code..."

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

echo
echo "VS Code installation completed."
echo "Settings, keybindings, and extensions are managed by VS Code Settings Sync."
```
