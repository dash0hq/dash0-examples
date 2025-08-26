import { API_ENDPOINTS } from '../utils/constants';

class TodoAPI {
  async getTodos() {
    const response = await fetch(API_ENDPOINTS.TODOS);
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    return response.json();
  }

  async createTodo(name) {
    const response = await fetch(API_ENDPOINTS.TODOS, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ name })
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
    
    return response.json();
  }

  async deleteTodo(id) {
    const response = await fetch(`${API_ENDPOINTS.TODOS}/${id}`, {
      method: 'DELETE'
    });
    
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }
  }
}

export const todoAPI = new TodoAPI();