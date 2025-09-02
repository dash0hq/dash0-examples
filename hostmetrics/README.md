# Host Metrics Collection

Demonstrates collecting system metrics from Kubernetes nodes using OpenTelemetry Collector's hostmetrics receiver.

## What it does

- Creates a 2-node Kind cluster
- Deploys OpenTelemetry Collector as a DaemonSet on all nodes
- Collects host metrics (CPU, memory, disk, network, etc.)
- Exports metrics to Dash0

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

## Metrics Collected

The hostmetrics receiver collects:
- CPU (utilization, time per state)
- Memory (usage, available, utilization)
- Disk I/O (operations, bytes read/written)
- Filesystem (usage, utilization)
- Network (packets, bytes, errors, drops)
- System load
- Paging/swap statistics
- Process information

## View Logs

```bash
kubectl logs -n opentelemetry -l app.kubernetes.io/name=opentelemetry-collector --tail=50 -f
```

## Cleanup

```bash
./01_cleanup.sh
```