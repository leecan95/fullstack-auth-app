const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'cancaucacan',
  host: process.env.DB_HOST || 'postgre-db.craw4ikasnx6.ap-southeast-2.rds.amazonaws.com',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'auth_db',
  // Add SSL configuration
  ssl: {
    rejectUnauthorized: false // Set to true in production with proper certificates
  }
});

// Add connection error handling and logging
pool.on('error', (err) => {
  console.error('Unexpected database error:', err);
});

// Test connection on startup
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('Database connection error:', err);
  } else {
    console.log('Successfully connected to PostgreSQL database');
  }
});

module.exports = {
  query: (text, params) => pool.query(text, params)
};