#!/bin/bash
set -euxo pipefail

COMPOSE_VERSION="v5.6.0"
COMPOSE_PLUGIN_DIR="/usr/local/lib/docker/cli-plugins"

yum update -y

# Install Docker only.
# Amazon Linux 2023 already provides curl via curl-minimal.
yum install -y docker

systemctl enable --now docker
usermod -aG docker ec2-user

# Verify curl is already available
curl --version

# Install Docker Compose as Docker CLI plugin
mkdir -p "${COMPOSE_PLUGIN_DIR}"

curl -fsSL \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o "${COMPOSE_PLUGIN_DIR}/docker-compose"

chmod +x "${COMPOSE_PLUGIN_DIR}/docker-compose"

# Verify installation
docker --version
docker compose version