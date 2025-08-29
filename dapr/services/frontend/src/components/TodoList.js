import React, { useState } from 'react';
import { TodoItem } from './TodoItem';
import { MESSAGES } from '../utils/constants';

export const TodoList = ({ todos, onDelete, isLoading }) => {
  const [deletingIds, setDeletingIds] = useState(new Set());

  const handleDelete = async (id) => {
    setDeletingIds(prev => new Set([...prev, id]));
    
    try {
      await onDelete(id);
    } catch (error) {
      // Error is handled by parent component
      console.error('Delete error:', error);
    } finally {
      setDeletingIds(prev => {
        const newSet = new Set(prev);
        newSet.delete(id);
        return newSet;
      });
    }
  };

  if (isLoading && todos.length === 0) {
    return (
      <div className="todo-list-container">
        <div className="loading-message">{MESSAGES.LOADING}</div>
      </div>
    );
  }

  if (todos.length === 0) {
    return (
      <div className="todo-list-container">
        <div className="empty-message">{MESSAGES.NO_TODOS}</div>
      </div>
    );
  }

  return (
    <div className="todo-list-container">
      <h2>Your Todos ({todos.length})</h2>
      <ul className="todo-list">
        {todos.map(todo => (
          <TodoItem
            key={todo.id}
            todo={todo}
            onDelete={handleDelete}
            isDeleting={deletingIds.has(todo.id)}
          />
        ))}
      </ul>
    </div>
  );
};