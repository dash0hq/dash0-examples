// API Configuration
export const API_ENDPOINTS = {
  TODOS: '/v1.0/invoke/todo-service/method/todos'
};

// OpenTelemetry Configuration
export const OTEL_CONFIG = {
  SERVICE_NAME: 'frontend',
  SERVICE_VERSION: '1.0.0'
};

// UI Messages
export const MESSAGES = {
  LOADING: 'Loading todos...',
  NO_TODOS: 'No todos yet. Add one above!',
  ERROR_LOAD: 'Failed to load todos',
  ERROR_CREATE: 'Failed to create todo',
  ERROR_DELETE: 'Failed to delete todo'
};