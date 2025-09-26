# Emissary-ingress Demo with OpenTelemetry Observability

This demo demonstrates Emissary-ingress with complete OpenTelemetry observability integration using Dash0.

## Prerequisites

- Docker
- Kind
- kubectl
- Helm 3
- Dash0 account with API token
- bc (for load testing calculations)

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

3. **Access services:**
   ```bash
   # Port-forward to access the demo application
   kubectl port-forward svc/emissary-ingress -n emissary 8080:80 &

   # Test the application
   curl -H "Host: node.dash0-examples.com" http://localhost:8080/

   # Access admin interface
   kubectl port-forward svc/emissary-ingress-admin -n emissary 8877:8877 &
   # Visit: http://localhost:8877/
   ```

5. **Generate load:**
   ```bash
   ./scripts/load-test.sh
   ```

## Cleanup

Remove the entire demo:
```bash
./01_cleanup.sh
```

## References

- [Emissary-ingress Documentation](https://www.getambassador.io/docs/emissary)
- [Emissary-ingress Observability](https://www.getambassador.io/docs/emissary/latest/topics/running/statistics)
- [OpenTelemetry](https://opentelemetry.io/)
- [Dash0 Documentation](https://www.dash0.com/docs)
- [Kind Ingress](https://kind.sigs.k8s.io/docs/user/ingress)