const express = require('express');
const app = express();
const PORT = process.env.PORT || 4000;

app.use(express.json());

// Simulate processing data
function processData(data) {
  // Simulate some CPU work
  const start = Date.now();
  let result = 0;
  for (let i = 0; i < 100000; i++) {
    result += Math.sqrt(i);
  }
  const duration = Date.now() - start;

  return {
    processed: true,
    data: data,
    processingTime: duration,
    timestamp: new Date().toISOString()
  };
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'service-b' });
});

// Process data endpoint
app.post('/process', (req, res) => {
  console.log('Processing request:', req.body);
  const result = processData(req.body);
  res.json(result);
});

// Get backend info
app.get('/info', (req, res) => {
  console.log('service-b - Received info request');
  res.json({
    service: 'service-b',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptime: process.uptime(),
    memory: process.memoryUsage()
  });
});

// Simulate slow operation
app.get('/slow', (req, res) => {
  setTimeout(() => {
    res.json({
      message: 'Slow operation completed',
      delay: '1000ms'
    });
  }, 1000);
});

// Simulate error
app.get('/error', (req, res) => {
  console.error('Intentional error triggered');
  res.status(500).json({ error: 'Internal server error', message: 'This is a test error' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`service-b listening on port ${PORT}`);
  console.log(`OTEL_EXPORTER_OTLP_ENDPOINT: ${process.env.OTEL_EXPORTER_OTLP_ENDPOINT}`);
});
