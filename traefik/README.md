# Traefik Demo with Observability

This demo sets up a complete Traefik ingress controller environment with full observability using OpenTelemetry and Dash0.

## Features

- Multi-node Kind cluster with ingress support
- Traefik v3.5 as ingress controller with OTLP observability
- OpenTelemetry Collector (DaemonSet + Deployment)
- OTLP metrics and tracing from Traefik (HTTP endpoints)
- JSON structured access logs with trace correlation
- Node.js demo application with OpenTelemetry auto-instrumentation
- Load generation script with multiple traffic patterns
- Full integration with Dash0

## Prerequisites

- Docker
- Kind
- kubectl
- Helm 3
- Dash0 account with API token

## Quick Start

1. **Configure environment variables:**
   ```bash
   # From the root directory (dash0-examples)
   cp .env.template .env
   # Edit .env with your Dash0 credentials
   ```

2. **Deploy everything:**
   ```bash
   cd traefik
   ./00_run.sh
   ```

3. **Add host entry:**
   ```bash
   sudo echo '127.0.0.1 nodejs.localhost' >> /etc/hosts
   ```

4. **Access services:**
   - Node.js App: http://nodejs.localhost
   - Traefik Dashboard: http://localhost:8080/dashboard/

5. **Generate load:**
   ```bash
   ./scripts/load-test.sh --duration 300 --rate 20
   ```

## Architecture

```
┌─────────────────────────────────────────────────┐
│                   Dash0                          │
│         (Metrics, Traces, Logs, Dashboards)      │
└─────────────────────▲────────────────────────────┘
                      │ OTLP/gRPC
┌─────────────────────┴────────────────────────────┐
│           OpenTelemetry Collectors               │
│  • DaemonSet: Node/pod metrics, container logs   │
│  • Deployment: Cluster metrics, OTLP receiver    │
└─────────────────────▲────────────────────────────┘
                      │ OTLP/HTTP
┌─────────────────────┴────────────────────────────┐
│              Traefik Ingress                     │
│  • OTLP metrics export (HTTP)                    │
│  • OTLP tracing export (HTTP)                    │
│  • JSON access logs with TraceId                 │
│  • Request routing & load balancing              │
└──────────────────────────────────────────────────┘
                      │
┌──────────────────────────────────────────────────┐
│              Node.js Application                 │
│  • Simple Express API endpoint                   │
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

3. **Install Traefik:**
   ```bash
   ./scripts/03_install_traefik.sh
   ```

4. **Deploy test applications:**
   ```bash
   ./scripts/04_deploy_apps.sh
   ```

## Load Testing

The load test script supports various options:

```bash
# Basic load test (60s, 10 rps)
./scripts/load-test.sh

# Extended load test
./scripts/load-test.sh --duration 300 --rate 50 --concurrent 10

# Help
./scripts/load-test.sh --help
```

## Monitoring

### Traefik Metrics (via OTLP)
- Request rate by service, status code, method
- Response time percentiles (P50, P90, P95)
- Error rates (4xx, 5xx) with success rate
- Active connections and config reloads
- Request/response bytes throughput

### Kubernetes Metrics
- Node CPU/memory usage
- Pod CPU/memory usage and limits
- Container restarts
- Kubernetes events

### Application Metrics
- Node.js app with auto-instrumentation
- HTTP server request duration
- Automatic trace context propagation

## Troubleshooting

### Check component status:
```bash
# OpenTelemetry
kubectl get pods -n opentelemetry
kubectl logs -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector

# Traefik
kubectl get pods -n traefik
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Test apps
kubectl get pods -n demo
```

### Verify ingress:
```bash
# Test direct service access
kubectl port-forward -n demo svc/nodejs-app 3000:3000
curl http://localhost:3000

# Test ingress
curl -H "Host: nodejs.localhost" http://localhost
```

### Check OTLP export:
```bash
# Check collector logs for export status
kubectl logs -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector | grep -i export
```

## Cleanup

Remove the entire demo:
```bash
./01_cleanup.sh
```


## Configuration Files

- `kind/cluster.yaml` - Kind cluster configuration with ingress support
- `traefik/values.yaml` - Traefik Helm values with OTLP configuration
- `collector/*.yaml` - OpenTelemetry Collector configurations (DaemonSet & Deployment)
- `services/nodejs-app/` - Node.js demo application with auto-instrumentation

## References

- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Traefik Observability](https://doc.traefik.io/traefik/observe/overview/)
- [OpenTelemetry](https://opentelemetry.io/)
- [Dash0 Traefik Integration](https://www.dash0.com/hub/integrations/int_traefik/overview)
- [Kind Ingress](https://kind.sigs.k8s.io/docs/user/ingress)