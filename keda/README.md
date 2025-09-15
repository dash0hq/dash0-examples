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
           Dash0 ◄─── RabbitMQ Operator (guest/guest)
             │
             ▼
        KEDA Operator (queries Dash0 via Prometheus API)
             │
             ▼
    Horizontal Pod Autoscaler
```

## Scaling Triggers

### HTTP Demo App
- **Trigger**: >1 request/second from Dash0 metrics
- **Scales**: 1 → 10 pods
- **Metrics Source**: Dash0 Prometheus API (`http.server.duration` rate)
- **Authentication**: Bearer token via TriggerAuthentication

### RabbitMQ Consumer
- **Trigger**: >5 messages in queue
- **Scales**: 0 → 10 pods (scale-to-zero!)
- **Connection**: Direct RabbitMQ connection (`guest:guest@rabbitmq.keda-demo.svc.cluster.local`)
- **Queue**: `work_queue` with durable persistence

## Services

- **HTTP Test App**: `http://localhost:30000` (scales based on request rate)
- **RabbitMQ Producer API**: `http://localhost:30001` (publishes messages to trigger scaling)
  - `POST /publish` - Send single message
  - `POST /burst` - Send multiple messages (`{"count": N}`)
- **RabbitMQ Management UI**: `http://localhost:31672` (guest/guest)
- **OpenTelemetry Collector**: Exports metrics to Dash0 via OTLP
- **KEDA**: 
  - HTTP scaling via Dash0 Prometheus API
  - RabbitMQ scaling via direct AMQP connection

## Cleanup

```bash
./01_cleanup.sh
```