# Contour with OpenTelemetry

Demonstrates Contour ingress controller with OpenTelemetry metrics, tracing, and logs using Dash0.

## What it does

- Creates a multi-node Kind cluster with Contour/Envoy
- Configures OTLP metrics, distributed tracing, and JSON access logs
- Deploys OpenTelemetry Collectors (DaemonSet + Deployment) with trace-logs correlation
- Includes Node.js demo application with auto-instrumentation
- Uses Gateway API with HTTPRoute for modern, standards-based routing

## Prerequisites

- Docker
- Kind
- kubectl
- Helm 3

## Setup

1. Configure your Dash0 credentials in `../.env` (copy from `../.env.template`)

2. Run the demo:
   ```bash
   ./00_run.sh
   ```

3. Test:
   ```bash
   kubectl port-forward -n projectcontour svc/envoy-contour 8080:80 &
   curl -H "Host: node.dash0-examples.com" http://localhost:8080
   ```

## Key Features

- **Metrics**: Contour controller and Envoy proxy metrics via Prometheus scraping
- **Tracing**: Full trace propagation from ingress through application using W3C trace context
- **Logs**: JSON structured access logs with automatic trace_id/span_id extraction for correlation
- **Gateway API**: Modern Kubernetes networking with GatewayClass, Gateway, and HTTPRoute resources

## Load Testing

Generate traffic to test observability:

```bash
# Basic load test
./scripts/load-test.sh
```


## Cleanup

```bash
./01_cleanup.sh
```