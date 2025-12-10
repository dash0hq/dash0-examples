# Linkerd Demo with Dash0 Observability

This example demonstrates how to set up Linkerd service mesh with full observability using Dash0. It deploys the [emojivoto](https://github.com/BuoyantIO/emojivoto) demo application with Linkerd proxy injection and forwards metrics and traces to Dash0.

This demo uses the Linkerd edge release (`edge-25.12.1`) which includes native proxy tracing support, replacing the deprecated Linkerd-Jaeger extension.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/docs/intro/install/)
- [Linkerd CLI](https://linkerd.io/2.19/getting-started/#step-1-install-the-cli) (will be installed automatically if missing)
- Dash0 account with API credentials

## Configuration

Copy the `.env.template` file in the root directory to `.env` and configure it with your Dash0 credentials:

```bash
cp ../.env.template ../.env
```

Required environment variables:
- `DASH0_AUTH_TOKEN` - Your Dash0 authorization token
- `DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME` - Dash0 OTLP gRPC endpoint hostname
- `DASH0_ENDPOINT_OTLP_GRPC_PORT` - Dash0 OTLP gRPC endpoint port (default: 4317)

## Quick Start

Run the complete setup:

```bash
./00_run.sh
```

This will:
1. Create a Kind cluster with 3 nodes
2. Install Gateway API CRDs and Linkerd with native proxy tracing enabled
3. Install OpenTelemetry Collectors (in the Linkerd mesh)
4. Deploy the emojivoto demo application

### Application-Level Traces

The emojivoto deployment uses custom-built images (`kaspernissen/emojivoto-*:otel`) that include native OpenTelemetry SDK instrumentation. These images are built from the [main branch of emojivoto](https://github.com/BuoyantIO/emojivoto) which includes OpenTelemetry support that is not yet present in the released images.

**Why custom images are needed:**

The standard released emojivoto images do not include OpenTelemetry instrumentation or trace context header propagation. While Linkerd's proxy tracing works automatically, application-level traces require the application to:
1. Propagate trace context headers (like `traceparent`) between services
2. Export spans to an OTLP endpoint

The custom OTel-instrumented images provide both of these capabilities.

The deployment script configures:
- **Application traces**: Each service reports traces with its own service name (`web`, `emoji`, `voting`, `vote-bot`)
- **Linkerd proxy traces**: All proxies report traces as `linkerd-proxy` (custom proxy service naming is not currently supported in Linkerd's official configuration)

The application-level traces allow you to see the actual service behavior, while the proxy traces show the mesh-level network handling.

## Accessing the Demo

### Emojivoto Web UI

```bash
kubectl port-forward -n emojivoto svc/web-svc 8080:80 &
open http://localhost:8080
```

## What Gets Collected

### Metrics

The OpenTelemetry Collector scrapes Linkerd metrics including:

- **Control plane metrics** - Linkerd controller health and performance
- **Proxy metrics** - Per-pod sidecar proxy metrics
  - `request_total` - Total requests
  - `response_total` - Total responses
  - `response_latency_ms` - Response latency histogram
  - `route_*` - Route-level metrics
- **Service mirror metrics** - Multi-cluster metrics (if enabled)

### Traces

With tracing enabled (Linkerd 2.19+), distributed traces are collected showing:

- Service-to-service communication
- Request flow through the mesh
- Latency breakdown per service

## Cleanup

To delete the Kind cluster and all resources:

```bash
./01_cleanup.sh
```

## References

- [Linkerd Documentation](https://linkerd.io/2.19/)
- [Linkerd Distributed Tracing](https://linkerd.io/2.19/tasks/distributed-tracing/)
- [Emojivoto Demo](https://github.com/BuoyantIO/emojivoto)
- [Dash0 Documentation](https://www.dash0.com/documentation)
