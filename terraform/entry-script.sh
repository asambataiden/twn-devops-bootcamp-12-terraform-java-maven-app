#!/bin/bash
set -euxo pipefail

COMPOSE_VERSION="v5.6.0"
COMPOSE_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

yum update -y
yum install -y docker curl

systemctl enable --now docker
usermod -aG docker ec2-user

mkdir -p "${COMPOSE_PLUGIN_DIR}"

curl -fsSL \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o "${COMPOSE_PLUGIN_DIR}/docker-compose"

chmod +x "${COMPOSE_PLUGIN_DIR}/docker-compose"

docker --version
docker compose version