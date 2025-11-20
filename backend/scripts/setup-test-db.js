const mysql = require('mysql2/promise');
require('dotenv').config();

async function setupTestDatabase() {
  let connection;

  try {
    console.log('🔧 Setting up test database...');

    const testDbName = `${process.env.DB_NAME}_test`;

    // Connect and create test database (may need manual creation first)
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      multipleStatements: true
    });

    // Try to create database if it doesn't exist
    console.log(`📦 Ensuring database exists: ${testDbName}`);
    try {
      await connection.query(`CREATE DATABASE IF NOT EXISTS ${testDbName}`);
    } catch (err) {
      console.log(`ℹ️  Database may already exist: ${err.message}`);
    }
    
    await connection.query(`USE ${testDbName}`);

    console.log('✅ Test database created');

    // Read and execute main schema
    const fs = require('fs').promises;
    const path = require('path');
    
    // Try to find schema SQL file
    const possiblePaths = [
      path.join(__dirname, '..', 'schema.sql'),
      path.join(__dirname, '..', 'database-schema.sql'),
      path.join(__dirname, '..', 'src', 'database', 'schema.sql'),
    ];

    let schemaContent = null;
    for (const schemaPath of possiblePaths) {
      try {
        schemaContent = await fs.readFile(schemaPath, 'utf8');
        console.log(`📄 Found schema at: ${schemaPath}`);
        break;
      } catch (err) {
        // Try next path
      }
    }

    if (!schemaContent) {
      console.log('⚠️  No schema.sql found, will copy structure from main database');
      
      // Get structure from main database
      await connection.query(`USE ${process.env.DB_NAME}`);
      const [tables] = await connection.query('SHOW TABLES');
      
      await connection.query(`USE ${testDbName}`);
      
      // Disable FK checks
      await connection.query('SET FOREIGN_KEY_CHECKS = 0');
      
      for (const table of tables) {
        const tableName = Object.values(table)[0];
        console.log(`  📋 Copying structure: ${tableName}`);
        
        await connection.query(`USE ${process.env.DB_NAME}`);
        const [createTable] = await connection.query(`SHOW CREATE TABLE ${tableName}`);
        const createSql = createTable[0]['Create Table'];
        
        await connection.query(`USE ${testDbName}`);
        
        // Drop table if exists
        await connection.query(`DROP TABLE IF EXISTS ${tableName}`);
        await connection.query(createSql);
      }
      
      // Re-enable FK checks
      await connection.query('SET FOREIGN_KEY_CHECKS = 1');
    } else {
      console.log('📄 Executing schema SQL...');
      
      // Split by semicolon and execute each statement
      const statements = schemaContent
        .split(';')
        .map(s => s.trim())
        .filter(s => s.length > 0 && !s.startsWith('--'));

      for (const statement of statements) {
        try {
          await connection.query(statement);
        } catch (err) {
          if (!err.message.includes('already exists')) {
            console.warn(`  ⚠️  Warning: ${err.message}`);
          }
        }
      }
    }

    console.log('✅ Test database setup complete!');
    console.log(`📊 Database: ${testDbName}`);

  } catch (error) {
    console.error('❌ Error setting up test database:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// Run if called directly
if (require.main === module) {
  setupTestDatabase();
}

module.exports = setupTestDatabase;
