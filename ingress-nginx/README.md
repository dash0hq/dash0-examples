# Ingress-NGINX with OpenTelemetry

Demonstrates ingress-nginx with OpenTelemetry metrics, tracing, and trace-logs correlation using Dash0.

## What it does

- Creates a multi-node Kind cluster with ingress-nginx controller
- Configures OTLP metrics and distributed tracing from ingress-nginx
- Deploys OpenTelemetry Collectors (DaemonSet + Deployment) with trace-logs correlation
- Includes Node.js demo application with auto-instrumentation

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
   echo '127.0.0.1 nodejs.localhost' | sudo tee -a /etc/hosts
   curl -H "Host: nodejs.localhost" http://localhost
   ```

## Key Features

- **Metrics**: Request rate, response times, error rates from ingress-nginx
- **Tracing**: Full trace propagation from ingress through application
- **Logs**: Trace-logs correlation using custom OTTL transform processor
- **Kubernetes**: Node/pod metrics and cluster events

## Configuration

The demo configures ingress-nginx with OpenTelemetry and uses a custom transform processor to extract trace context from nginx logs for correlation in Dash0.

## Cleanup

```bash
./01_cleanup.sh
```