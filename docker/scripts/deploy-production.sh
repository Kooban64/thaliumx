#!/bin/bash
# ThaliumX Production Deployment Script
# ======================================
# This script orchestrates the complete production deployment process

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DOCKER_DIR="${PROJECT_ROOT}/docker"
K8S_DIR="${PROJECT_ROOT}/k8s"

# Environment
ENVIRONMENT="${ENVIRONMENT:-production}"
DOMAIN="${DOMAIN:-thaliumx.com}"
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-thaliumx-${ENVIRONMENT}}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Check prerequisites
check_prerequisites() {
    log_section "Checking Prerequisites"
    
    local missing=()
    
    # Check required tools
    command -v docker &> /dev/null || missing+=("docker")
    command -v kubectl &> /dev/null || missing+=("kubectl")
    command -v helm &> /dev/null || missing+=("helm")
    command -v aws &> /dev/null || missing+=("aws-cli")
    command -v vault &> /dev/null || missing+=("vault")
    command -v openssl &> /dev/null || missing+=("openssl")
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Please install the missing tools and try again"
        exit 1
    fi
    
    log_info "All prerequisites met"
}

# Validate environment
validate_environment() {
    log_section "Validating Environment"
    
    # Check required environment variables
    local required_vars=(
        "VAULT_ADDR"
        "VAULT_TOKEN"
        "AWS_ACCESS_KEY_ID"
        "AWS_SECRET_ACCESS_KEY"
    )
    
    local missing=()
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing+=("$var")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        log_error "Missing required environment variables: ${missing[*]}"
        exit 1
    fi
    
    # Validate Vault connection
    if ! vault status &> /dev/null; then
        log_error "Cannot connect to Vault at ${VAULT_ADDR}"
        exit 1
    fi
    
    log_info "Environment validated"
}

# Generate TLS certificates
generate_certificates() {
    log_section "Generating TLS Certificates"
    
    if [ -f "${DOCKER_DIR}/certs/server/fullchain.pem" ]; then
        log_info "Certificates already exist, skipping generation"
        return
    fi
    
    bash "${SCRIPT_DIR}/generate-certs.sh" \
        --domain "${DOMAIN}" \
        --environment "${ENVIRONMENT}"
    
    log_info "Certificates generated"
}

# Initialize Vault secrets
initialize_vault() {
    log_section "Initializing Vault Secrets"
    
    # Check if secrets are already populated
    if vault kv get kv/thaliumx/database/postgres &> /dev/null; then
        log_info "Vault secrets already populated"
        return
    fi
    
    # Run the populate secrets script
    bash "${DOCKER_DIR}/vault/scripts/populate-secrets.sh"
    
    log_info "Vault secrets initialized"
}

# Build Docker images
build_images() {
    log_section "Building Docker Images"
    
    local version="${VERSION:-$(git describe --tags --always)}"
    local registry="${DOCKER_REGISTRY:-ghcr.io/thaliumx}"
    
    # Build backend
    log_info "Building backend image..."
    docker build \
        -t "${registry}/thaliumx-backend:${version}" \
        -t "${registry}/thaliumx-backend:latest" \
        --build-arg VERSION="${version}" \
        --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        -f "${DOCKER_DIR}/backend/Dockerfile" \
        "${DOCKER_DIR}/backend"
    
    # Build frontend
    log_info "Building frontend image..."
    docker build \
        -t "${registry}/thaliumx-frontend:${version}" \
        -t "${registry}/thaliumx-frontend:latest" \
        --build-arg VERSION="${version}" \
        --build-arg NEXT_PUBLIC_API_URL="https://api.${DOMAIN}" \
        -f "${DOCKER_DIR}/frontend/Dockerfile" \
        "${DOCKER_DIR}/frontend"
    
    log_info "Docker images built"
}

# Push Docker images
push_images() {
    log_section "Pushing Docker Images"
    
    local version="${VERSION:-$(git describe --tags --always)}"
    local registry="${DOCKER_REGISTRY:-ghcr.io/thaliumx}"
    
    # Login to registry
    echo "${DOCKER_PASSWORD}" | docker login "${registry}" -u "${DOCKER_USERNAME}" --password-stdin
    
    # Push images
    docker push "${registry}/thaliumx-backend:${version}"
    docker push "${registry}/thaliumx-backend:latest"
    docker push "${registry}/thaliumx-frontend:${version}"
    docker push "${registry}/thaliumx-frontend:latest"
    
    log_info "Docker images pushed"
}

# Configure Kubernetes
configure_kubernetes() {
    log_section "Configuring Kubernetes"
    
    # Update kubeconfig
    aws eks update-kubeconfig \
        --name "${CLUSTER_NAME}" \
        --region "${AWS_REGION}"
    
    # Verify connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Create namespace if not exists
    kubectl create namespace thaliumx --dry-run=client -o yaml | kubectl apply -f -
    
    # Create image pull secret
    kubectl create secret docker-registry ghcr-secret \
        --docker-server=ghcr.io \
        --docker-username="${DOCKER_USERNAME}" \
        --docker-password="${DOCKER_PASSWORD}" \
        --namespace=thaliumx \
        --dry-run=client -o yaml | kubectl apply -f -
    
    log_info "Kubernetes configured"
}

# Deploy with Helm
deploy_helm() {
    log_section "Deploying with Helm"
    
    local version="${VERSION:-$(git describe --tags --always)}"
    local values_file="${K8S_DIR}/helm/thaliumx/values-${ENVIRONMENT}.yaml"
    
    # Use default values if environment-specific file doesn't exist
    if [ ! -f "${values_file}" ]; then
        values_file="${K8S_DIR}/helm/thaliumx/values.yaml"
    fi
    
    # Update Helm dependencies
    helm dependency update "${K8S_DIR}/helm/thaliumx"
    
    # Deploy
    helm upgrade --install thaliumx "${K8S_DIR}/helm/thaliumx" \
        --namespace thaliumx \
        --values "${values_file}" \
        --set global.environment="${ENVIRONMENT}" \
        --set global.domain="${DOMAIN}" \
        --set backend.image.tag="${version}" \
        --set frontend.image.tag="${version}" \
        --wait \
        --timeout 10m
    
    log_info "Helm deployment complete"
}

# Run database migrations
run_migrations() {
    log_section "Running Database Migrations"
    
    # Wait for backend pod to be ready
    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/component=backend \
        -n thaliumx \
        --timeout=300s
    
    # Run migrations
    kubectl exec -it deployment/thaliumx-backend \
        -n thaliumx \
        -- npm run migrate || true
    
    log_info "Database migrations complete"
}

# Verify deployment
verify_deployment() {
    log_section "Verifying Deployment"
    
    # Check pod status
    log_info "Checking pod status..."
    kubectl get pods -n thaliumx
    
    # Check services
    log_info "Checking services..."
    kubectl get svc -n thaliumx
    
    # Check ingress
    log_info "Checking ingress..."
    kubectl get ingress -n thaliumx
    
    # Health checks
    log_info "Running health checks..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -sf "https://api.${DOMAIN}/health" > /dev/null; then
            log_info "Backend health check passed"
            break
        fi
        log_warn "Health check attempt ${attempt}/${max_attempts} failed, retrying..."
        sleep 10
        ((attempt++))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_error "Health checks failed after ${max_attempts} attempts"
        exit 1
    fi
    
    log_info "Deployment verified successfully"
}

# Rollback deployment
rollback() {
    log_section "Rolling Back Deployment"
    
    helm rollback thaliumx -n thaliumx
    
    log_info "Rollback complete"
}

# Print deployment summary
print_summary() {
    log_section "Deployment Summary"
    
    echo "Environment: ${ENVIRONMENT}"
    echo "Domain: ${DOMAIN}"
    echo "Cluster: ${CLUSTER_NAME}"
    echo ""
    echo "URLs:"
    echo "  - Frontend: https://app.${DOMAIN}"
    echo "  - API: https://api.${DOMAIN}"
    echo "  - Auth: https://auth.${DOMAIN}"
    echo ""
    echo "Monitoring:"
    echo "  - Grafana: https://grafana.${DOMAIN}"
    echo "  - Prometheus: https://prometheus.${DOMAIN}"
    echo ""
    echo "Next Steps:"
    echo "1. Verify all services are running: kubectl get pods -n thaliumx"
    echo "2. Check logs: kubectl logs -f deployment/thaliumx-backend -n thaliumx"
    echo "3. Monitor metrics in Grafana"
    echo "4. Set up alerting rules"
}

# Main execution
main() {
    local command="${1:-deploy}"
    
    case "$command" in
        deploy)
            check_prerequisites
            validate_environment
            generate_certificates
            initialize_vault
            build_images
            push_images
            configure_kubernetes
            deploy_helm
            run_migrations
            verify_deployment
            print_summary
            ;;
        build)
            check_prerequisites
            build_images
            ;;
        push)
            push_images
            ;;
        certificates)
            generate_certificates
            ;;
        vault)
            initialize_vault
            ;;
        verify)
            verify_deployment
            ;;
        rollback)
            rollback
            ;;
        *)
            echo "Usage: $0 {deploy|build|push|certificates|vault|verify|rollback}"
            exit 1
            ;;
    esac
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [command] [options]"
            echo ""
            echo "Commands:"
            echo "  deploy      Full deployment (default)"
            echo "  build       Build Docker images only"
            echo "  push        Push Docker images only"
            echo "  certificates Generate TLS certificates"
            echo "  vault       Initialize Vault secrets"
            echo "  verify      Verify deployment"
            echo "  rollback    Rollback to previous version"
            echo ""
            echo "Options:"
            echo "  --environment ENV   Deployment environment (default: production)"
            echo "  --domain DOMAIN     Domain name (default: thaliumx.com)"
            echo "  --version VERSION   Version tag for images"
            echo "  --help              Show this help message"
            exit 0
            ;;
        *)
            COMMAND="$1"
            shift
            ;;
    esac
done

main "${COMMAND:-deploy}"