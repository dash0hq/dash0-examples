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

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   Dash0                          │
│         (Metrics, Traces, Logs, Dashboards)      │
└─────────────────────▲────────────────────────────┘
                      │ OTLP/gRPC
┌─────────────────────┴────────────────────────────┐
│           OpenTelemetry Collectors               │
│  • DaemonSet: Container logs with trace          │
│    extraction, node/pod metrics, k8s attributes  │
│  • Deployment: Contour/Envoy metrics scraping,   │
│    OTLP receiver for traces, cluster metrics     │
└─────────────────────▲────────────────────────────┘
                      │ OTLP/gRPC
┌─────────────────────┴────────────────────────────┐
│              Contour/Envoy                       │
│  • OTLP tracing export                           │
│  • JSON access logs with traceparent             │
│  • Gateway API with HTTPRoute routing            │
└──────────────────────────────────────────────────┘
                      │
┌──────────────────────────────────────────────────┐
│              Node.js Application                 │
│  • OpenTelemetry auto-instrumentation            │
│  • W3C trace context propagation                 │
└──────────────────────────────────────────────────┘
```

## Individual Deployment Steps

If you prefer to deploy components individually:

1. **Create Kind cluster:**
   ```bash
   ./scripts/01_setup_cluster.sh
   ```

2. **Install OpenTelemetry:**
   ```bash
   ./scripts/02_install_otel.sh
   ```

3. **Install Contour:**
   ```bash
   ./scripts/03_install_contour.sh
   ```

4. **Deploy test applications:**
   ```bash
   ./scripts/04_deploy_apps.sh
   ```

## Load Testing

Generate traffic to test observability:

```bash
# Basic load test (60s, 10 rps)
./scripts/load-test.sh

# Extended load test
./scripts/load-test.sh --duration 300 --rate 50 --concurrent 10
```

## Configuration

The demo configures Contour with Gateway API, OpenTelemetry tracing via ExtensionService, and JSON access logs with trace correlation using a custom OTTL transform processor.

## Troubleshooting

### Check component status:
```bash
# OpenTelemetry
kubectl get pods -n opentelemetry
kubectl logs -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector

# Contour
kubectl get pods -n projectcontour
kubectl logs -n projectcontour -l app.kubernetes.io/name=contour

# Test apps
kubectl get pods -n demo
```

### Verify HTTPRoute:
```bash
# Test direct service access
kubectl port-forward -n demo svc/nodejs-app 3000:3000
curl http://localhost:3000

# Test HTTPRoute via Gateway
kubectl port-forward -n projectcontour svc/envoy-contour 8080:80
curl -H "Host: node.dash0-examples.com" http://localhost:8080
```

## Cleanup

```bash
./01_cleanup.sh
```