const mysql = require('mysql2/promise');
require('dotenv').config();

let pool;

// Setup test database connection
function setupTestDb() {
  const testDbName = `${process.env.DB_NAME}_test`;
  
  pool = mysql.createPool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: testDbName,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
  });

  return pool;
}

// Clean all tables
async function cleanDatabase() {
  if (!pool) {
    throw new Error('Database pool not initialized. Call setupTestDb() first.');
  }

  try {
    // Disable FK checks
    await pool.query('SET FOREIGN_KEY_CHECKS = 0');

    // Get all tables
    const [tables] = await pool.query(`
      SELECT TABLE_NAME 
      FROM INFORMATION_SCHEMA.TABLES 
      WHERE TABLE_SCHEMA = DATABASE()
    `);

    // Delete from each table (TRUNCATE can have issues with foreign keys)
    for (const table of tables) {
      const tableName = table.TABLE_NAME;
      await pool.query(`DELETE FROM ${tableName}`);
    }

    // Re-enable FK checks
    await pool.query('SET FOREIGN_KEY_CHECKS = 1');
  } catch (error) {
    console.error('Error cleaning database:', error);
    throw error;
  }
}

// Close database connection
async function closeDatabase() {
  if (pool) {
    await pool.end();
    pool = null;
  }
}

// Seed test user for authentication
async function seedTestUser() {
  const bcrypt = require('bcryptjs');
  const { v4: uuidv4 } = require('uuid');

  const userId = uuidv4();
  const hashedPassword = await bcrypt.hash('test123', 10);

  await pool.query(`
    INSERT INTO users (id, username, password_hash, full_name, role, is_active)
    VALUES (?, ?, ?, ?, ?, ?)
  `, [userId, 'testuser', hashedPassword, 'Test User', 'admin', 1]);

  return userId;
}

// Generate test JWT token
function generateTestToken(userId, role = 'admin') {
  const jwt = require('jsonwebtoken');
  return jwt.sign(
    { userId, role },
    process.env.JWT_SECRET || 'test-secret-key',
    { expiresIn: '1h' }
  );
}

module.exports = {
  setupTestDb,
  cleanDatabase,
  closeDatabase,
  seedTestUser,
  generateTestToken,
  getPool: () => pool
};
