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

### [Kagent with LLM Observability](./kagent/)
A comprehensive demo showcasing AI agent orchestration with full OpenTelemetry observability for LLM calls. This demo demonstrates:
- Kagent agent framework with Anthropic Claude as the LLM provider
- OpenTelemetry tracing for LLM inference calls and agent workflows
- Model Context Protocol (MCP) integration with Dash0 for observability queries
- Observability agent with 23 Dash0 MCP tools for querying logs, traces, and metrics
- Web frontend for querying observability data via natural language
- Real-world example of AI agents using MCP tools to query observability data

**Technologies**: Kagent, Anthropic Claude, OpenTelemetry, MCP (Model Context Protocol), Kubernetes (Kind), Helm

### [LangChain with OpenTelemetry](./langchain/)
A demonstration of LangChain applications instrumented with OpenTelemetry, showcasing both manual and automatic instrumentation approaches:
- Manual instrumentation: Explicit OpenTelemetry code with custom spans and full control
- Auto-instrumentation: Zero-code instrumentation using `opentelemetry-instrument`
- LangChain integration with Anthropic Claude
- Chain composition examples (prompt | llm | parser)
- Streaming response handling with tracing
- Local OpenTelemetry Collector with Docker Compose

**Technologies**: LangChain, Anthropic Claude, OpenTelemetry, Python, Docker

### [OpenLIT Auto-Instrumentation](./openlit/)
A demonstration of zero-code auto-instrumentation for LLM applications using the OpenLIT operator:
- OpenLIT operator for automatic instrumentation injection into Python applications
- Sample FastAPI application with Anthropic Claude integration
- Kubernetes deployment with Kind cluster
- Zero-code observability - no manual instrumentation required
- Automatic OTLP trace export to Dash0 via OpenTelemetry Collector
- Runtime instrumentation injection using pod labels

**Technologies**: OpenLIT, Anthropic Claude, Kubernetes (Kind), Python, FastAPI, OpenTelemetry

### [Traefik Ingress with Observability](./traefik/)
A complete Traefik ingress controller demo with full observability using OpenTelemetry and Dash0. This demo showcases:
- Multi-node Kind cluster with Traefik v3.5 as ingress controller
- OTLP metrics, distributed tracing, and logs export from Traefik (HTTP/gRPC)
- Direct OTLP log export with automatic trace correlation (experimental otlpLogs feature)
- OpenTelemetry Collectors (DaemonSet + Deployment) for comprehensive telemetry collection
- Node.js demo application with auto-instrumentation and trace propagation
- Load generation scripts for testing observability

**Technologies**: Traefik, Kubernetes (Kind), OpenTelemetry, Node.js, Helm

### [Ingress-NGINX with Observability](./ingress-nginx/)
A complete ingress-nginx controller demo with full observability using OpenTelemetry and Dash0. This demo showcases:
- Multi-node Kind cluster with ingress-nginx as ingress controller
- OTLP metrics and distributed tracing from ingress-nginx
- OpenTelemetry Collectors (DaemonSet + Deployment) for comprehensive telemetry collection
- Trace-logs correlation with custom log processing
- Node.js demo application with auto-instrumentation and trace propagation

**Technologies**: Ingress-NGINX, Kubernetes (Kind), OpenTelemetry, Node.js, Helm

### [Emissary-ingress with Observability](./emissary-ingress/)
A complete Emissary-ingress controller demo with full observability using OpenTelemetry and Dash0. This demo showcases:
- Multi-node Kind cluster with Emissary-ingress v3.12.2 as ingress controller
- OTLP metrics and distributed tracing from Emissary-ingress
- JSON structured access logs with sequential transform processors for trace correlation
- OpenTelemetry Collectors (DaemonSet + Deployment) for comprehensive telemetry collection
- Node.js demo application with auto-instrumentation and trace propagation
- Load generation scripts for testing observability

**Technologies**: Emissary-ingress, Kubernetes (Kind), OpenTelemetry, Node.js, Helm

### [Contour with Gateway API](./contour/)
A complete Contour ingress controller demo with full observability using OpenTelemetry and Dash0. This demo showcases:
- Multi-node Kind cluster with Contour/Envoy using Gateway API
- OTLP metrics and distributed tracing from Contour/Envoy
- OpenTelemetry Collectors (DaemonSet + Deployment) for comprehensive telemetry collection
- JSON structured access logs with automatic trace_id/span_id extraction for correlation
- Node.js demo application with auto-instrumentation and W3C trace context propagation
- Modern Gateway API with GatewayClass, Gateway, and HTTPRoute resources

**Technologies**: Contour, Envoy, Gateway API, Kubernetes (Kind), OpenTelemetry, Node.js, Helm

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

### [NGINX logs](./nginx-logs/)

Demonstrates setting up an OpenTelemetry pipeline for NGINX logs covering:

- Structured JSON logging for reliable parsing.
- Log sampling to cut down on log noise and cost.
- Robust error log parsing.
- Full integration with the OpenTelemetry ecosystem.

### [Linkerd Service Mesh](./linkerd/)
A Linkerd service mesh demo with full observability using Dash0. This demo showcases:
- Multi-node Kind cluster with Linkerd edge release (native proxy tracing)
- Metrics collection via Prometheus scraping of Linkerd control plane and proxy endpoints
- Distributed tracing using Linkerd's built-in OpenTelemetry trace export
- Emojivoto demo application with OTel-instrumented images for application-level traces
- OpenTelemetry Collector in the Linkerd mesh forwarding telemetry to Dash0

**Technologies**: Linkerd, Kubernetes (Kind), OpenTelemetry, Go, Helm

## Getting Started

1. **Prerequisites**: Ensure you have Docker installed and a Dash0 account
2. **Environment Setup**: Copy `.env.template` to `.env` and configure your Dash0 credentials
3. **Choose a Demo**: Navigate to any demo directory and follow its README instructions
4. **Run the Example**: Each demo includes setup scripts for easy deployment

Each example directory contains its own comprehensive README with detailed setup and usage instructions. 
