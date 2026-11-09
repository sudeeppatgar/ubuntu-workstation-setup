# Ubuntu Workstation Setup

Personal workstation bootstrap and dotfiles for setting up an Ubuntu development machine. The repository automates common packages, developer tools, shell and Git preferences, optional local Docker services, GNOME customization, and a standard workspace directory layout.

## Supported system

- Ubuntu (the installer checks `/etc/os-release` and currently accepts Ubuntu only)
- `amd64` architecture
- A user with `sudo` access
- GNOME desktop for the GNOME customization module

The setup installs packages and configures system services, so review the scripts before running them on a machine you rely on.

## Installation

Clone the repository and start the installer:

```bash
git clone https://github.com/sudeeppatgar/ubuntu-workstation-setup.git
cd ubuntu-workstation-setup
./install.sh
```

The installer runs the modules in `scripts/` in sequence. It may request your Git identity, ask whether to create a GitHub SSH key, and prompt for a local Docker development password. Some steps require internet access and sudo. Docker containers are configured but are not started automatically.

After installation, reload Bash and verify the machine:

```bash
source ~/.bashrc
./doctor.sh
```

To run an individual module, execute its script from the repository root, for example `bash scripts/docker.sh`.

## What it configures

- **Base software:** common Ubuntu command-line tools, Google Chrome, Docker Engine and Compose, Node.js LTS, pnpm, and OpenCode.
- **Git:** global identity prompt (only if not already set), defaults, aliases, global ignore rules, and the libsecret credential helper.
- **GitHub and SSH:** optional personal Ed25519 key and a `github-personal` SSH host entry. GitHub CLI login remains an interactive user action (`gh auth login`).
- **Bash:** sources the managed configuration from `shell/` through a marked block in `~/.bashrc`, preserving a backup of the prior file.
- **GNOME:** listed GNOME Shell extensions, keyboard shortcuts, dock and Desktop Cube dconf settings, WhiteSur icons, and wallpapers.
- **Workspaces:** creates `~/Workspace/{Work,Personal,Learning,Archive,Boeing}`.
- **Docker development environment:** creates a private `.env`, configures the daemon, enables Docker, and creates the external `dev-network` network.

## Repository layout

```text
.
├── install.sh          # Main installer and supported-system checks
├── doctor.sh           # Post-install health checks
├── scripts/            # Modular package and workstation setup scripts
├── shell/              # Bash aliases, functions, exports, and prompt
├── git/                # Git configuration and global ignore rules
├── gnome/              # dconf settings, extension list, and wallpapers
├── docker/             # Compose stack, daemon settings, and env template
└── LICENSE             # MIT license
```

## Local Docker services

The optional Compose stack is in `docker/`. Create `docker/.env` with `scripts/docker.sh` or copy `docker/.env.example` and replace its example credentials. Then:

```bash
cd docker
docker compose up -d
docker compose ps
docker compose down
```

The stack includes PostgreSQL, MongoDB, Redis, RabbitMQ, SeaweedFS, and browser interfaces for PostgreSQL, MongoDB, and Redis. Published ports bind to `127.0.0.1`; see [`docker/README.md`](docker/README.md) for addresses and service commands. Named volumes persist data after containers are stopped. `docker compose down -v` removes those volumes and their data.

Keep `docker/.env` private; it is ignored by Git. The Compose network is declared external and is created by `scripts/docker.sh`.

## Health check

`./doctor.sh` reports available tools, Docker access and network state, Git identity, repository configuration files, GNOME extension state, and expected workspace directories. Some items such as GitHub authentication and Docker environment setup are optional until configured.

## License

[MIT](LICENSE) © Sudeep Patgar
