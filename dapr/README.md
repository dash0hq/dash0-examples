# Dapr Todo Demo

A simple demonstration of Dapr (Distributed Application Runtime) showcasing microservices architecture with state management, pub/sub messaging, and service-to-service invocation. Features full observability with OpenTelemetry.

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│   Frontend  │────▶│   Todo Service   │────▶│ Validation Service  │
│   (React)   │     │  (Java/Spring)   │     │   (Java/Spring)     │
└─────────────┘     └──────────────────┘     └─────────────────────┘
                            │
                            │ PubSub Events
                            ▼
                  ┌──────────────────────┐
                  │ Notification Service │
                  │    (Java/Spring)     │
                  └──────────────────────┘
```

## 🚀 Quick Start

Deploy the complete application:

```bash
./00_run.sh
```

Access the application at: http://localhost:31000

## 📋 Services

- **Frontend** (React) - Web UI for managing todos
- **Todo Service** (Java/Spring Boot) - Main business logic, state management
- **Validation Service** (Java/Spring Boot) - Validates todo names against forbidden words
- **Notification Service** (Java/Spring Boot) - Logs todo events from pub/sub

## 🔧 Dapr Features

- **State Management**: PostgreSQL for persistent todo storage
- **Pub/Sub Messaging**: RabbitMQ for event notifications
- **Service Invocation**: Direct service-to-service calls
- **Configuration**: Centralized tracing configuration

## 🛠️ Manual Steps

Run individual deployment steps:

```bash
./scripts/01_setup_kind.sh              # Setup Kind cluster + registry  
./scripts/02_install_dapr.sh            # Install Dapr control plane
./scripts/03_install_otel.sh            # Install OpenTelemetry stack
./scripts/04_build_images.sh            # Build all service images
./scripts/05_deploy_databases.sh        # Deploy PostgreSQL + RabbitMQ
./scripts/06_deploy_dapr_components.sh  # Deploy Dapr components
./scripts/07_deploy_services.sh         # Deploy microservices
```

## 🧹 Cleanup

Remove everything:

```bash
./01_cleanup.sh
```

## 📊 Monitoring

- **Application**: http://localhost:31000
- **RabbitMQ Management**: http://localhost:31672 (guest/guest)
- **View Pods**: `kubectl get pods -n dapr-demo`
- **View Logs**: `kubectl logs -f <pod-name> -n dapr-demo`