#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

echo "Setting up Docker..."

DOCKER_DIR="$DOTFILES_DIR/docker"

# ------------------------------------------------
# Install Docker
# ------------------------------------------------

if command -v docker >/dev/null 2>&1 && \
   docker compose version >/dev/null 2>&1; then

    echo "Docker and Docker Compose are already installed."
    docker --version
    docker compose version

else
    echo "Installing Docker and Docker Compose..."

    sudo apt update

    sudo apt install -y \
        ca-certificates \
        curl \
        gnupg

    sudo install -m 0755 -d /etc/apt/keyrings

    if [[ ! -f /etc/apt/keyrings/docker.asc ]]; then
        sudo curl -fsSL \
            https://download.docker.com/linux/ubuntu/gpg \
            -o /etc/apt/keyrings/docker.asc
    fi

    sudo chmod a+r /etc/apt/keyrings/docker.asc

    if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
        # shellcheck disable=SC1091
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    fi

    sudo apt update

    sudo apt install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    echo "Docker and Docker Compose installed."
fi

# ------------------------------------------------
# Docker daemon configuration
# ------------------------------------------------

if [[ -f "$DOCKER_DIR/daemon.json" ]]; then

    echo
    echo "Checking Docker daemon configuration..."

    sudo install -d -m 0755 /etc/docker

    if [[ ! -f /etc/docker/daemon.json ]] || \
       ! sudo cmp -s "$DOCKER_DIR/daemon.json" /etc/docker/daemon.json; then

        sudo cp "$DOCKER_DIR/daemon.json" /etc/docker/daemon.json

        echo "Docker daemon configuration updated."

        if systemctl is-active --quiet docker; then
            echo "Restarting Docker to apply configuration..."
            sudo systemctl restart docker
        fi

    else
        echo "Docker daemon configuration is already up to date."
    fi
fi

# ------------------------------------------------
# Docker service
# ------------------------------------------------

sudo systemctl enable docker.service
sudo systemctl enable containerd.service

if systemctl is-active --quiet docker; then
    echo "Docker service is running."
else
    sudo systemctl start docker
    echo "Docker service started."
fi

# ------------------------------------------------
# Docker group
# ------------------------------------------------

if ! getent group docker >/dev/null 2>&1; then
    sudo groupadd docker
fi

if id -nG "$USER" | grep -qw docker; then
    echo "User '$USER' is already in the docker group."
else
    sudo usermod -aG docker "$USER"

    echo
    echo "User '$USER' was added to the docker group."
    echo "The current shell does not have the new group yet."
fi

# ------------------------------------------------
# Development network
# ------------------------------------------------

echo
echo "Checking Docker network..."

if sudo docker network inspect dev-network >/dev/null 2>&1; then
    echo "Docker network 'dev-network' already exists."
else
    echo "Creating Docker network 'dev-network'..."
    sudo docker network create dev-network >/dev/null
    echo "Docker network 'dev-network' created."
fi

# ------------------------------------------------
# Local environment file
# ------------------------------------------------

if [[ -f "$DOCKER_DIR/.env" ]]; then

    echo
    echo "Docker .env already exists."
    echo "Keeping the existing credentials."

else

    echo
    echo "Creating Docker development environment..."

    DEFAULT_USER="devuser"

    read -r -p "Local development username [$DEFAULT_USER]: " DEV_USER
    DEV_USER="${DEV_USER:-$DEFAULT_USER}"

    while true; do
    read -r -s -p "Local development password: " DEV_PASSWORD
        echo

        if [[ -z "$DEV_PASSWORD" ]]; then
            echo "Password must not be empty."
            continue
        fi

        read -r -s -p "Confirm password: " DEV_PASSWORD_CONFIRM
        echo

        if [[ "$DEV_PASSWORD" == "$DEV_PASSWORD_CONFIRM" ]]; then
            break
        fi

        echo
        echo "Passwords do not match. Please try again."
        echo
    done

    cat > "$DOCKER_DIR/.env" <<ENV
TZ=Asia/Kolkata

DEV_USER=$DEV_USER
DEV_PASSWORD=$DEV_PASSWORD

ADMIN_EMAIL=admin@example.com
ADMIN_PASSWORD=$DEV_PASSWORD

S3_ACCESS_KEY=devstorage
S3_SECRET_KEY=$DEV_PASSWORD
S3_BUCKET=dev-bucket

POSTGRES_USER=$DEV_USER
POSTGRES_PASSWORD=$DEV_PASSWORD
POSTGRES_DB=devdb

MONGO_USER=$DEV_USER
MONGO_PASSWORD=$DEV_PASSWORD

RABBITMQ_USER=$DEV_USER
RABBITMQ_PASSWORD=$DEV_PASSWORD

REDIS_PASSWORD=$DEV_PASSWORD
ENV

    chmod 600 "$DOCKER_DIR/.env"

    echo
    echo "Created:"
    echo "  $DOCKER_DIR/.env"
fi

# ------------------------------------------------
# Validate Docker Compose configuration
# ------------------------------------------------

echo
echo "Validating Docker Compose configuration..."

if ! sudo docker compose \
    --env-file "$DOCKER_DIR/.env" \
    -f "$DOCKER_DIR/compose.yml" \
    config >/dev/null; then

    echo "ERROR: Docker Compose configuration is invalid."
    exit 1
fi

echo "Docker Compose configuration is valid."

# ------------------------------------------------
# Verification
# ------------------------------------------------

echo
echo "Docker version:"
sudo docker --version

echo
echo "Docker Compose version:"
sudo docker compose version

echo
echo "Docker network:"
sudo docker network inspect dev-network --format '{{.Name}}'

echo
echo "Docker setup completed."
echo
echo "Containers were NOT started."
echo
echo "Start development services when needed:"
echo
echo "  cd $DOCKER_DIR"
echo "  docker compose up -d"
echo
echo "Stop them with:"
echo
echo "  docker compose down"
