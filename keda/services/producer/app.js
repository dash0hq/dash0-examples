const amqp = require('amqplib');
const express = require('express');

let connection;
let channel;
let messageCount = 0;

async function initRabbitMQ() {
  try {
    connection = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://guest:guest@rabbitmq.keda-demo.svc.cluster.local');
    channel = await connection.createChannel();
    
    const queue = 'work_queue';
    await channel.assertQueue(queue, { durable: true });
    console.log('Connected to RabbitMQ');
  } catch (error) {
    console.error('Error connecting to RabbitMQ:', error);
    setTimeout(initRabbitMQ, 5000);
  }
}

async function publishMessage(customMessage) {
  if (!channel) {
    throw new Error('RabbitMQ not connected');
  }
  
  const message = customMessage || `Work item ${messageCount++}`;
  channel.sendToQueue('work_queue', Buffer.from(message), { persistent: true });
  console.log('Published:', message);
  return message;
}

// Express API
const app = express();
app.use(express.json());

app.post('/publish', async (req, res) => {
  try {
    const message = await publishMessage(req.body.message);
    res.json({ success: true, message });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/burst', async (req, res) => {
  try {
    const count = req.body.count || 50;
    const messages = [];
    
    for (let i = 0; i < count; i++) {
      const message = await publishMessage(`Burst message ${i + 1}/${count}`);
      messages.push(message);
    }
    
    res.json({ 
      success: true, 
      count: messages.length,
      messages: messages.slice(0, 5) // Show first 5
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok', connected: !!channel });
});

// Start server
const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`Producer API listening on port ${port}`);
});

initRabbitMQ();