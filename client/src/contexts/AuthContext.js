import React, { createContext, useState, useContext, useEffect } from 'react';
import axios from 'axios';

// API base URL - for production deployment
const API_URL = 'http://localhost:5001/api';

const AuthContext = createContext();

export function useAuth() {
  return useContext(AuthContext);
}

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  // Check if user is logged in when the app loads
  useEffect(() => {
    const token = localStorage.getItem('token');
    
    if (token) {
      // Set auth header
      axios.defaults.headers.common['x-auth-token'] = token;
      
      // Fetch user profile
      const fetchUser = async () => {
        try {
          const res = await axios.get(`${API_URL}/auth/profile`);  // Removed duplicate /api
          setCurrentUser(res.data);
          setIsAuthenticated(true);
        } catch (err) {
          console.error('Error fetching user:', err);
          localStorage.removeItem('token');
          delete axios.defaults.headers.common['x-auth-token'];
        } finally {
          setLoading(false);
        }
      };
      
      fetchUser();
    } else {
      setLoading(false);
    }
  }, []);

  // Register user
  const register = async (username, email, password) => {
    try {
      const res = await axios.post(`${API_URL}/auth/register`, {  // Removed duplicate /api
        username,
        email,
        password
      });
      
      // Set token in local storage
      localStorage.setItem('token', res.data.token);
      
      // Set auth header
      axios.defaults.headers.common['x-auth-token'] = res.data.token;
      
      setCurrentUser(res.data.user);
      setIsAuthenticated(true);
      
      return res.data;
    } catch (err) {
      throw err.response.data;
    }
  };

  // Login user
  const login = async (email, password) => {
    try {
      const res = await axios.post(`${API_URL}/auth/login`, {  // Removed duplicate /api
        email,
        password
      });
      
      // Set token in local storage
      localStorage.setItem('token', res.data.token);
      
      // Set auth header
      axios.defaults.headers.common['x-auth-token'] = res.data.token;
      
      setCurrentUser(res.data.user);
      setIsAuthenticated(true);
      
      return res.data;
    } catch (err) {
      throw err.response.data;
    }
  };

  // Logout user
  const logout = () => {
    // Remove token from local storage
    localStorage.removeItem('token');
    
    // Remove auth header
    delete axios.defaults.headers.common['x-auth-token'];
    
    setCurrentUser(null);
    setIsAuthenticated(false);
  };

  const value = {
    currentUser,
    isAuthenticated,
    loading,
    login,
    register,
    logout
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};