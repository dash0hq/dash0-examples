# KEDA Auto-scaling with Dash0

Demonstrates Kubernetes auto-scaling using KEDA with metrics from Dash0.

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
   ```

5. **Watch scaling**
   ```bash
   kubectl get pods -n keda-demo -w
   ```

## How it Works

```
App → OpenTelemetry SDK → Collector → Dash0
                                         ↓
KEDA ← Prometheus API ← ← ← ← ← ← ← ← ← ←
  ↓
HPA → Scale Pods
```

1. **App sends metrics** via OpenTelemetry SDK
2. **Collector forwards** to Dash0
3. **KEDA queries** Dash0's Prometheus API
4. **Scales based on**:
   - HTTP request rate (>10 req/s)
   - Queue size (>30 items)

## Cleanup

```bash
./01_cleanup.sh
```