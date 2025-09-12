const express = require('express');

const app = express();
const port = 8080;

// Main endpoint that generates HTTP traffic metrics
app.get('/', (req, res) => {
  res.json({
    service: 'http-app',
    message: 'Hello from KEDA demo!',
    timestamp: new Date().toISOString()
  });
});

// Health check endpoints
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/ready', (req, res) => {
  res.json({ status: 'ready', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`HTTP demo app running on port ${port}`);
  console.log(`Sending metrics to: ${process.env.OTEL_EXPORTER_OTLP_ENDPOINT}`);
});