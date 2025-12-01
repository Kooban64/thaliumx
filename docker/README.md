# Thaliumx Docker Orchestration

This directory contains the Docker Compose configuration for the Thaliumx platform.

## Current Status

**28 containers running** - Full infrastructure operational with **ALL healthchecks passing**!

| Category | Services | Count | Status |
|----------|----------|-------|--------|
| Security | Vault, Keycloak, OPA | 3 | ✅ All Healthy |
| Databases | PostgreSQL (TimescaleDB), MongoDB, Redis | 3 | ✅ All Healthy |
| Search | Typesense | 1 | ✅ Healthy |
| Messaging | Kafka + KRaft, Kafka UI | 2 | ✅ All Healthy |
| Gateway | APISIX, etcd, APISIX Dashboard | 3 | ✅ All Healthy |
| Observability | Prometheus, Grafana, Loki, Tempo, Promtail, otel-collector, blackbox-exporter, cAdvisor, postgres-exporter, redis-exporter | 10 | ✅ All Healthy |
| Fintech | Ballerine (workflow, backoffice, postgres), BlinkFinance | 4 | ✅ All Healthy |
| Core | Frontend, Backend (placeholders) | 2 | ✅ All Healthy |
| Trading | Dingir, Liquibook, QuantLib | 0 | ⏳ Pending (needs custom development) |
| **Total** | | **28** | **✅ All Healthy** |

## Directory Structure

```
docker/
├── compose.yaml                    # Master orchestrator file
├── .env                            # Global environment variables
├── Makefile                        # Convenience commands
├── README.md                       # This file
│
├── core/                           # Frontend & Backend services
│   ├── compose.yaml
│   └── config/
│       ├── frontend/
│       │   ├── nginx.conf
│       │   └── html/
│       └── backend/
│           └── nginx.conf
│
├── trading/                        # Exchange, Liquibook, QuantLib
│   └── compose.yaml
│
├── gateway/                        # APISIX & etcd
│   ├── compose.yaml
│   └── config/
│       └── apisix.yaml
│
├── security/                       # Keycloak, Vault, OPA
│   ├── compose.yaml
│   └── policies/
│
├── databases/                      # PostgreSQL, MongoDB, Redis, Typesense
│   ├── compose.yaml
│   └── init/
│
├── messaging/                      # Kafka with KRaft
│   └── compose.yaml
│
├── fintech/                        # Ballerine, BlinkFinance
│   ├── compose.yaml
│   ├── config/
│   │   ├── ballerine.env
│   │   └── blinkfinance/
│   └── scripts/
│       ├── ballerine-entrypoint.sh
│       └── vault-secrets.js
│
├── vault/                          # Vault configuration
│   ├── compose.yaml
│   ├── config/
│   ├── policies/
│   └── scripts/
│
├── redis/                          # Redis configuration
│   └── compose.yaml
│
├── postgres/                       # PostgreSQL configuration
│   ├── compose.yaml
│   └── init/
│
├── keycloak/                       # Keycloak configuration
│   └── compose.yaml
│
├── mongodb/                        # MongoDB configuration
│   ├── compose.yaml
│   └── init/
│
├── kafka/                          # Kafka configuration
│   └── compose.yaml
│
├── apisix/                         # APISIX configuration
│   ├── compose.yaml
│   └── config/
│
├── opa/                            # OPA configuration
│   ├── compose.yaml
│   └── policies/
│
├── typesense/                      # Typesense configuration
│   └── compose.yaml
│
└── observability/                  # Full monitoring stack
    ├── compose.yaml
    └── config/
        ├── prometheus.yml
        ├── loki.yml
        ├── promtail.yml
        ├── tempo.yml
        ├── otel-collector.yml
        ├── blackbox.yml
        └── grafana/
            ├── dashboards/
            └── provisioning/
```

## Network

All services run on the `thaliumx-net` bridge network (subnet: 172.28.0.0/16).

## Container Naming

All containers are prefixed with `thaliumx-` for easy identification.

## Quick Start

### Start Services Individually (Recommended)

```bash
# 1. Create network first
docker network create --driver bridge --subnet 172.28.0.0/16 thaliumx-net

# 2. Start services in order
cd docker/vault && docker compose up -d
cd docker/redis && docker compose up -d
cd docker/postgres && docker compose up -d
cd docker/keycloak && docker compose up -d
cd docker/mongodb && docker compose up -d
cd docker/kafka && docker compose up -d
cd docker/apisix && docker compose up -d
cd docker/opa && docker compose up -d
cd docker/typesense && docker compose up -d
cd docker/observability && docker compose up -d
cd docker/fintech && docker compose up -d
cd docker/core && docker compose up -d
```

### Using Make

```bash
# Show all available commands
make help

# Create network and start all services
make up

# View running containers
make ps

# View logs
make logs

# Stop all services
make down
```

## Service Ports

| Service | Port | Description |
|---------|------|-------------|
| **Security** | | |
| Vault | 8200 | Secrets management |
| Keycloak | 8080 | Identity & access management |
| OPA | 8181 | Policy engine |
| **Databases** | | |
| PostgreSQL | 5432 | Primary database (TimescaleDB) |
| MongoDB | 27017 | Document database |
| Redis | 6379 | Cache & session store |
| Typesense | 8108 | Search engine |
| **Messaging** | | |
| Kafka | 9092 | Event streaming |
| Kafka UI | 8082 | Kafka management UI |
| **Gateway** | | |
| APISIX | 9080 | API Gateway |
| APISIX Admin | 9180 | APISIX Admin API |
| APISIX Dashboard | 9000 | APISIX Dashboard UI |
| etcd | 2379 | Service discovery |
| **Observability** | | |
| Prometheus | 9090 | Metrics collection |
| Grafana | 3000 | Dashboards & visualization |
| Loki | 3100 | Log aggregation |
| Tempo | 3200 | Distributed tracing |
| otel-collector | 4317, 4318 | OpenTelemetry collector |
| **Fintech** | | |
| Ballerine API | 3003 | KYC/KYB workflow service |
| Ballerine Backoffice | 3004 | Ballerine admin UI |
| Ballerine PostgreSQL | 5433 | Ballerine database |
| BlinkFinance | 8005 | Financial services (placeholder) |
| **Core** | | |
| Frontend | 3001 | Web application (placeholder) |
| Backend | 8000 | API server (placeholder) |

## Credentials

All services use the standardized password: `ThaliumX2025`

| Service | Username | Password |
|---------|----------|----------|
| PostgreSQL | thaliumx | ThaliumX2025 |
| MongoDB | thaliumx | ThaliumX2025 |
| Redis | - | ThaliumX2025 |
| Keycloak | admin | ThaliumX2025 |
| Grafana | admin | ThaliumX2025 |
| Vault | - | Token: <VAULT_TOKEN> |
| Typesense | - | API Key: ThaliumX2025 |

**⚠️ Important:** Change all passwords before deploying to production!

## Vault Secrets

Secrets are stored in HashiCorp Vault at the following paths:

| Path | Description |
|------|-------------|
| `kv/databases/postgres` | PostgreSQL credentials |
| `kv/databases/mongodb` | MongoDB credentials |
| `kv/databases/redis` | Redis credentials |
| `kv/security/keycloak` | Keycloak credentials |
| `kv/fintech/ballerine` | Ballerine secrets (bcrypt salt, JWT keys, etc.) |

## Health Checks

All services include health checks. View service health:

```bash
# Check all container health
docker ps --format "table {{.Names}}\t{{.Status}}" | grep thaliumx

# Check specific service
docker inspect thaliumx-<service-name> | jq '.[0].State.Health'
```

## Accessing Services

| Service | URL | Notes |
|---------|-----|-------|
| Grafana | http://localhost:3000 | Dashboards & monitoring |
| Keycloak | http://localhost:8080 | Identity management |
| Prometheus | http://localhost:9090 | Metrics |
| APISIX Dashboard | http://localhost:9000 | API Gateway management |
| Vault | http://localhost:8200 | Secrets management |
| Kafka UI | http://localhost:8082 | Kafka management |
| Ballerine Backoffice | http://localhost:3004 | KYC/KYB admin |
| Frontend | http://localhost:3001 | Web application |
| Backend API | http://localhost:8000 | REST API |

## Troubleshooting

### Network Issues
```bash
# Recreate network
docker network rm thaliumx-net
docker network create --driver bridge --subnet 172.28.0.0/16 thaliumx-net
```

### Container Won't Start
```bash
# Check logs
docker logs thaliumx-<service-name>

# Check health
docker inspect thaliumx-<service-name> | jq '.[0].State.Health'
```

### Vault Issues
```bash
# Check Vault status
docker exec thaliumx-vault vault status

# List secrets
docker exec thaliumx-vault vault kv list kv/
```

### Reset Everything
```bash
# Stop all containers
docker ps -q --filter "name=thaliumx" | xargs -r docker stop
docker ps -aq --filter "name=thaliumx" | xargs -r docker rm

# Remove volumes (WARNING: data loss!)
docker volume ls -q --filter "name=thaliumx" | xargs -r docker volume rm

# Remove network
docker network rm thaliumx-net
```

## Future Enhancements

- [ ] Trading services (Dingir, Liquibook, QuantLib) - requires custom development
- [ ] Sequelize setup for schema management
- [ ] Citus for multi-tenancy
- [ ] BlinkFinance actual implementation (currently placeholder)
- [ ] Frontend/Backend actual implementation (currently placeholders)