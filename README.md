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

## Getting Started

1. **Prerequisites**: Ensure you have Docker installed and a Dash0 account
2. **Environment Setup**: Copy `.env.template` to `.env` and configure your Dash0 credentials
3. **Choose a Demo**: Navigate to any demo directory and follow its README instructions
4. **Run the Example**: Each demo includes setup scripts for easy deployment

Each example directory contains its own comprehensive README with detailed setup and usage instructions. 
