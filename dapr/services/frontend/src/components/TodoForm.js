import React, { useState } from 'react';

export const TodoForm = ({ onSubmit, isLoading }) => {
  const [name, setName] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!name.trim()) {
      return;
    }

    try {
      await onSubmit(name);
      setName(''); // Clear form on success
    } catch (error) {
      // Error handling is managed by the parent component
      console.error('Form submission error:', error);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="todo-form">
      <div className="form-group">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Enter todo name"
          disabled={isLoading}
          className="todo-input"
          maxLength={100}
        />
        <button 
          type="submit" 
          disabled={isLoading || !name.trim()}
          className="add-button"
        >
          {isLoading ? 'Adding...' : 'Add Todo'}
        </button>
      </div>
    </form>
  );
};