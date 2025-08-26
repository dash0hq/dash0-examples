import React from 'react';
import { TodoForm } from './components/TodoForm';
import { TodoList } from './components/TodoList';
import { ErrorDisplay } from './components/ErrorDisplay';
import { useTodos } from './hooks/useTodos';
import './App.css';

function App() {
  const { todos, isLoading, error, createTodo, deleteTodo } = useTodos();

  return (
    <div className="App">
      <header className="App-header">
        <div className="logo-section">
          <img src="/opentelemetry-logo.svg" alt="OpenTelemetry" className="otel-logo" />
          +
          <img src="/dapr-logo.svg" alt="Dapr" className="dapr-logo" />
        </div>
      </header>

      <main className="App-main">
        <div className="todo-container">
          <div className="todo-form-section">
            <h2>Add New Todo</h2>
            <TodoForm onSubmit={createTodo} isLoading={isLoading} />
            <ErrorDisplay error={error} />
          </div>

          <div className="todos-section">
            <TodoList 
              todos={todos} 
              onDelete={deleteTodo}
              isLoading={isLoading}
            />
          </div>
        </div>
      </main>
      
      <footer className="app-footer">
        <p>Crafted with ❤️ by <img src="/dash0-logo.svg" alt="Dash0" className="dash0-logo" /></p>
      </footer>
    </div>
  );
}

export default App;