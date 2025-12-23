# Kagent Demo with Dash0 Observability

This demo sets up [kagent](https://kagent.dev) with OpenTelemetry tracing, exporting traces to Dash0. It uses a local Ollama instance for LLM inference (with Metal GPU acceleration on Mac).


## Setup

1. **Start Ollama locally** (uses Metal GPU on Mac):

```bash
ollama serve
```

2. **Pull a model** (recommended: gpt-oss:20b for best results):

```bash
ollama pull gpt-oss:20b
```

3. **Configure Dash0 credentials:**

```bash
cp ../.env.template ../.env
```

Edit `../.env` and set:
- `DASH0_AUTH_TOKEN` - Your Dash0 authorization token
- `DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME` - Dash0 OTLP endpoint
- `DASH0_ENDPOINT_OTLP_GRPC_PORT` - Dash0 OTLP port (usually 4317)

4. **Run the setup script:**

```bash
./00_run.sh
```

## Accessing kagent

After installation, port-forward to access the kagent UI:

```bash
kubectl port-forward svc/kagent-ui -n kagent 8080:8080
```

Then open http://localhost:8080

## Changing the Model

To use a different Ollama model, edit `modelconfig.yaml`:

```yaml
spec:
  model: llama3.2:3b  # or any other Ollama model
  provider: Ollama
  ollama:
    host: http://host.docker.internal:11434
```

Then apply:

```bash
kubectl apply -f modelconfig.yaml
```

## Cleanup

To delete the demo cluster:

```bash
./01_cleanup.sh
```