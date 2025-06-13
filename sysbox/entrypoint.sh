#!/bin/bash
set -euo pipefail

# Secure token handling function
read_token_securely() {
    local token_source=$1
    local token=""
    
    # Try multiple token sources in order of preference
    if [[ -n "${GITHUB_TOKEN_FILE:-}" ]] && [[ -f "$GITHUB_TOKEN_FILE" ]]; then
        # Best: Read from file
        token=$(cat "$GITHUB_TOKEN_FILE")
    elif [[ -n "${GITHUB_TOKEN_COMMAND:-}" ]]; then
        # Good: Execute command to get token (e.g., from secret manager)
        token=$(eval "$GITHUB_TOKEN_COMMAND")
    elif [[ -n "${GITHUB_TOKEN:-}" ]]; then
        # Fallback: Environment variable (less secure)
        echo "Warning: Using token from environment variable. Consider using GITHUB_TOKEN_FILE instead." >&2
        token="$GITHUB_TOKEN"
    else
        echo "Error: No token source configured. Set GITHUB_TOKEN_FILE, GITHUB_TOKEN_COMMAND, or GITHUB_TOKEN" >&2
        exit 1
    fi
    
    # Validate token format (basic check)
    if [[ ! "$token" =~ ^gh[ps]_[a-zA-Z0-9]{36,}$ ]]; then
        echo "Error: Invalid token format" >&2
        exit 1
    fi
    
    echo "$token"
}

# Check required environment variables
if [[ -z "${GITHUB_OWNER:-}" ]]; then
    echo "Error: GITHUB_OWNER environment variable is not set"
    exit 1
fi

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
    echo "Error: GITHUB_REPOSITORY environment variable is not set"
    exit 1
fi

# Validate input to prevent injection
if [[ ! "$GITHUB_OWNER" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "Error: Invalid GITHUB_OWNER format"
    exit 1
fi

if [[ ! "$GITHUB_REPOSITORY" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "Error: Invalid GITHUB_REPOSITORY format"
    exit 1
fi

# Set runner name (default is hostname)
RUNNER_NAME=${RUNNER_NAME:-$(hostname)}
RUNNER_WORKDIR=${RUNNER_WORKDIR:-"_work"}
RUNNER_LABELS=${RUNNER_LABELS:-"docker,self-hosted,mac"}

# Validate runner name
if [[ ! "$RUNNER_NAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "Error: Invalid RUNNER_NAME format"
    exit 1
fi

cd /home/runner

# Get PAT securely
GITHUB_PAT=$(read_token_securely)

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
    ./config.sh remove --token "$REMOVE_TOKEN" 2>/dev/null || true
fi

# Configure runner
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

# Clear any token variables from memory
unset GITHUB_TOKEN GITHUB_TOKEN_FILE GITHUB_TOKEN_COMMAND

# Execute runner
echo "Starting GitHub Actions Runner..."
exec ./run.sh