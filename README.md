# Thaliumx Platform

A comprehensive financial trading infrastructure platform built with microservices architecture.

## Prerequisites

- **Node.js** >= 20.0.0
- **pnpm** >= 9.0.0
- **Docker** >= 24.0.0
- **Docker Compose** >= 2.20.0

## Quick Start

### 1. Install Dependencies

```bash
# Install pnpm if not already installed
npm install -g pnpm@9

# Install project dependencies
pnpm install
```

### 2. Start Infrastructure

```bash
# Start all Docker services
pnpm docker:up

# Or start specific service groups
pnpm docker:up:infra        # databases, messaging, security, gateway
pnpm docker:up:apps         # core, trading, fintech
pnpm docker:up:observability # monitoring stack
```

### 3. View Running Services

```bash
pnpm docker:ps
```

## Project Structure

```
thaliumx/
├── package.json              # Root package.json with Docker scripts
├── pnpm-workspace.yaml       # PNPM workspace configuration
├── .npmrc                    # PNPM settings
├── .gitignore
│
├── docker/                   # Docker orchestration
│   ├── compose.yaml          # Master orchestrator
│   ├── .env                  # Environment variables
│   ├── Makefile              # Make commands
│   ├── databases/            # PostgreSQL, MongoDB, Redis, Typesense
│   ├── messaging/            # Kafka (KRaft)
│   ├── security/             # Keycloak, Vault, OPA
│   ├── gateway/              # APISIX, etcd
│   ├── core/                 # Frontend, Backend
│   ├── trading/              # Dingir, Liquibook, QuantLib
│   ├── fintech/              # Ballerine, BlinkFinance
│   └── observability/        # Prometheus, Grafana, Loki, etc.
│
├── frontend/                 # Frontend application (workspace)
├── backend/                  # Backend application (workspace)
├── dingir/                   # Dingir Exchange (workspace)
├── liquibook/                # Liquibook (workspace)
├── quantlib/                 # QuantLib service (workspace)
├── ballerine/                # Ballerine (workspace)
├── blinkfinance/             # BlinkFinance (workspace)
└── packages/                 # Shared packages (workspace)
```

## Docker Commands

All Docker commands are available via pnpm scripts:

| Command | Description |
|---------|-------------|
| `pnpm docker:up` | Start all services |
| `pnpm docker:down` | Stop all services |
| `pnpm docker:logs` | View logs |
| `pnpm docker:ps` | List running containers |
| `pnpm docker:clean` | Stop and remove all containers/volumes |
| `pnpm docker:up:databases` | Start databases only |
| `pnpm docker:up:messaging` | Start Kafka only |
| `pnpm docker:up:security` | Start security services |
| `pnpm docker:up:gateway` | Start API gateway |
| `pnpm docker:up:core` | Start frontend/backend |
| `pnpm docker:up:trading` | Start trading services |
| `pnpm docker:up:fintech` | Start fintech services |
| `pnpm docker:up:observability` | Start monitoring stack |
| `pnpm docker:up:infra` | Start all infrastructure |
| `pnpm docker:up:apps` | Start all applications |

Alternatively, use Make commands from the `docker/` directory:

```bash
cd docker
make help    # Show all available commands
make up      # Start all services
make down    # Stop all services
```

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| Frontend | 3001 | Web application |
| Backend | 8000 | API server |
| PostgreSQL | 5432 | TimescaleDB |
| MongoDB | 27017 | Document store |
| Redis | 6379 | Cache/Queue |
| Typesense | 8108 | Search engine |
| Kafka | 9092 | Message broker |
| Keycloak | 8080 | Identity provider |
| Vault | 8200 | Secrets management |
| OPA | 8181 | Policy engine |
| APISIX | 9080 | API gateway |
| etcd | 2379 | Service discovery |
| Grafana | 3000 | Dashboards |
| Prometheus | 9090 | Metrics |
| Loki | 3100 | Logs |
| Tempo | 3200 | Traces |

## Network

All services communicate on the `thaliumx-net` Docker network (172.28.0.0/16).

## Environment Variables

Configuration is managed through `docker/.env`. Key variables:

- `POSTGRES_PASSWORD` - PostgreSQL password
- `REDIS_PASSWORD` - Redis password
- `KEYCLOAK_ADMIN_PASSWORD` - Keycloak admin password
- `VAULT_DEV_ROOT_TOKEN_ID` - Vault root token
- `GRAFANA_ADMIN_PASSWORD` - Grafana admin password

⚠️ **Important:** Change all default passwords before deploying to production!

## Development

### Adding a New Workspace Package

1. Create the package directory
2. Add a `package.json` with the package name
3. The package will be automatically included via `pnpm-workspace.yaml`

### Installing Dependencies

```bash
# Install to root
pnpm add -w <package>

# Install to specific workspace
pnpm add <package> --filter <workspace-name>

# Install dev dependency
pnpm add -D <package> --filter <workspace-name>
```

## License

UNLICENSED - Private repository