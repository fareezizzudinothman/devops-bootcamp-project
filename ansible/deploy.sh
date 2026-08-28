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
# Run Ansible deployment
# ---------------------------------------------------------

cd "$REPO_DIR/ansible"

echo "Running Ansible deployment..."

ansible-playbook \
  playbooks/playbooks-nginx-deploy.yaml \
  -e "image_tag=$IMAGE_TAG"

echo "========================================"
echo "Deployment completed"
echo "Image: $IMAGE_TAG"
echo "========================================"