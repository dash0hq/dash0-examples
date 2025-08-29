import React from 'react';

export const TodoItem = ({ todo, onDelete, isDeleting }) => {
  const handleDelete = () => {
    onDelete(todo.id);
  };

  return (
    <li className="todo-item">
      <div className="todo-content">
        <span className="todo-name">{todo.name}</span>
        <div className="todo-meta">
          <small className="todo-date">
            Created: {new Date(todo.createdAt).toLocaleString()}
          </small>
          {todo.id && (
            <small className="todo-id">
              ID: {todo.id.substring(0, 8)}...
            </small>
          )}
        </div>
      </div>
      <button
        onClick={handleDelete}
        disabled={isDeleting}
        className="delete-button"
        title={`Delete ${todo.name}`}
      >
        {isDeleting ? '...' : '×'}
      </button>
    </li>
  );
};