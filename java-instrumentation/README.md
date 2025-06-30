# Java Instrumentation Example

This example demonstrates how to instrument Java applications using OpenTelemetry auto-instrumentation and send telemetry data to Dash0. The example includes a multi-service application with a frontend, todo service, and validation service.

## Prerequisites

- **Docker and Docker Compose**: For running the example locally
- **Kubernetes cluster (optional)**: For running on Kubernetes (kind cluster will be created automatically)
- **Helm (for Kubernetes)**: Required for Kubernetes deployment
- **Dash0 account**: Sign up at [dash0.com](https://www.dash0.com) to get your authentication token

## Setup

1. **Configure environment variables**: Copy the `.env.template` file to `.env` in the parent directory and configure your Dash0 settings:
   ```bash
   cp ../.env.template ../.env
   ```

2. **Edit the `.env` file** with your Dash0 credentials:
   ```bash
   # You can get this data from Dash0's settings screens
   DASH0_AUTH_TOKEN="your_auth_token_here"
   DASH0_DATASET="default"
   DASH0_ENDPOINT_OTLP_GRPC_HOSTNAME="ingress.eu-west-1.aws.dash0.com"
   DASH0_ENDPOINT_OTLP_GRPC_PORT="4317"
   DASH0_ENDPOINT_OTLP_HTTP_HOSTNAME="ingress.eu-west-1.aws.dash0.com"
   DASH0_ENDPOINT_OTLP_HTTP_PORT="443"
   ```

## Running with Docker Compose

Execute the setup script to start all services:

```bash
./00_run_docker_compose.sh
```

This script will:
- Load environment variables from `../.env`
- Start the OpenTelemetry collector, observability tools (Prometheus, Jaeger, OpenSearch), and database
- Build and run the Java services with auto-instrumentation enabled
- Start the React frontend

### Services and Ports

Once running, the following services will be available:

- **Frontend**: http://localhost:3002 - React application for managing todos
- **Todo Service**: http://localhost:3000 - Java Spring Boot REST API
- **Validation Service**: http://localhost:3001 - Java Spring Boot validation service
- **Jaeger UI**: http://localhost:16686 - Distributed tracing visualization
- **Prometheus**: http://localhost:9090 - Metrics collection and querying
- **OpenSearch Dashboards**: http://localhost:5601 - Log analysis and visualization
- **MySQL**: localhost:3306 - Database for todo storage

## Running on Kubernetes

Execute the Kubernetes setup script to deploy on a kind cluster:

```bash
./01_run_kubernetes.sh
```

This script will:
- Create a multi-node kind cluster named `java-instrumentation`
- Deploy MySQL, Jaeger, Prometheus, and OpenSearch using Helm
- Install the OpenTelemetry Operator
- Deploy the OpenTelemetry Collector
- Apply auto-instrumentation configuration
- Deploy all application services

To access services in Kubernetes, use port-forwarding:

```bash
# Access frontend
kubectl port-forward svc/frontend 3000:80

# Access Jaeger UI
kubectl port-forward svc/jaeger-query 16686:16686

# Access Prometheus
kubectl port-forward svc/prometheus 9090:9090
```

## Testing the Application

1. **Open the frontend**: Navigate to http://localhost:3000
2. **Create todos**: Add new todo items using the web interface
3. **View telemetry**: 
   - Check traces in Jaeger: http://localhost:16686
   - View metrics in Prometheus: http://localhost:9090
   - Analyze logs in OpenSearch Dashboards: http://localhost:5601
   - Monitor telemetry in Dash0 

## Architecture

The example consists of:

- **Frontend (React)**: User interface with browser-based OpenTelemetry instrumentation
- **Todo Service (Java/Spring Boot)**: Main API service with automatic OpenTelemetry instrumentation
- **Validation Service (Java/Spring Boot)**: Microservice for validating todo items
- **OpenTelemetry Collector**: Processes and forwards telemetry data to Dash0 and local tools
- **MySQL**: Database for persistent storage

The Java services are automatically instrumented using the OpenTelemetry Java agent, which captures:
- HTTP requests and responses
- Database queries and connections
- Service-to-service communication
- JVM metrics
- Custom application metrics and traces

## Cleanup

### Docker Compose
```bash
docker-compose down -v
```

### Kubernetes
```bash
kind delete cluster --name=java-instrumentation
```