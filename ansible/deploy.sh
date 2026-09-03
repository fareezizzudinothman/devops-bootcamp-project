#!/bin/bash

set -e

IMAGE_TAG="$1"

if [ -z "$IMAGE_TAG" ]; then
  echo "ERROR: image tag is required"
  echo "Usage: ./deploy.sh <image-tag>"
  exit 1
fi

REPO_DIR="/home/ubuntu/devops-bootcamp-project"

echo "========================================"
echo "Starting deployment"
echo "Image tag: $IMAGE_TAG"
echo "========================================"

# ---------------------------------------------------------
# Configure Git safe directory
# ---------------------------------------------------------

git config --global --add safe.directory "$REPO_DIR"

# ---------------------------------------------------------
# Update repository
# ---------------------------------------------------------

cd "$REPO_DIR"

echo "Pulling latest repository..."

git pull origin main

# ---------------------------------------------------------
# Install Ansible Galaxy dependencies
# ---------------------------------------------------------

cd "$REPO_DIR/ansible"

echo "Installing Ansible Galaxy dependencies..."

ansible-galaxy install -r requirements.yml

# ---------------------------------------------------------
# Run Ansible deployment
# ---------------------------------------------------------

echo "Running Ansible deployment..."

ansible-playbook \
  playbooks/playbooks-nginx-deploy.yaml \
  -e "image_tag=$IMAGE_TAG"


# ---------------------------------------------------------
# Deploy Node Exporter 3 node
# ---------------------------------------------------------

echo "Running Node Exporter deployment..."

ansible-playbook \
  playbooks/playbooks-node-exporter.yaml

# ---------------------------------------------------------
# Deploy prometheus dan grafana node3
# ---------------------------------------------------------

echo "Running prometheus dan grafana deployment..."

ansible-playbook \
  playbooks/playbooks-monitoring.yaml

# ---------------------------------------------------------
# Deploy Cloudflared node3
# ---------------------------------------------------------

echo "Running Cloudflared deployment..."

ansible-playbook \
  playbooks/playbooks-cloudflare.yaml

echo "========================================"
echo "Deployment completed"
echo "Image: $IMAGE_TAG"
echo "========================================"