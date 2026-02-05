# Istio Service Mesh with OpenTelemetry

An Istio service mesh demo with full observability using OpenTelemetry and Dash0.

## What it does

- Creates a multi-node Kind cluster with Istio service mesh (1.28.3)
- Deploys local observability stack: Jaeger, Prometheus, and OpenSearch
- Configures OTLP distributed tracing and access logs from Envoy sidecars
- Deploys OpenTelemetry Collectors with dual export to Dash0 and local stack
- Includes two-service demo with service-to-service communication through mesh
- Uses Istio Gateway and VirtualService for traffic management

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
   ./00_run.sh
   ```

3. **Access the gateway:**
   ```bash
   kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80
   ```

4. **Test the application:**
   ```bash
   # Test frontend
   curl -H 'Host: service-a.dash0-examples.com' http://localhost:8080/

   # Test service mesh communication (service-a → service-b)
   curl -H 'Host: service-a.dash0-examples.com' http://localhost:8080/api/backend
   ```

## Accessing Telemetry

The demo sends telemetry to both Dash0 (primary cloud backend) and a local observability stack for offline inspection.

### Dash0 (Primary)
Log in to your Dash0 dashboard to view:
- **Traces**: Filter by `service.name = "istio-ingressgateway"` or `"service-a"`
- **Metrics**: Search for `istio_*` and `envoy_*` metrics
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

## Cleanup

```bash
./01_cleanup.sh
```

## References

- [Istio Documentation](https://istio.io/)
- [Istio OpenTelemetry Integration](https://istio.io/latest/docs/tasks/observability/distributed-tracing/opentelemetry/)
- [OpenTelemetry](https://opentelemetry.io/)
- [Dash0](https://www.dash0.com/)
