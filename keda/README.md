# KEDA Auto-scaling with Dash0

Demonstrates Kubernetes auto-scaling using KEDA with OpenTelemetry metrics exported to Dash0.

## Quick Start

1. **Prerequisites**
   - Docker, kubectl, helm, kind
   - Dash0 account with API access

2. **Configure credentials**
   ```bash
   cp ../env.template ../.env
   # Edit .env with your Dash0 credentials
   ```

3. **Run the demo**
   ```bash
   ./00_run.sh
   ```

4. **Test auto-scaling**
   ```bash
   ./scripts/generate_load.sh
   # Choose option 1 for HTTP scaling or option 2 for RabbitMQ scaling
   ```

5. **Watch scaling**
   ```bash
   kubectl get pods -n keda-demo -w
   ```

## Architecture

```
HTTP App ────┐                RabbitMQ Producer/Consumer
             │                         │
             ▼                         ▼
     OpenTelemetry SDK          OpenTelemetry SDK
             │                         │
             ▼                         ▼
     OpenTelemetry Collector ──────────┤
             │                         │
             ▼                         ▼
           Dash0 ◄─────────── RabbitMQ Metrics
             │
             ▼
        KEDA Operator
             │
             ▼
    Horizontal Pod Autoscaler
```

## Scaling Triggers

### HTTP Demo App
- **Trigger**: >1 request/second 
- **Scales**: 1 → 10 pods
- **Metrics**: `http.server.duration` rate

### RabbitMQ Consumer
- **Trigger**: >5 messages in queue
- **Scales**: 0 → 10 pods (scale-to-zero!)
- **Metrics**: RabbitMQ queue depth
- **Demo**: 600 messages processed in ~2 minutes

## Services

- **HTTP Test App**: `http://localhost:30000`
- **RabbitMQ Producer API**: `http://localhost:30001`
- **OpenTelemetry Collector**: Exports to Dash0
- **KEDA**: Uses OpenTelemetry metrics (not Prometheus scraping)

## Cleanup

```bash
./01_cleanup.sh
```