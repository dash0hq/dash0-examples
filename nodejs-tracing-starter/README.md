# Distributed Tracing in Node.js with OpenTelemetry

A two-service URL shortener (Snip) instrumented with
OpenTelemetry to demonstrate distributed tracing in Node.js,
covering:

- Zero-code auto-instrumentation with the Node.js SDK.
- Programmatic SDK customization for span naming.
- Manual spans for business logic with error handling.
- Enriching auto-instrumented spans with custom attributes.
- Using traces to find N+1 queries and cache bugs.

**Full tutorial**:
[Distributed Tracing in Node.js with OpenTelemetry](https://www.dash0.com/guides/distributed-tracing-nodejs-opentelemetry)

## Prerequisites

- Docker and Docker Compose

## Getting started

1. Clone the repo and change into the project directory:

```bash
git clone https://github.com/dash0hq/dash0-examples/nodejs-tracing-starter.git \
  && cd nodejs-tracing-starter
```

2. Copy the example environment file:

```bash
mv .env.example .env
```

3. Bring up the services:

```bash
docker compose up -d --build
```

4. Open `http://localhost:3000` in your browser to use the
   Snip UI.

5. Read and follow the [tutorial](https://www.dash0.com/guides/distributed-tracing-nodejs-opentelemetry) to set up tracing.
