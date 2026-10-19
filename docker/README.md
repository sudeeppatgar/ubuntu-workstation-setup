# Docker Development Environment

This directory contains the local development services used by the workstation.

## Start

From this directory:

    cd ~/dotfiles/docker
    docker compose up -d

## Stop

    cd ~/dotfiles/docker
    docker compose down

## Status

    cd ~/dotfiles/docker
    docker compose ps

## Logs

Follow all service logs:

    cd ~/dotfiles/docker
    docker compose logs -f

Follow a specific service:

    docker compose logs -f postgres
    docker compose logs -f mongodb
    docker compose logs -f redis
    docker compose logs -f rabbitmq
    docker compose logs -f minio
    docker compose logs -f meilisearch

## Services

| Service | Address |
|---|---|
| PostgreSQL | `localhost:5432` |
| MongoDB | `localhost:27017` |
| Redis | `localhost:6379` |
| RabbitMQ | `localhost:5672` |
| RabbitMQ Management | `http://localhost:15672` |
| MinIO API | `http://localhost:9000` |
| MinIO Console | `http://localhost:9001` |
| Meilisearch | `http://localhost:7700` |

## Environment

The actual environment file is:

    docker/.env

It contains local credentials and secrets and is intentionally excluded from Git.

A new machine gets its environment file automatically when `scripts/docker.sh` is run.

Do not commit `docker/.env`.

## Volumes

Docker Compose uses named volumes so service data persists when containers are stopped or recreated.

The services use:

    restart: no

Containers therefore do not automatically restart after a reboot.

Start the development environment when needed:

    cd ~/dotfiles/docker
    docker compose up -d

Stop it when finished:

    cd ~/dotfiles/docker
    docker compose down
