import React, { useState, useEffect } from 'react';
import { trace } from '@opentelemetry/api';
import './App.css';

const tracer = trace.getTracer('todo-frontend', '1.0.0');

function App() {
  const [todos, setTodos] = useState([]);
  const [newTodo, setNewTodo] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  // Load todos on component mount
  useEffect(() => {
    loadTodos();
  }, []);

  const loadTodos = async () => {
    const span = tracer.startSpan('load_todos');
    span.setAttributes({
      'user.action': 'load_todos',
      'component': 'TodoList'
    });

    try {
      setIsLoading(true);
      const response = await fetch('/todos');
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setTodos(data.content || []);
      span.addEvent('Todos loaded successfully');
      span.setAttributes({
        'todos.count': data.content ? data.content.length : 0
      });
    } catch (err) {
      console.error('Error loading todos:', err);
      setError('Failed to load todos');
      span.recordException(err);
      span.setStatus({ code: 2, message: err.message });
    } finally {
      setIsLoading(false);
      span.end();
    }
  };

  const createTodo = async (e) => {
    e.preventDefault();
    
    const span = tracer.startSpan('create_todo');
    span.setAttributes({
      'user.action': 'create_todo',
      'todo.name': newTodo,
      'todo.name.length': newTodo.length
    });

    try {
      setIsLoading(true);
      setError('');
      
      const response = await fetch('/todos', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: newTodo }),
      });

      if (response.ok) {
        const createdTodo = await response.json();
        setTodos(prev => [...prev, createdTodo]);
        setNewTodo('');
        span.addEvent('Todo created successfully');
        span.setAttributes({
          'todo.id': createdTodo.id,
          'operation.result': 'success'
        });
      } else {
        throw new Error('Failed to create todo - validation failed');
      }
    } catch (err) {
      console.error('Error creating todo:', err);
      setError(err.message);
      span.recordException(err);
      span.setStatus({ code: 2, message: err.message });
    } finally {
      setIsLoading(false);
      span.end();
    }
  };

  const deleteTodo = async (id) => {
    const span = tracer.startSpan('delete_todo');
    span.setAttributes({
      'user.action': 'delete_todo',
      'todo.id': id
    });

    try {
      setIsLoading(true);
      const response = await fetch(`/todos/${id}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        setTodos(prev => prev.filter(todo => todo.id !== id));
        span.addEvent('Todo deleted successfully');
        span.setAttributes({
          'operation.result': 'success'
        });
      } else {
        throw new Error('Failed to delete todo');
      }
    } catch (err) {
      console.error('Error deleting todo:', err);
      setError('Failed to delete todo');
      span.recordException(err);
      span.setStatus({ code: 2, message: err.message });
    } finally {
      setIsLoading(false);
      span.end();
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>
          <img src="/opentelemetry-logo.svg" alt="OpenTelemetry" className="otel-logo" />
        </h1>
        <p>A simple todo app demonstrating distributed tracing</p>
      </header>

      <main className="App-main">
        {error && <div className="error">{error}</div>}
        
        <form onSubmit={createTodo} className="todo-form">
          <input
            type="text"
            value={newTodo}
            onChange={(e) => setNewTodo(e.target.value)}
            placeholder="Enter a new todo..."
            disabled={isLoading}
            required
          />
          <button type="submit" disabled={isLoading || !newTodo.trim()}>
            {isLoading ? 'Adding...' : 'Add Todo'}
          </button>
        </form>

        <div className="todos-container">
          <h2>Todos ({todos.length})</h2>
          {isLoading && <p>Loading...</p>}
          
          {todos.length === 0 && !isLoading ? (
            <p className="no-todos">No todos yet. Add one above!</p>
          ) : (
            <ul className="todos-list">
              {todos.map(todo => (
                <li key={todo.id} className="todo-item">
                  <span className="todo-name">{todo.name}</span>
                  <button 
                    onClick={() => deleteTodo(todo.id)}
                    className="delete-btn"
                    disabled={isLoading}
                  >
                    Delete
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="demo-actions">
          <h3>Test Distributed Tracing:</h3>
          <button 
            onClick={() => {
              setNewTodo('This is bad content');
              setTimeout(() => createTodo({ preventDefault: () => {} }), 100);
            }}
            disabled={isLoading}
          >
            Try Invalid Todo (triggers validation)
          </button>
        </div>
      </main>
      
      <footer className="app-footer">
        <p>Crafted with ❤️ by <img src="/dash0-logo.svg" alt="Dash0" className="dash0-logo" /></p>
      </footer>
    </div>
  );
}

export default App;