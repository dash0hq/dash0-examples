const express = require('express');
const { metrics } = require('@opentelemetry/api');

const app = express();
const port = 8080;

// Create OpenTelemetry metrics for custom business logic
const meter = metrics.getMeter('keda-demo-app', '1.0.0');

const queueSize = meter.createUpDownCounter('app_processing_queue_size', {
  description: 'Items in processing queue',
});

let currentQueueSize = 0;

app.use(express.json());

// Main endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'keda-demo-app',
    endpoints: ['/simulate-load', '/queue-status', '/health', '/ready']
  });
});

// Add load to queue
app.post('/simulate-load', (req, res) => {
  const items = req.body.items || 100;
  
  currentQueueSize += items;
  queueSize.add(items, { service: 'keda-demo-app' });
  
  // Process after 30 seconds
  setTimeout(() => {
    currentQueueSize = Math.max(0, currentQueueSize - items);
    queueSize.add(-items, { service: 'keda-demo-app' });
  }, 30000);
  
  res.json({ added: items, queueSize: currentQueueSize });
});

// Check queue status
app.get('/queue-status', (req, res) => {
  res.json({ queueSize: currentQueueSize });
});

// Health check endpoints
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

app.get('/ready', (req, res) => {
  res.json({ status: 'ready', timestamp: new Date().toISOString() });
});

app.listen(port, () => {
  console.log(`App running on port ${port}`);
  console.log(`Sending metrics to: ${process.env.OTEL_EXPORTER_OTLP_ENDPOINT}`);
});