# GitHub Actions Self-Hosted Runner on Docker

Secure GitHub Actions self-hosted runner using Docker on Mac.

## Prerequisites

- Docker Desktop for Mac
- GitHub account with repository access

## Quick Start

### 1. Create GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Click "Generate new token"
3. Set expiration (recommended: 90 days)
4. Select your repository in "Repository access"
5. Under "Repository permissions", grant:
   
   **Essential permissions:**
   - **Actions**: Read and Write (runner communication)
   - **Administration**: Write (runner management)
   - **Contents**: Read (code checkout)
   - **Metadata**: Read (required by GitHub)
   
   **Recommended for CI/CD:**
   - **Commit statuses**: Write (build status badges)
   - **Pull requests**: Read and Write (PR status updates)
   
   **Optional (if needed):**
   - **Issues**: Read and Write (auto-create issues)
   - **Discussions**: Read and Write (if using discussions)
   - **Repository security advisories**: Read (security scanning)
6. Copy the generated token

### 2. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env file
nano .env
```

Set your repository details in `.env`:
```bash
GITHUB_OWNER=your-username
GITHUB_REPOSITORY=your-repo-name
RUNNER_NAME=mac-docker-runner
RUNNER_VERSION=2.325.0

# Optional: Hash validation for security
# RUNNER_HASH=5020da7139d85c776059f351e0de8fdec753affc9c558e892472d43ebeb518f4
```

### 3. Configure Secure Token

**Option A: Using setup-token script (Recommended)**

```bash
./build_runner.sh setup-token
```

**The script will prompt you:**
```
Please enter your GitHub Personal Access Token:
(The token will not be displayed as you type)
```

**Enter the token you copied from Step 1** and press Enter. The token will be securely saved to `.github_token` file.

**Option B: Using GitHub Actions environment variables**

Alternatively, you can set the GitHub Personal Access Token as a repository environment variable named `GH_PAT` in your repository's Actions settings. This method is useful when running the self-hosted runner from within GitHub Actions workflows. The runner will automatically detect and use the `GH_PAT` environment variable with higher priority than the local `.github_token` file.

### 4. Start Runner

```bash
# Start with Docker-in-Docker (recommended)
./build_runner.sh start-dind

# Check logs
./build_runner.sh logs-dind
```

**Running Multiple Runners**

You can run multiple self-hosted runners simultaneously by using different `RUNNER_NAME` values:

```bash
# Start first runner
RUNNER_NAME=runner-1 ./build_runner.sh start-dind

# Start second runner (in same or different terminal)
RUNNER_NAME=runner-2 ./build_runner.sh start-dind

# Check logs for specific runner
./build_runner.sh logs-dind runner-1
./build_runner.sh logs-dind runner-2
```

This enables parallel execution of GitHub Actions jobs, significantly improving CI/CD performance.

### 5. Verify in GitHub

Go to your repository Settings → Actions → Runners to see the connected runner.

## Usage

### Commands

```bash
# Start DinD runner (recommended)
./build_runner.sh start-dind

# Start Sysbox runner (maximum security)
./build_runner.sh start-sysbox

# Stop runners
./build_runner.sh stop

# View logs
./build_runner.sh logs-dind      # DinD logs
./build_runner.sh logs-sysbox    # Sysbox logs

# Check status
./build_runner.sh status

# Setup new token
./build_runner.sh setup-token

# Clean up
./build_runner.sh clean
```

### GitHub Actions Workflow

```yaml
jobs:
  build:
    # Option 1: Simple (works with any self-hosted runner)
    runs-on: self-hosted
    
    # Option 2: Specific labels (only this Docker runner)
    # runs-on: [self-hosted, docker, mac, dind]
    
    steps:
      - uses: actions/checkout@v4
      - name: Run build
        run: |
          npm install
          npm run build
```

**Label Options:**
- `runs-on: self-hosted` - Uses any available self-hosted runner
- `runs-on: [self-hosted, docker, mac, dind]` - Only uses runners with ALL these labels

## Project Structure

The project is organized into two main deployment variants:

```
├── build_runner.sh           # Main runner management script
├── .env.example              # Environment configuration template
├── dind/                     # Docker-in-Docker variant
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── entrypoint.sh
│   └── supervisord.conf
├── sysbox/                   # Sysbox variant
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── entrypoint.sh
├── commands/                 # Command utilities
│   └── setup-secure-token.sh
└── README.md                 # This file
```

### Deployment Options

| Method | Security Level | Docker Support | Host Isolation | Setup Complexity |
|--------|---------------|----------------|----------------|------------------|
| **Docker-in-Docker** | ⚠️ Medium | ✅ Full | ⚠️ Partial | ⚠️ Medium |
| **Sysbox Runtime** | ✅ High | ✅ Full | ✅ Complete | ❌ Complex |

## Security Features

- **🔒 Secure Token Storage**: Tokens stored in protected files
- **🛡️ Container Isolation**: Multiple isolation strategies available
- **📝 Input Validation**: Prevents injection attacks
- **🔄 Minimal Privileges**: Runs with restricted permissions

## Troubleshooting

### Runner Not Visible
1. Check essential token permissions:
   - Actions: Read/Write ✅
   - Administration: Write ✅
   - Contents: Read ✅
   - Metadata: Read ✅
2. Verify repository settings: Settings → Actions → Runners
3. Check logs: `./build_runner.sh logs-dind`
4. Ensure token hasn't expired (Fine-grained tokens have shorter expiration)

### Common Issues
```bash
# Recreate token
./build_runner.sh setup-token

# Restart runner
./build_runner.sh stop
./build_runner.sh start-dind

# Clean restart
./build_runner.sh clean
./build_runner.sh start-dind
```

## Requirements

- Docker Desktop: 4GB+ RAM, 2+ CPU cores
- GitHub fine-grained token with Actions and Administration permissions
- macOS with Docker Desktop installed

## Security Notes

- Never commit `.env` or `.github_token` files
- Use private repositories only
- Rotate tokens regularly
- Monitor runner activity in GitHub Settings

## Development

This project was developed using [Claude Code](https://claude.ai/code), Anthropic's official CLI for Claude.