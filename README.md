![This repository is courtesy of Dash0](./images/dash0-logo.png)

# Examples
This repository contains various examples to generate, collect and transmit telemetry, and is typically referenced
by Dash0 [guides](https://www.dash0.com/guides), [blog posts](https://www.dash0.com/blog) and the [integration hub](https://www.dash0.com/hub/integrations).

## Available Demos

### [Java Instrumentation](./java-instrumentation/)
A comprehensive example demonstrating OpenTelemetry auto-instrumentation for Java applications. This demo includes:
- Multi-service Java application (Todo API, Validation service, React frontend)
- Automatic instrumentation using OpenTelemetry Java agent
- Full observability stack (Jaeger, Prometheus, OpenSearch)
- Deployment options for both Docker Compose and Kubernetes

**Technologies**: Java, Spring Boot, React, OpenTelemetry, Docker, Kubernetes

### [OpenTelemetry Collector](./opentelemetry-collector/)
Examples showing how to configure and deploy the OpenTelemetry Collector in various environments:
- **[Docker deployment](./opentelemetry-collector/in-docker/)**: Run the collector in Docker with sample applications
- Additional collector configurations and deployment patterns

**Technologies**: OpenTelemetry Collector, Docker, OTLP

### [Traefik Ingress with Observability](./traefik/)
A complete Traefik ingress controller demo with full observability using OpenTelemetry and Dash0. This demo showcases:
- Multi-node Kind cluster with Traefik v3.5 as ingress controller
- OTLP metrics and distributed tracing from Traefik
- OpenTelemetry Collectors (DaemonSet + Deployment) for comprehensive telemetry collection
- Node.js demo application with auto-instrumentation and trace propagation
- Load generation scripts for testing observability

**Technologies**: Traefik, Kubernetes (Kind), OpenTelemetry, Node.js, Helm

### [Host Metrics Collection](./hostmetrics/)
Demonstrates collecting system-level metrics from Kubernetes nodes using the OpenTelemetry Collector's hostmetrics receiver:
- 2-node Kind cluster setup
- OpenTelemetry Collector DaemonSet on all nodes
- Comprehensive host metrics collection (CPU, memory, disk, network, processes)
- Direct export to Dash0 via OTLP

**Technologies**: OpenTelemetry Collector, Kind, Kubernetes, Helm

### [KEDA Auto-scaling with Dash0](./keda/)
Demonstrates Kubernetes auto-scaling using KEDA with OpenTelemetry metrics exported to Dash0:
- HTTP-based scaling: Scale based on request rate from Dash0 metrics
- RabbitMQ queue-based scaling: Scale consumers based on queue depth (scale-to-zero capable)
- OpenTelemetry Collector exporting metrics to Dash0
- KEDA configured to use Dash0 as metrics source via Prometheus API
- Producer/Consumer Node.js services with full observability

**Technologies**: KEDA, OpenTelemetry Collector, Kind, Kubernetes, Node.js, RabbitMQ, Helm

### [Dapr Microservices](./dapr/)
A comprehensive Dapr (Distributed Application Runtime) demonstration showcasing microservices architecture with full observability:
- Multi-service Java application (Todo, Validation, Notification services + React frontend)
- Dapr features: state management, pub/sub messaging, service-to-service invocation
- PostgreSQL and RabbitMQ integration via Dapr components
- Complete observability with OpenTelemetry and distributed tracing

**Technologies**: Dapr, Java, Spring Boot, React, PostgreSQL, RabbitMQ, OpenTelemetry, Kind, Kubernetes

## Getting Started

1. **Prerequisites**: Ensure you have Docker installed and a Dash0 account
2. **Environment Setup**: Copy `.env.template` to `.env` and configure your Dash0 credentials
3. **Choose a Demo**: Navigate to any demo directory and follow its README instructions
4. **Run the Example**: Each demo includes setup scripts for easy deployment

Each example directory contains its own comprehensive README with detailed setup and usage instructions. 
