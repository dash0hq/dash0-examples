# Todo Service with Dapr

A Java Spring Boot application for managing todos with Dapr integration.

## Features

- **CRUD Operations**: Create, read, update, and delete todos
- **Dapr State Store**: Persistent storage using Dapr state store (`todo-statestore`)
- **Dapr PubSub**: Event publishing for todo operations (`todo-pubsub`)
- **Service Invocation**: Validation service integration via Dapr
- **REST API**: RESTful endpoints for todo management
- **Health Checks**: Built-in health monitoring
- **Docker Support**: Containerized deployment

## API Endpoints

- `GET /todos` - Get all todos
- `GET /todos/{id}` - Get a specific todo
- `POST /todos` - Create a new todo
- `PUT /todos/{id}` - Update todo (toggle completed status)
- `DELETE /todos/{id}` - Delete a todo
- `GET /todos/health` - Health check endpoint

## Requirements

- Java 17
- Maven 3.9+
- Dapr runtime

## Configuration

The application requires the following Dapr components:
- State store named `todo-statestore`
- PubSub component named `todo-pubsub`
- Validation service with app-id `validation-service`

## Building and Running

### Local Development
```bash
# Build the application
./mvnw clean package

# Run with Dapr
dapr run --app-id todo-service --app-port 8080 --dapr-http-port 3500 -- java -jar target/todo-service-1.0.0.jar
```

### Docker
```bash
# Build Docker image
docker build -t todo-service:latest .

# Run with Docker
docker run -p 8080:8080 todo-service:latest
```

## Environment Variables

- `SERVER_PORT`: Application port (default: 8080)
- `DAPR_HTTP_PORT`: Dapr HTTP port (default: 3500)
- `DAPR_GRPC_PORT`: Dapr gRPC port (default: 50001)

## Health Monitoring

The service includes Spring Boot Actuator endpoints:
- `/actuator/health` - Application health
- `/actuator/metrics` - Application metrics
- `/actuator/prometheus` - Prometheus metrics