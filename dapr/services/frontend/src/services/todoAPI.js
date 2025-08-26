import { trace } from '@opentelemetry/api';
import { API_ENDPOINTS, OTEL_CONFIG } from '../utils/constants';

class TodoAPI {
  constructor() {
    this.tracer = trace.getTracer(OTEL_CONFIG.SERVICE_NAME, OTEL_CONFIG.SERVICE_VERSION);
  }

  async getTodos() {
    const span = this.tracer.startSpan('fetch_todos');
    
    try {
      span.setAttributes({
        'http.method': 'GET',
        'http.url': API_ENDPOINTS.TODOS,
        'operation': 'fetch_todos'
      });
      
      const response = await fetch(API_ENDPOINTS.TODOS, {
        headers: this.injectTraceHeaders()
      });
      
      span.setAttributes({
        'http.status_code': response.status,
        'http.response_size': response.headers.get('content-length') || 0
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const todos = await response.json();
      span.setAttributes({
        'todos.count': todos.length
      });
      
      span.addEvent('todos_fetched', {
        count: todos.length
      });
      
      return todos;
    } catch (error) {
      span.recordException(error);
      span.setStatus({
        code: trace.SpanStatusCode.ERROR,
        message: error.message
      });
      throw error;
    } finally {
      span.end();
    }
  }

  async createTodo(name) {
    const span = this.tracer.startSpan('create_todo');
    
    try {
      span.setAttributes({
        'http.method': 'POST',
        'http.url': API_ENDPOINTS.TODOS,
        'todo.name': name,
        'operation': 'create_todo'
      });
      
      const response = await fetch(API_ENDPOINTS.TODOS, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...this.injectTraceHeaders()
        },
        body: JSON.stringify({ name })
      });
      
      span.setAttributes({
        'http.status_code': response.status,
        'http.response_size': response.headers.get('content-length') || 0
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      const newTodo = await response.json();
      span.setAttributes({
        'todo.id': newTodo.id
      });
      
      span.addEvent('todo_created', {
        id: newTodo.id,
        name: newTodo.name
      });
      
      return newTodo;
    } catch (error) {
      span.recordException(error);
      span.setStatus({
        code: trace.SpanStatusCode.ERROR,
        message: error.message
      });
      throw error;
    } finally {
      span.end();
    }
  }

  async deleteTodo(id) {
    const span = this.tracer.startSpan('delete_todo');
    
    try {
      span.setAttributes({
        'http.method': 'DELETE',
        'http.url': `${API_ENDPOINTS.TODOS}/${id}`,
        'todo.id': id,
        'operation': 'delete_todo'
      });
      
      const response = await fetch(`${API_ENDPOINTS.TODOS}/${id}`, {
        method: 'DELETE',
        headers: this.injectTraceHeaders()
      });
      
      span.setAttributes({
        'http.status_code': response.status
      });
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      
      span.addEvent('todo_deleted', {
        id: id
      });
      
    } catch (error) {
      span.recordException(error);
      span.setStatus({
        code: trace.SpanStatusCode.ERROR,
        message: error.message
      });
      throw error;
    } finally {
      span.end();
    }
  }

  injectTraceHeaders() {
    const headers = {};
    
    try {
      const activeSpan = trace.getActiveSpan();
      if (activeSpan) {
        const spanContext = activeSpan.spanContext();
        if (spanContext.traceId && spanContext.spanId) {
          headers['traceparent'] = `00-${spanContext.traceId}-${spanContext.spanId}-01`;
        }
      }
    } catch (error) {
      console.warn('Failed to inject trace headers:', error);
    }
    
    return headers;
  }
}

export const todoAPI = new TodoAPI();