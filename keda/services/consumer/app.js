const amqp = require('amqplib');

async function consume() {
  try {
    const connection = await amqp.connect(process.env.RABBITMQ_URL || 'amqp://guest:guest@rabbitmq.keda-demo.svc.cluster.local');
    const channel = await connection.createChannel();
    
    const queue = 'work_queue';
    await channel.assertQueue(queue, { durable: true });
    
    // Set prefetch to 1 to distribute work evenly
    channel.prefetch(1);
    
    console.log('Waiting for messages...');
    
    channel.consume(queue, (msg) => {
      if (msg) {
        const content = msg.content.toString();
        console.log('Received:', content);
        
        // Simulate processing (2 seconds)
        const processingTime = 2000;
        setTimeout(() => {
          console.log('Processed:', content);
          channel.ack(msg);
        }, processingTime);
      }
    });
    
  } catch (error) {
    console.error('Error:', error);
    setTimeout(consume, 5000);
  }
}

consume();