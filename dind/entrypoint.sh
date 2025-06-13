#!/bin/bash
set -e

# Check required environment variables
if [[ -z "$GITHUB_OWNER" ]]; then
    echo "Error: GITHUB_OWNER environment variable is not set"
    exit 1
fi

if [[ -z "$GITHUB_REPOSITORY" ]]; then
    echo "Error: GITHUB_REPOSITORY environment variable is not set"
    exit 1
fi

# Token will be read from file for security
if [[ -z "$GITHUB_TOKEN_FILE" ]]; then
    echo "Error: GITHUB_TOKEN_FILE environment variable is not set"
    exit 1
fi

if [[ ! -f "$GITHUB_TOKEN_FILE" ]]; then
    echo "Error: Token file not found at $GITHUB_TOKEN_FILE"
    exit 1
fi

# Read token from file
GITHUB_TOKEN=$(cat "$GITHUB_TOKEN_FILE")

# Set runner name (default is hostname)
RUNNER_NAME=${RUNNER_NAME:-$(hostname)}
RUNNER_WORKDIR=${RUNNER_WORKDIR:-"_work"}
RUNNER_LABELS=${RUNNER_LABELS:-"docker,self-hosted,mac,dind"}

cd /home/runner

# Clean up existing configuration
if [[ -f ".runner" ]]; then
    echo "Removing existing runner configuration..."
    # Use token from file, not as command argument
    ./config.sh remove --token "$(cat "$GITHUB_TOKEN_FILE")" || true
fi

# Configure runner
echo "Configuring GitHub Actions Runner..."
./config.sh --unattended \
    --url "https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}" \
    --token "$(cat "$GITHUB_TOKEN_FILE")" \
    --name "${RUNNER_NAME}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --replace

# Clear token from memory
unset GITHUB_TOKEN

# Start supervisor as root to manage dockerd and runner
exec sudo /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf