# Thaliumx Platform

A comprehensive, production-ready infrastructure backbone for building modern financial applications.

[![Version](https://img.shields.io/badge/version-0.3.0--trading-blue.svg)](https://github.com/thaliumx/thaliumx)
[![Services](https://img.shields.io/badge/services-36-green.svg)](#services)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## 🚀 Overview

Thaliumx provides a complete Docker-based infrastructure with 36 pre-configured services covering:

- **Data Storage**: PostgreSQL (TimescaleDB), MongoDB, Redis, Typesense
- **Messaging**: Kafka (KRaft), Schema Registry
- **Security**: Keycloak, Vault, OPA, Wazuh SIEM
- **API Gateway**: APISIX with Dashboard
- **Observability**: Prometheus, Grafana, Loki, Tempo, OpenTelemetry
- **Fintech**: Ballerine (KYC/KYB), BlinkFinance (Ledger)
- **Trading**: Dingir Exchange, Liquibook, QuantLib

## 📊 Project Status

| Category | Status | Services |
|----------|--------|----------|
| Data Layer | ✅ Complete | PostgreSQL, MongoDB, Redis, Typesense |
| Messaging | ✅ Complete | Kafka, Schema Registry, Kafka UI |
| Security | ✅ Complete | Keycloak, Vault, OPA, Wazuh (3) |
| Gateway | ✅ Complete | APISIX, etcd, Dashboard |
| Observability | ✅ Complete | 10 services |
| Fintech | ✅ Complete | Ballerine (3), BlinkFinance |
| Core | ✅ Placeholder | Frontend, Backend |
| Trading | ✅ Complete | Dingir (2), Liquibook, QuantLib |

**Total: 36 services running and healthy**

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        THALIUMX PLATFORM                         │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│   │ Frontend │  │ Backend  │  │Ballerine │  │BlinkFin. │       │
│   └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘       │
│        └──────────────┴──────────────┴──────────────┘           │
│                           │                                      │
│   ┌───────────────────────┼───────────────────────┐             │
│   │              Trading Layer                     │             │
│   │  Dingir Exchange │ Liquibook │ QuantLib       │             │
│   └───────────────────────────────────────────────┘             │
│                           │                                      │
│                    ┌──────┴──────┐                              │
│                    │   APISIX    │                              │
│                    │   Gateway   │                              │
│                    └──────┬──────┘                              │
│                           │                                      │
│   ┌───────────────────────┼───────────────────────┐             │
│   │              Security Layer                    │             │
│   │  Keycloak │ Vault │ OPA │ Wazuh SIEM         │             │
│   └───────────────────────────────────────────────┘             │
│                                                                  │
│   ┌───────────────────────┬───────────────────────┐             │
│   │      Data Layer       │    Messaging Layer    │             │
│   │ PostgreSQL │ MongoDB  │  Kafka │ Schema Reg.  │             │
│   │ Redis │ Typesense     │  Kafka UI             │             │
│   └───────────────────────┴───────────────────────┘             │
│                                                                  │
│   ┌───────────────────────────────────────────────┐             │
│   │            Observability Layer                 │             │
│   │ Prometheus │ Grafana │ Loki │ Tempo │ OTEL   │             │
│   └───────────────────────────────────────────────┘             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

```bash
# Clone the repository
git clone <repository-url> thaliumx
cd thaliumx

# Create Docker network
docker network create --driver bridge --subnet 172.28.0.0/16 thaliumx-net

# Generate Wazuh certificates
cd docker/wazuh && chmod +x scripts/generate-certs.sh && ./scripts/generate-certs.sh && cd ../..

# Start all services
cd docker && docker compose up -d

# Check status (wait 5-10 minutes for all services)
docker ps --filter name=thaliumx --format "table {{.Names}}\t{{.Status}}"
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [Installation Guide](docs/INSTALLATION_GUIDE.md) | Complete setup from zero |
| [Core Services](docs/core-services/README.md) | Service descriptions and value |
| [Installation Tips](docs/installation-tips/README.md) | Fixes and workarounds |

## 🔗 Access Points

### Web Interfaces

| Service | URL | Credentials |
|---------|-----|-------------|
| Grafana | http://localhost:3000 | admin / ThaliumX2025 |
| Keycloak | http://localhost:8080 | admin / ThaliumX2025 |
| Vault | http://localhost:8200 | Token: <VAULT_TOKEN> |
| APISIX Dashboard | http://localhost:9000 | admin / ThaliumX2025 |
| Kafka UI | http://localhost:8081 | - |
| Wazuh Dashboard | https://localhost:5601 | admin / SecretPassword |
| Ballerine Backoffice | http://localhost:3004 | - |
| Prometheus | http://localhost:9090 | - |

### Trading APIs

| Service | URL | Description |
|---------|-----|-------------|
| Dingir REST API | http://localhost:50053/api/exchange/panel | Trading engine REST interface |
| Dingir gRPC | localhost:50051 | High-performance gRPC interface |
| Liquibook | http://localhost:8083 | Order book engine |
| QuantLib | http://localhost:3010 | Financial calculations |

### Other APIs

| Service | URL |
|---------|-----|
| APISIX Gateway | http://localhost:9080 |
| Schema Registry | http://localhost:8085 |
| OPA | http://localhost:8181 |
| Typesense | http://localhost:8108 |
| BlinkFinance | http://localhost:5001 |
| Ballerine Workflow | http://localhost:3003 |

### Databases

| Service | Connection |
|---------|------------|
| PostgreSQL | `postgres://thaliumx:ThaliumX2025@localhost:5432/thaliumx` |
| MongoDB | `mongodb://thaliumx:ThaliumX2025@localhost:27017` |
| Redis | `redis://:ThaliumX2025@localhost:6379` |

## 📁 Project Structure

```
thaliumx/
├── docker/                    # Docker Compose configurations
│   ├── compose.yaml          # Master orchestrator
│   ├── databases/            # PostgreSQL, MongoDB, Redis, Typesense
│   ├── messaging/            # Kafka, Schema Registry
│   ├── security/             # Keycloak, Vault, OPA
│   ├── gateway/              # APISIX, etcd
│   ├── observability/        # Prometheus, Grafana, Loki, etc.
│   ├── wazuh/                # Wazuh SIEM/XDR
│   ├── fintech/              # Ballerine, BlinkFinance
│   ├── core/                 # Frontend, Backend
│   └── trading/              # Dingir, Liquibook, QuantLib
│       ├── dingir/           # Rust trading engine
│       ├── liquibook/        # C++/Node.js order book
│       ├── quantlib/         # Python financial calculations
│       └── plugins/          # Trading UI plugins
├── docs/                      # Documentation
│   ├── INSTALLATION_GUIDE.md
│   ├── core-services/
│   └── installation-tips/
└── README.md                  # This file
```

## 🏷️ Version History

| Version | Tag | Description |
|---------|-----|-------------|
| 0.3.0 | v0.3.0-trading | Trading services (Dingir, Liquibook, QuantLib) - 36 containers |
| 0.2.0 | v0.2.0-backbone | Complete backbone with 32 services + docs |
| 0.1.0 | v0.1.0-core-services | Initial 28 services |

## 🗺️ Roadmap

### Completed ✅
- [x] Data Layer (PostgreSQL/TimescaleDB, MongoDB, Redis, Typesense)
- [x] Messaging Layer (Kafka KRaft, Schema Registry, Kafka UI)
- [x] Security Layer (Keycloak, Vault, OPA, Wazuh SIEM)
- [x] Gateway Layer (APISIX, etcd, Dashboard)
- [x] Observability Layer (10 services)
- [x] Fintech Layer (Ballerine, BlinkFinance)
- [x] Core Layer (Frontend/Backend placeholders)
- [x] Trading Layer (Dingir Exchange, Liquibook, QuantLib)
- [x] Documentation

### Planned 🔲
- [ ] Citus for multi-tenancy
- [ ] Production hardening
- [ ] Kubernetes deployment
- [ ] CI/CD pipelines

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

This platform integrates the following open-source projects:
- [PostgreSQL](https://www.postgresql.org/) / [TimescaleDB](https://www.timescale.com/)
- [Apache Kafka](https://kafka.apache.org/)
- [Keycloak](https://www.keycloak.org/)
- [HashiCorp Vault](https://www.vaultproject.io/)
- [Apache APISIX](https://apisix.apache.org/)
- [Prometheus](https://prometheus.io/) / [Grafana](https://grafana.com/)
- [Wazuh](https://wazuh.com/)
- [Ballerine](https://www.ballerine.com/)
- [BlinkFinance](https://github.com/blnkfinance/blnk)
- [Dingir Exchange](https://github.com/fluidex/dingir-exchange)
- [Liquibook](https://github.com/objectcomputing/liquibook)
- [QuantLib](https://www.quantlib.org/)

---

**Built with ❤️ for the fintech community**
