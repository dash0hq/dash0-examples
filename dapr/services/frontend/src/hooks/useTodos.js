import { useState, useEffect, useCallback } from 'react';
import { todoAPI } from '../services/todoAPI';
import { MESSAGES } from '../utils/constants';

export const useTodos = () => {
  const [todos, setTodos] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');

  const loadTodos = useCallback(async () => {
    setIsLoading(true);
    setError('');
    
    try {
      const todosData = await todoAPI.getTodos();
      setTodos(Array.isArray(todosData) ? todosData : []);
    } catch (err) {
      console.error('Failed to load todos:', err);
      setError(`${MESSAGES.ERROR_LOAD}: ${err.message}`);
    } finally {
      setIsLoading(false);
    }
  }, []);

  const createTodo = useCallback(async (name) => {
    if (!name || !name.trim()) {
      throw new Error('Todo name is required');
    }

    setError('');
    try {
      const newTodo = await todoAPI.createTodo(name.trim());
      setTodos(prev => [...prev, newTodo]);
      return newTodo;
    } catch (err) {
      console.error('Failed to create todo:', err);
      const errorMessage = `${MESSAGES.ERROR_CREATE}: ${err.message}`;
      setError(errorMessage);
      throw new Error(errorMessage);
    }
  }, []);

  const deleteTodo = useCallback(async (id) => {
    if (!id) {
      throw new Error('Todo ID is required');
    }

    setError('');
    try {
      await todoAPI.deleteTodo(id);
      setTodos(prev => prev.filter(todo => todo.id !== id));
    } catch (err) {
      console.error('Failed to delete todo:', err);
      const errorMessage = `${MESSAGES.ERROR_DELETE}: ${err.message}`;
      setError(errorMessage);
      throw new Error(errorMessage);
    }
  }, []);

  useEffect(() => {
    loadTodos();
  }, [loadTodos]);

  return {
    todos,
    isLoading,
    error,
    loadTodos,
    createTodo,
    deleteTodo
  };
};