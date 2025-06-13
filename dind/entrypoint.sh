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

# Read PAT with priority: GH_PAT env var > .github_token file > GITHUB_TOKEN_FILE
if [[ -n "${GH_PAT:-}" ]]; then
    echo "Using GitHub token from GH_PAT environment variable"
    GITHUB_PAT="$GH_PAT"
elif [[ -f "/home/runner/.github_token" ]]; then
    echo "Using GitHub token from .github_token file"
    GITHUB_PAT=$(cat "/home/runner/.github_token")
elif [[ -n "${GITHUB_TOKEN_FILE:-}" ]] && [[ -f "$GITHUB_TOKEN_FILE" ]]; then
    echo "Using GitHub token from $GITHUB_TOKEN_FILE"
    GITHUB_PAT=$(cat "$GITHUB_TOKEN_FILE")
else
    echo "Error: No GitHub token found. Set GH_PAT environment variable or create .github_token file"
    exit 1
fi

# Set runner name (default is hostname)
RUNNER_NAME=${RUNNER_NAME:-$(hostname)}
RUNNER_WORKDIR=${RUNNER_WORKDIR:-"_work"}
RUNNER_LABELS=${RUNNER_LABELS:-"docker,self-hosted,mac,dind"}

cd /home/runner

# Get registration token from GitHub API
echo "Getting registration token from GitHub API..."
REG_TOKEN=$(curl -s -X POST \
    -H "Authorization: token $GITHUB_PAT" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/registration-token" \
    | jq -r '.token')

if [[ -z "$REG_TOKEN" ]] || [[ "$REG_TOKEN" == "null" ]]; then
    echo "Error: Failed to get registration token"
    echo "Check your PAT permissions and repository settings"
    exit 1
fi

# Clean up existing configuration
if [[ -f ".runner" ]]; then
    echo "Removing existing runner configuration..."
    # Get removal token
    REMOVE_TOKEN=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_PAT" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPOSITORY}/actions/runners/remove-token" \
        | jq -r '.token')
    ./config.sh remove --token "$REMOVE_TOKEN" || true
fi

# Configure runner with registration token
echo "Configuring GitHub Actions Runner..."
./config.sh --unattended \
    --url "https://github.com/${GITHUB_OWNER}/${GITHUB_REPOSITORY}" \
    --token "$REG_TOKEN" \
    --name "${RUNNER_NAME}" \
    --work "${RUNNER_WORKDIR}" \
    --labels "${RUNNER_LABELS}" \
    --replace

# Clear tokens from memory
unset GITHUB_PAT REG_TOKEN REMOVE_TOKEN

# Start runner directly (supervisord should already be running)
echo "Starting GitHub Actions Runner..."
exec ./run.sh