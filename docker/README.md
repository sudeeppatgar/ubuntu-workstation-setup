# Docker Development Environment

This directory contains optional local development services managed with Docker Compose.

## Start

From this directory:

    cd /path/to/ubuntu-workstation-setup/docker
    docker compose up -d

## Stop

    cd /path/to/ubuntu-workstation-setup/docker
    docker compose down

## Status

    cd /path/to/ubuntu-workstation-setup/docker
    docker compose ps

## Logs

Follow all service logs:

    cd /path/to/ubuntu-workstation-setup/docker
    docker compose logs -f

Follow a specific service:

    docker compose logs -f postgres
    docker compose logs -f mongodb
    docker compose logs -f redis
    docker compose logs -f rabbitmq
    docker compose logs -f seaweedfs
    docker compose logs -f mongo-express
    docker compose logs -f redisinsight
    docker compose logs -f pgadmin

## Services

| Service | Address |
|---|---|
| PostgreSQL | `localhost:5432` |
| MongoDB | `localhost:27017` |
| Redis | `localhost:6379` |
| RabbitMQ | `localhost:5672` |
| RabbitMQ Management | `http://localhost:15672` |
| SeaweedFS S3 API | `http://localhost:8333` |
| SeaweedFS filer | `http://localhost:8888` |
| Mongo Express | `http://localhost:8081` |
| RedisInsight | `http://localhost:5540` |
| pgAdmin | `http://localhost:5050` |

## Environment

The actual environment file is:

    docker/.env

It contains local credentials and secrets and is intentionally excluded from Git.

The environment file is created interactively when `scripts/docker.sh` is run. You can also copy `.env.example` to `.env` and replace the example credentials before starting the services.

Do not commit `docker/.env`.

## Volumes

Docker Compose uses named volumes so service data persists when containers are stopped or recreated.

The services use:

    restart: no

Containers therefore do not automatically restart after a reboot.

Start the development environment when needed:

    cd /path/to/ubuntu-workstation-setup/docker
    docker compose up -d

Stop it when finished:

    cd /path/to/ubuntu-workstation-setup/docker
    docker compose down
