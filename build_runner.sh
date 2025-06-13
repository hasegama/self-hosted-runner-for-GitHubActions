#!/bin/bash

# Color output settings
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Check .env file existence
check_env() {
    if [ ! -f .env ]; then
        echo -e "${RED}Error: .env file not found${NC}"
        echo "1. Copy .env.example to create .env:"
        echo "   cp .env.example .env"
        echo "2. Edit .env file and enter required information"
        exit 1
    fi
}

# Check token file existence
check_token() {
    if [ ! -f .github_token ]; then
        echo -e "${RED}Error: Token file not found${NC}"
        echo "Run ./commands/setup-secure-token.sh to create secure token file"
        exit 1
    fi
}

# Check Docker daemon
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        echo "Please start Docker Desktop and try again"
        exit 1
    fi
}

# Execute docker compose with error checking
run_docker_compose() {
    local compose_file=$1
    local action_name=$2
    
    if docker compose -f "$compose_file" --env-file .env up -d --build; then
        echo -e "${GREEN}$action_name started successfully!${NC}"
        
        # Show appropriate log command based on compose file
        case "$compose_file" in
            *"dind"*)
                echo "To check logs: ./build_runner.sh logs-dind"
                ;;
            *"sysbox"*)
                echo "To check logs: ./build_runner.sh logs-sysbox"
                ;;
        esac
        return 0
    else
        echo -e "${RED}Failed to start $action_name${NC}"
        echo "Check the error messages above for details"
        return 1
    fi
}

# Process commands
case "$1" in
    start-dind)
        check_env
        check_token
        check_docker
        echo -e "${GREEN}Starting GitHub Actions Runner with Docker-in-Docker...${NC}"
        run_docker_compose "dind/docker-compose.yml" "GitHub Actions Runner (Docker-in-Docker)"
        ;;
    
    start-sysbox)
        check_env
        check_token
        check_docker
        echo -e "${GREEN}Starting GitHub Actions Runner with Sysbox...${NC}"
        run_docker_compose "sysbox/docker-compose.yml" "GitHub Actions Runner (Sysbox)"
        ;;
    
    stop)
        echo -e "${YELLOW}Stopping GitHub Actions Runner...${NC}"
        docker compose -f dind/docker-compose.yml --env-file .env down 2>/dev/null || true
        docker compose -f sysbox/docker-compose.yml --env-file .env down 2>/dev/null || true
        echo -e "${GREEN}Stopped successfully!${NC}"
        ;;
    
    logs-dind)
        echo -e "${GREEN}Showing DinD logs (Ctrl+C to exit)${NC}"
        docker compose -f dind/docker-compose.yml --env-file .env logs -f
        ;;
    
    logs-sysbox)
        echo -e "${GREEN}Showing Sysbox logs (Ctrl+C to exit)${NC}"
        docker compose -f sysbox/docker-compose.yml --env-file .env logs -f
        ;;
    
    setup-token)
        echo -e "${GREEN}Setting up secure token...${NC}"
        ./commands/setup-secure-token.sh
        ;;
    
    status)
        echo -e "${GREEN}Checking status...${NC}"
        docker compose -f dind/docker-compose.yml --env-file .env ps 2>/dev/null || true
        docker compose -f sysbox/docker-compose.yml --env-file .env ps 2>/dev/null || true
        ;;
    
    clean)
        echo -e "${RED}Warning: This operation will delete all data!${NC}"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker compose -f dind/docker-compose.yml --env-file .env down -v 2>/dev/null || true
            docker compose -f sysbox/docker-compose.yml --env-file .env down -v 2>/dev/null || true
            echo -e "${GREEN}Cleanup completed!${NC}"
        else
            echo "Cancelled"
        fi
        ;;
    
    *)
        echo "Usage: $0 {start-dind|start-sysbox|stop|logs-dind|logs-sysbox|setup-token|status|clean}"
        echo ""
        echo "Commands:"
        echo "  start-dind   - Start with Docker-in-Docker (standard secure mode)"
        echo "  start-sysbox - Start with Sysbox runtime (maximum security)"
        echo "  stop         - Stop all GitHub Actions Runners"
        echo "  logs-dind    - Show DinD logs (real-time)"
        echo "  logs-sysbox  - Show Sysbox logs (real-time)"
        echo "  setup-token  - Setup secure token file"
        echo "  status       - Check current status"
        echo "  clean        - Delete all data and cleanup"
        exit 1
        ;;
esac