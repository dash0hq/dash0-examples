# Traefik Demo with Observability

This demo sets up a complete Traefik ingress controller environment with full observability using OpenTelemetry and Dash0.

## Features

- Multi-node Kind cluster with ingress support
- Traefik v3.6.7 as ingress controller with OTLP observability
- OpenTelemetry Collector (DaemonSet + Deployment)
- OTLP metrics, tracing, and logs from Traefik (HTTP/gRPC endpoints)
- Direct OTLP log export with automatic trace correlation
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
   ./scripts/load-test.sh
   ```

## Load Testing

Simple load testing script that generates 60 seconds of traffic at 10 RPS:

```bash
./scripts/load-test.sh
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