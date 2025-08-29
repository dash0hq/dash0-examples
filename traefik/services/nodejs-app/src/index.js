const express = require('express');
const axios = require('axios');

const app = express();
const port = process.env.PORT || 3000;
const serviceName = 'nodejs-app';

// Middleware
app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: serviceName,
    message: 'Hello from Node.js demo app!',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    headers: {
      'x-forwarded-for': req.headers['x-forwarded-for'],
      'x-real-ip': req.headers['x-real-ip'],
      'traceparent': req.headers['traceparent'],
      'tracestate': req.headers['tracestate']
    }
  });
});

// Error handling
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// Start server
app.listen(port, '0.0.0.0', () => {
  console.log(`${serviceName} listening on port ${port}`);
  console.log(`OTEL_SERVICE_NAME: ${process.env.OTEL_SERVICE_NAME}`);
  console.log(`OTEL_EXPORTER_OTLP_ENDPOINT: ${process.env.OTEL_EXPORTER_OTLP_ENDPOINT}`);
});