#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

# =========================================================
# Wait for Internet / NAT Gateway
# =========================================================

until curl -4 -fsS https://ifconfig.me >/dev/null 2>&1; do
  echo "Waiting for Internet connection..."
  sleep 10
done

# =========================================================
# Update packages
# =========================================================

apt-get update

# =========================================================
# Install required packages
# =========================================================

apt-get install -y \
  ansible \
  git \
  curl \
  unzip \
  python3

# =========================================================
# Install AWS CLI v2
# =========================================================

if ! command -v aws >/dev/null 2>&1; then
  curl -fsSL https://awscli.amazonaws.com/v2/install.sh | bash -s -- --system
fi

# =========================================================
# Install Session Manager Plugin
# =========================================================

if ! command -v session-manager-plugin >/dev/null 2>&1; then

  curl -fsSL \
    "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" \
    -o /tmp/session-manager-plugin.deb

  dpkg -i /tmp/session-manager-plugin.deb

  rm -f /tmp/session-manager-plugin.deb

fi

# =========================================================
# Install Ansible AWS Collection
# =========================================================

sudo -u ubuntu ansible-galaxy collection install amazon.aws

# =========================================================
# Clone GitHub Repository
# =========================================================

REPO_DIR="/home/ubuntu/devops-bootcamp-project"

if [ ! -d "$REPO_DIR/.git" ]; then

  git clone \
    "https://github.com/fareezizzudinothman/devops-bootcamp-project.git" \
    "$REPO_DIR"

fi

# =========================================================
# Set ownership
# =========================================================

chown -R ubuntu:ubuntu "$REPO_DIR"

# =========================================================
# Create bootstrap log
# =========================================================

cat > /home/ubuntu/node2-bootstrap.txt <<EOF
Node2 bootstrap completed.

AWS CLI:
$(aws --version)

Ansible:
$(ansible --version | head -n 1)

Git:
$(git --version)

Python:
$(python3 --version)

Repository:
$REPO_DIR

Completed:
$(date)
EOF

chown ubuntu:ubuntu /home/ubuntu/node2-bootstrap.txt

echo "Node2 bootstrap completed successfully."