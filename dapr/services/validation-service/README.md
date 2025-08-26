# Validation Service

A Java Spring Boot validation service with Dapr integration for the Todo application. This service validates todo names based on configurable rules and maintains validation history.

## Features

- **Validation Logic**: Configurable validation rules including length checks, forbidden words, and external API validation
- **Dapr State Store**: Persistent storage for validation rules and history
- **Dapr Bindings**: External API validation using Dapr bindings
- **REST API**: RESTful endpoints for validation operations
- **Health Checks**: Built-in health check endpoint
- **Comprehensive Logging**: Detailed logging with trace context support

## API Endpoints

### POST /validate
Validates a todo name based on current rules.

**Request:**
```json
{
  "name": "My Todo Item"
}
```

**Response:**
```json
{
  "valid": true,
  "message": "Todo name is valid"
}
```

### GET /rules
Gets current validation rules.

**Response:**
```json
{
  "minLength": 3,
  "maxLength": 100,
  "forbiddenWords": ["spam", "test123", "delete", "bad", "terrible", "awful"],
  "profanityCheck": true,
  "externalApiCheck": true
}
```

### PUT /rules
Updates validation rules.

**Request:**
```json
{
  "minLength": 5,
  "maxLength": 50,
  "forbiddenWords": ["spam", "bad"],
  "profanityCheck": true,
  "externalApiCheck": false
}
```

### GET /history
Gets validation history (last 50 entries).

**Response:**
```json
[
  {
    "name": "My Todo",
    "result": true,
    "reason": "Todo name is valid",
    "timestamp": "2024-01-15T10:30:00",
    "rules": { ... }
  }
]
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "UP",
  "service": "validation-service",
  "timestamp": "2024-01-15T10:30:00"
}
```

## Configuration

The service is configured via `application.properties`:

- **Port**: 8081
- **State Store**: `validation-statestore`
- **Binding**: `external-api-binding`
- **Dapr Sidecar**: localhost:3500

## Default Validation Rules

- **Minimum Length**: 3 characters
- **Maximum Length**: 100 characters
- **Forbidden Words**: spam, test123, delete, bad, terrible, awful
- **Profanity Check**: Enabled (placeholder)
- **External API Check**: Enabled

## State Store Usage

The service uses Dapr state store to persist:

- **Validation Rules**: Key `validation-rules`
- **Validation History**: Keys with pattern `validation-history-{timestamp}-{random}`

## Running the Service

### With Maven
```bash
./mvnw spring-boot:run
```

### With Docker
```bash
docker build -t validation-service .
docker run -p 8081:8081 validation-service
```

### With Dapr
```bash
dapr run --app-id validation-service --app-port 8081 --dapr-http-port 3500 -- java -jar target/validation-service-1.0.0.jar
```

## Building

```bash
./mvnw clean package
```

## Testing

```bash
./mvnw test
```

## Dependencies

- Spring Boot 3.2.5
- Java 17
- Dapr SDK 1.10.0
- Jackson for JSON processing
- Spring Boot Validation
- Spring Boot Actuator

## Environment Variables

The service logs OpenTelemetry environment variables at startup for debugging:

- `JAVA_TOOL_OPTIONS`
- `OTEL_SERVICE_NAME`
- `OTEL_PROPAGATORS`
- `OTEL_LOG_LEVEL`
- `OTEL_TRACES_EXPORTER`
- `OTEL_EXPORTER_OTLP_PROTOCOL`
- `OTEL_EXPORTER_OTLP_ENDPOINT`

## Error Handling

The service includes comprehensive error handling:

- Validation errors return appropriate HTTP status codes
- External service failures don't block validation
- State store failures are logged but don't fail requests
- All errors are logged with trace context when available