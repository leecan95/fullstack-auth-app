require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const app = express();

// Debug environment variables immediately after loading
console.log('Environment variables loaded:');
console.log('PORT:', process.env.PORT);
console.log('DB_HOST:', process.env.DB_HOST);
console.log('JWT_SECRET exists:', !!process.env.JWT_SECRET);
console.log('JWT_SECRET length:', process.env.JWT_SECRET ? process.env.JWT_SECRET.length : 0);

// Check for JWT_SECRET and set a default if missing
if (!process.env.JWT_SECRET) {
  console.warn('WARNING: JWT_SECRET not found in environment variables. Using a temporary secret.');
  process.env.JWT_SECRET = 'temporary_secret_key_' + Math.random().toString(36).substring(2);
  console.log('Temporary JWT_SECRET set:', process.env.JWT_SECRET);
}

const authRoutes = require('./routes/auth');
const db = require('./db');

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);

// Base route
app.get('/', (req, res) => {
  res.send('Auth API is running');
});

// Start server
const port = process.env.PORT || 5001;
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});