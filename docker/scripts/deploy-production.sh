#!/bin/bash
# ===========================================
# ThaliumX Production Deployment Script
# ===========================================
# This script automates the complete production deployment
# including TLS setup, Vault initialization, and service startup
#
# Usage:
#   ./deploy-production.sh [full|tls|vault|keycloak|backup|status]
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="${SCRIPT_DIR}/.."
SECURITY_DIR="${DOCKER_DIR}/security"
ENV_FILE="${DOCKER_DIR}/.env"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Load environment
if [ -f "${ENV_FILE}" ]; then
    set -a
    source "${ENV_FILE}"
    set +a
fi

show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║           ThaliumX Production Deployment                  ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  full      - Complete production deployment (recommended)"
    echo "  tls       - Generate TLS certificates only"
    echo "  vault     - Initialize Vault only"
    echo "  keycloak  - Build optimized Keycloak image only"
    echo "  backup    - Set up automated backups only"
    echo "  status    - Show deployment status"
    echo "  help      - Show this help message"
    echo ""
    echo "Full deployment order:"
    echo "  1. Generate TLS certificates"
    echo "  2. Build optimized Keycloak image"
    echo "  3. Start infrastructure services"
    echo "  4. Initialize and unseal Vault"
    echo "  5. Configure Vault secrets"
    echo "  6. Start application services"
    echo "  7. Set up automated backups"
}

check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    local missing=0
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker not found${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ Docker installed${NC}"
    fi
    
    # Check Docker Compose
    if ! docker compose version &> /dev/null; then
        echo -e "${RED}✗ Docker Compose not found${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ Docker Compose installed${NC}"
    fi
    
    # Check OpenSSL
    if ! command -v openssl &> /dev/null; then
        echo -e "${RED}✗ OpenSSL not found${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ OpenSSL installed${NC}"
    fi
    
    # Check jq
    if ! command -v jq &> /dev/null; then
        echo -e "${YELLOW}⚠ jq not found (optional but recommended)${NC}"
    else
        echo -e "${GREEN}✓ jq installed${NC}"
    fi
    
    # Check .env file
    if [ ! -f "${ENV_FILE}" ]; then
        echo -e "${YELLOW}⚠ .env file not found, using defaults${NC}"
    else
        echo -e "${GREEN}✓ .env file found${NC}"
    fi
    
    if [ ${missing} -eq 1 ]; then
        echo ""
        echo -e "${RED}Missing prerequisites. Please install required tools.${NC}"
        exit 1
    fi
    
    echo ""
}

setup_tls() {
    echo -e "${BLUE}=== Setting up TLS Certificates ===${NC}"
    echo ""
    
    TLS_SCRIPT="${SECURITY_DIR}/scripts/setup-production-tls.sh"
    
    if [ ! -f "${TLS_SCRIPT}" ]; then
        echo -e "${RED}TLS setup script not found: ${TLS_SCRIPT}${NC}"
        exit 1
    fi
    
    chmod +x "${TLS_SCRIPT}"
    "${TLS_SCRIPT}"
    
    echo -e "${GREEN}✓ TLS certificates generated${NC}"
    echo ""
}

build_keycloak() {
    echo -e "${BLUE}=== Building Optimized Keycloak Image ===${NC}"
    echo ""
    
    DOCKERFILE="${SECURITY_DIR}/Dockerfile.keycloak"
    
    if [ ! -f "${DOCKERFILE}" ]; then
        echo -e "${RED}Keycloak Dockerfile not found: ${DOCKERFILE}${NC}"
        exit 1
    fi
    
    echo "Building thaliumx/keycloak:24.0-optimized..."
    docker build \
        -f "${DOCKERFILE}" \
        -t thaliumx/keycloak:24.0-optimized \
        "${SECURITY_DIR}"
    
    echo -e "${GREEN}✓ Keycloak image built${NC}"
    echo ""
}

create_network() {
    echo -e "${BLUE}=== Creating Docker Network ===${NC}"
    echo ""
    
    if docker network inspect thaliumx-net &> /dev/null; then
        echo -e "${GREEN}✓ Network thaliumx-net already exists${NC}"
    else
        docker network create thaliumx-net
        echo -e "${GREEN}✓ Network thaliumx-net created${NC}"
    fi
    echo ""
}

start_infrastructure() {
    echo -e "${BLUE}=== Starting Infrastructure Services ===${NC}"
    echo ""
    
    cd "${DOCKER_DIR}"
    
    # Start databases first
    echo "Starting databases..."
    docker compose -f databases/compose.yaml up -d
    
    # Wait for PostgreSQL
    echo "Waiting for PostgreSQL to be ready..."
    for i in {1..30}; do
        if docker exec thaliumx-postgres pg_isready -U ${POSTGRES_USER:-thaliumx} &> /dev/null; then
            echo -e "${GREEN}✓ PostgreSQL ready${NC}"
            break
        fi
        sleep 2
    done
    
    echo ""
}

initialize_vault() {
    echo -e "${BLUE}=== Initializing Vault ===${NC}"
    echo ""
    
    # Start Vault with production config
    cd "${DOCKER_DIR}"
    docker compose -f security/compose.production.yaml up -d vault
    
    # Wait for Vault to start
    echo "Waiting for Vault to start..."
    sleep 10
    
    VAULT_INIT_SCRIPT="${SECURITY_DIR}/scripts/vault-production-init.sh"
    
    if [ -f "${VAULT_INIT_SCRIPT}" ]; then
        chmod +x "${VAULT_INIT_SCRIPT}"
        "${VAULT_INIT_SCRIPT}"
    else
        echo -e "${YELLOW}Vault init script not found, manual initialization required${NC}"
    fi
    
    echo ""
}

start_security_services() {
    echo -e "${BLUE}=== Starting Security Services ===${NC}"
    echo ""
    
    cd "${DOCKER_DIR}"
    docker compose -f security/compose.production.yaml up -d
    
    # Wait for Keycloak
    echo "Waiting for Keycloak to be ready..."
    for i in {1..60}; do
        if curl -sk https://localhost:8443/health/ready 2>/dev/null | grep -q "UP"; then
            echo -e "${GREEN}✓ Keycloak ready${NC}"
            break
        fi
        sleep 5
    done
    
    echo ""
}

start_all_services() {
    echo -e "${BLUE}=== Starting All Services ===${NC}"
    echo ""
    
    cd "${DOCKER_DIR}"
    
    # Start remaining services
    for compose_file in apisix/compose.yaml trading/compose.yaml fintech/compose.yaml observability/compose.yaml; do
        if [ -f "${compose_file}" ]; then
            echo "Starting ${compose_file}..."
            docker compose -f "${compose_file}" up -d
        fi
    done
    
    echo -e "${GREEN}✓ All services started${NC}"
    echo ""
}

setup_backups() {
    echo -e "${BLUE}=== Setting Up Automated Backups ===${NC}"
    echo ""
    
    BACKUP_SCRIPT="${SCRIPT_DIR}/setup-backup-cron.sh"
    
    if [ -f "${BACKUP_SCRIPT}" ]; then
        chmod +x "${BACKUP_SCRIPT}"
        "${BACKUP_SCRIPT}" install
    else
        echo -e "${YELLOW}Backup setup script not found${NC}"
    fi
    
    echo ""
}

show_status() {
    echo -e "${BLUE}=== ThaliumX Deployment Status ===${NC}"
    echo ""
    
    # Check containers
    echo "Running Containers:"
    docker ps --filter "name=thaliumx" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
    
    echo ""
    
    # Count healthy/unhealthy
    TOTAL=$(docker ps --filter "name=thaliumx" -q | wc -l)
    HEALTHY=$(docker ps --filter "name=thaliumx" --filter "health=healthy" -q | wc -l)
    
    echo "Summary:"
    echo "  Total Containers: ${TOTAL}"
    echo "  Healthy: ${HEALTHY}"
    echo "  Unhealthy: $((TOTAL - HEALTHY))"
    
    echo ""
    
    # Check TLS certificates
    echo "TLS Certificates:"
    VAULT_CERT="${SECURITY_DIR}/config/vault/tls/vault.crt"
    if [ -f "${VAULT_CERT}" ]; then
        EXPIRY=$(openssl x509 -enddate -noout -in "${VAULT_CERT}" 2>/dev/null | cut -d= -f2)
        echo "  Vault Certificate Expires: ${EXPIRY}"
    else
        echo -e "  ${YELLOW}Vault certificate not found${NC}"
    fi
    
    KEYCLOAK_CERT="${SECURITY_DIR}/config/keycloak/tls/tls.crt"
    if [ -f "${KEYCLOAK_CERT}" ]; then
        EXPIRY=$(openssl x509 -enddate -noout -in "${KEYCLOAK_CERT}" 2>/dev/null | cut -d= -f2)
        echo "  Keycloak Certificate Expires: ${EXPIRY}"
    else
        echo -e "  ${YELLOW}Keycloak certificate not found${NC}"
    fi
    
    echo ""
    
    # Check Vault status
    echo "Vault Status:"
    if docker ps --filter "name=thaliumx-vault" -q | grep -q .; then
        VAULT_STATUS=$(docker exec thaliumx-vault vault status -format=json 2>/dev/null || echo '{"sealed": "unknown"}')
        SEALED=$(echo "${VAULT_STATUS}" | jq -r '.sealed' 2>/dev/null || echo "unknown")
        if [ "${SEALED}" == "false" ]; then
            echo -e "  ${GREEN}Unsealed${NC}"
        elif [ "${SEALED}" == "true" ]; then
            echo -e "  ${RED}Sealed${NC}"
        else
            echo -e "  ${YELLOW}Unknown${NC}"
        fi
    else
        echo -e "  ${YELLOW}Not running${NC}"
    fi
    
    echo ""
    
    # Check backups
    echo "Backup Status:"
    if crontab -l 2>/dev/null | grep -q "backup-cron-wrapper.sh"; then
        echo -e "  Automated Backups: ${GREEN}Enabled${NC}"
        BACKUP_DIR="${BACKUP_DIR:-/opt/thaliumx/backups}"
        if [ -d "${BACKUP_DIR}" ]; then
            BACKUP_COUNT=$(find "${BACKUP_DIR}" -name "thaliumx_backup_*.tar.gz" 2>/dev/null | wc -l)
            echo "  Backup Count: ${BACKUP_COUNT}"
        fi
    else
        echo -e "  Automated Backups: ${YELLOW}Not configured${NC}"
    fi
}

full_deployment() {
    show_banner
    check_prerequisites
    
    echo -e "${CYAN}Starting full production deployment...${NC}"
    echo ""
    
    # Step 1: TLS
    setup_tls
    
    # Step 2: Keycloak build
    build_keycloak
    
    # Step 3: Network
    create_network
    
    # Step 4: Infrastructure
    start_infrastructure
    
    # Step 5: Vault
    initialize_vault
    
    # Step 6: Security services
    start_security_services
    
    # Step 7: All services
    start_all_services
    
    # Step 8: Backups
    setup_backups
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Production Deployment Complete!                   ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    show_status
}

# Main
case "${1:-}" in
    full)
        full_deployment
        ;;
    tls)
        show_banner
        setup_tls
        ;;
    vault)
        show_banner
        initialize_vault
        ;;
    keycloak)
        show_banner
        build_keycloak
        ;;
    backup)
        show_banner
        setup_backups
        ;;
    status)
        show_banner
        show_status
        ;;
    help|--help|-h)
        show_banner
        show_usage
        ;;
    *)
        show_banner
        show_usage
        exit 1
        ;;
esac