FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY src/ ./src/

# Expose port
EXPOSE 4000

# Run the application with npm start (uses --require for auto-instrumentation)
CMD ["npm", "start"]
