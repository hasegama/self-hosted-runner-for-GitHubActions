#!/bin/bash

# Color output settings
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up secure token storage...${NC}"

# Create token file with restricted permissions
TOKEN_FILE=".github_token"

# Check if token file already exists
if [ -f "$TOKEN_FILE" ]; then
    echo -e "${YELLOW}Token file already exists. Do you want to replace it? (y/N): ${NC}"
    read -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing token file."
        exit 0
    fi
fi

# Prompt for token
echo -e "${GREEN}Please enter your GitHub Personal Access Token:${NC}"
echo "(The token will not be displayed as you type)"
read -s GITHUB_TOKEN

# Validate token is not empty
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}Error: Token cannot be empty${NC}"
    exit 1
fi

# Create token file with restricted permissions
echo "$GITHUB_TOKEN" > "$TOKEN_FILE"
chmod 600 "$TOKEN_FILE"

echo -e "${GREEN}Token saved securely to $TOKEN_FILE${NC}"
echo -e "${YELLOW}Important security notes:${NC}"
echo "- The token file has restricted permissions (600)"
echo "- Add $TOKEN_FILE to .gitignore (already included)"
echo "- Never commit this file to version control"
echo "- Delete this file when no longer needed"

# Clear token from memory
unset GITHUB_TOKEN