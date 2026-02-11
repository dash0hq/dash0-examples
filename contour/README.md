# Contour with OpenTelemetry

Demonstrates Contour ingress controller with OpenTelemetry metrics, tracing, and logs using a local observability stack and/or Dash0.

## What it does

- Creates a multi-node Kind cluster with Contour/Envoy
- Deploys local observability stack: Jaeger, Prometheus, and OpenSearch
- Configures OTLP metrics, distributed tracing, and JSON access logs
- Deploys OpenTelemetry Collectors (DaemonSet + Deployment) with dual export to Dash0 and local stack
- Includes Node.js demo application with auto-instrumentation
- Uses Gateway API with HTTPRoute for modern, standards-based routing

## Prerequisites

- Docker
- Kind
- kubectl
- Helm 3
- Optional: Dash0 account with API token

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

## Accessing Telemetry

The demo sends telemetry to both Dash0 (if configured) and a local observability stack for offline inspection.

### Dash0 (Optional)
If you configured Dash0 credentials, log in to your Dash0 dashboard to view:
- **Traces**: Filter by `service.name = "contour"` or `"envoy"`
- **Metrics**: Search for `envoy_*` and `contour_*` metrics
- **Logs**: Access logs with correlated trace IDs

### Local Observability Stack

**Jaeger (Traces):**
```bash
kubectl port-forward -n default svc/jaeger-query 16686:16686
```
Visit: http://localhost:16686

**Prometheus (Metrics):**
```bash
kubectl port-forward -n default svc/prometheus 9090:9090
```
Visit: http://localhost:9090

**OpenSearch Dashboards (Logs):**
```bash
kubectl port-forward -n default svc/opensearch-dashboards 5601:5601
```
Visit: http://localhost:5601
- Username: `admin`
- Password: `SecureP@ssw0rd123`

To view logs in OpenSearch Dashboards:
1. Navigate to "Discover" in the left menu
2. Create an index pattern: `otel-logs*`
3. Select `@timestamp` as the time field
4. Explore the logs with trace correlation

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