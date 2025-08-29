FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies including OpenTelemetry
RUN npm install

# Copy application code
COPY src ./src

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

EXPOSE 3000

# Use NODE_OPTIONS to enable auto-instrumentation
ENV NODE_OPTIONS="--require @opentelemetry/auto-instrumentations-node/register"

CMD ["node", "src/index.js"]