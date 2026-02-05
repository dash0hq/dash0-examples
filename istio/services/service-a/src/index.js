const express = require('express');
const os = require('os');
const http = require('http');

// Helper function for HTTP requests (auto-instrumented by OTel)
function httpRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const reqOptions = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname + urlObj.search,
      method: options.method || 'GET',
      headers: options.headers || {}
    };

    const req = http.request(reqOptions, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    });

    req.on('error', reject);
    if (options.body) req.write(options.body);
    req.end();
  });
}

const app = express();
const port = process.env.PORT || 3000;
const serviceName = 'service-a';

// Middleware
app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Root endpoint
app.get('/', (req, res) => {
  console.log(`${serviceName} - Processing request at root endpoint`);
  res.json({
    service: serviceName,
    message: 'Hello from service-a!',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    hostname: os.hostname(),
    headers: {
      'x-forwarded-for': req.headers['x-forwarded-for'],
      'x-real-ip': req.headers['x-real-ip'],
      'traceparent': req.headers['traceparent'],
      'tracestate': req.headers['tracestate'],
      'x-b3-traceid': req.headers['x-b3-traceid'],
      'x-b3-spanid': req.headers['x-b3-spanid']
    }
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: serviceName });
});

// API endpoint that returns data
app.get('/api/data', (req, res) => {
  res.json({
    message: 'Data from Node.js app',
    timestamp: new Date().toISOString(),
    hostname: os.hostname()
  });
});

// API endpoint that calls backend service (service mesh communication)
app.get('/api/backend', async (req, res) => {
  try {
    const backendUrl = process.env.BACKEND_URL || 'http://service-b.demo.svc.cluster.local:4000';
    console.log(`Calling backend service at: ${backendUrl}/info`);

    const response = await httpRequest(`${backendUrl}/info`);

    res.json({
      message: 'Data from backend via service mesh',
      frontend: os.hostname(),
      backend: response.data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error calling backend:', error);
    res.status(500).json({ error: 'Failed to call backend service', message: error.message });
  }
});

// API endpoint that processes data through backend
app.post('/api/process', async (req, res) => {
  try {
    const backendUrl = process.env.BACKEND_URL || 'http://service-b.demo.svc.cluster.local:4000';
    console.log(`Processing data through backend: ${backendUrl}/process`);

    const response = await httpRequest(`${backendUrl}/process`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(req.body)
    });

    res.json({
      message: 'Data processed by backend service',
      frontend: os.hostname(),
      result: response.data,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error processing through backend:', error);
    res.status(500).json({ error: 'Failed to process through backend', message: error.message });
  }
});

// Slow endpoint
app.get('/api/slow', async (req, res) => {
  const backendUrl = process.env.BACKEND_URL || 'http://service-b.demo.svc.cluster.local:4000';
  try {
    console.log(`Calling slow backend endpoint: ${backendUrl}/slow`);
    const response = await httpRequest(`${backendUrl}/slow`);
    res.json({
      message: 'Slow operation via backend',
      frontend: os.hostname(),
      backend: response.data
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Failed to call slow endpoint', message: error.message });
  }
});

// Error endpoint
app.get('/api/error', async (req, res) => {
  const backendUrl = process.env.BACKEND_URL || 'http://service-b.demo.svc.cluster.local:4000';
  try {
    console.log(`Calling error endpoint: ${backendUrl}/error`);
    const response = await httpRequest(`${backendUrl}/error`);
    res.status(response.status).json({
      message: 'Error from backend',
      frontend: os.hostname(),
      backend: response.data
    });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: 'Backend service error', message: error.message });
  }
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
