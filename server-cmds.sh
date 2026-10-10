#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="${1:?Image name is required}"

cd /home/ec2-user

export IMAGE="$IMAGE_NAME"

echo "Pulling Docker images..."
docker compose -f docker-compose.yaml pull

echo "Starting application..."
docker compose -f docker-compose.yaml up --detach

echo "Deployment status:"
docker compose -f docker-compose.yaml ps

echo "Deployment successful."