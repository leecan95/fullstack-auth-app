require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const app = express();
const authRoutes = require('./routes/auth');
const db = require('./db');

// Debug environment variables
console.log('Environment variables loaded:');
console.log('PORT:', process.env.PORT);
console.log('DB_HOST:', process.env.DB_HOST);
console.log('JWT_SECRET exists:', !!process.env.JWT_SECRET);
console.log('JWT_SECRET length:', process.env.JWT_SECRET ? process.env.JWT_SECRET.length : 0);

// Verify JWT_SECRET is set
if (!process.env.JWT_SECRET) {
  console.error('ERROR: JWT_SECRET is not set in environment variables');
  console.error('Please make sure your .env file contains JWT_SECRET');
  
  // Create a new JWT_SECRET if it doesn't exist
  process.env.JWT_SECRET = require('crypto').randomBytes(32).toString('hex');
  console.log('Generated a temporary JWT_SECRET for this session');
} else {
  console.log('JWT_SECRET is properly configured');
}

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