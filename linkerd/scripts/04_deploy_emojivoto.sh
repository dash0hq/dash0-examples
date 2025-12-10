#!/bin/bash
# Deploy the emojivoto demo application with Linkerd injection
set -e

echo "Deploying Emojivoto"

kubectl cluster-info &>/dev/null || { echo "Error: Cannot connect to cluster"; exit 1; }
linkerd check &>/dev/null || { echo "Error: Linkerd not installed"; exit 1; }

echo "Deploying with Linkerd injection..."
curl -sL https://run.linkerd.io/emojivoto.yml | linkerd inject - | kubectl apply -f - >/dev/null

echo "Waiting for initial pods..."
for deploy in web emoji voting vote-bot; do
    kubectl -n emojivoto rollout status deploy/$deploy --timeout=120s >/dev/null
done

echo "Configuring OTel-instrumented images and tracing..."
# Update images and env vars together, then restart once
kubectl -n emojivoto set image deploy/web web-svc=kaspernissen/emojivoto-web:otel >/dev/null
kubectl -n emojivoto set image deploy/emoji emoji-svc=kaspernissen/emojivoto-emoji-svc:otel >/dev/null
kubectl -n emojivoto set image deploy/voting voting-svc=kaspernissen/emojivoto-voting-svc:otel >/dev/null
kubectl -n emojivoto set image deploy/vote-bot vote-bot=kaspernissen/emojivoto-web:otel >/dev/null

kubectl -n emojivoto set env --all deploy \
    OTEL_EXPORTER_OTLP_ENDPOINT=otel-collector-opentelemetry-collector.opentelemetry:4317 \
    OTEL_EXPORTER_OTLP_PROTOCOL=grpc >/dev/null

kubectl -n emojivoto set env deploy/web OTEL_SERVICE_NAME=web >/dev/null
kubectl -n emojivoto set env deploy/emoji OTEL_SERVICE_NAME=emoji >/dev/null
kubectl -n emojivoto set env deploy/voting OTEL_SERVICE_NAME=voting >/dev/null
kubectl -n emojivoto set env deploy/vote-bot OTEL_SERVICE_NAME=vote-bot >/dev/null

# Force restart to ensure all changes are applied together
echo "Restarting pods with new configuration..."
kubectl -n emojivoto rollout restart deploy/web deploy/emoji deploy/voting deploy/vote-bot >/dev/null

echo "Waiting for pods..."
for deploy in web emoji voting vote-bot; do
    kubectl -n emojivoto rollout status deploy/$deploy --timeout=120s >/dev/null
done

echo "Emojivoto deployed!"
kubectl get pods -n emojivoto
