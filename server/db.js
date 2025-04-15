const { Pool } = require('pg');

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'cancaucacan',
  host: process.env.DB_HOST || 'postgre-db.craw4ikasnx6.ap-southeast-2.rds.amazonaws.com',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'auth_db'
});

module.exports = {
  query: (text, params) => pool.query(text, params)
}; 