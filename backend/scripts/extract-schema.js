const mysql = require('mysql2/promise');
const fs = require('fs').promises;
const path = require('path');
require('dotenv').config();

async function extractSchema() {
  let connection;
  
  try {
    console.log('🔍 Connecting to MySQL...');
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
    });

    console.log('✅ Connected to database:', process.env.DB_NAME);

    // Get all tables
    const [tables] = await connection.query(`
      SELECT TABLE_NAME
      FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA = ?
      ORDER BY TABLE_NAME
    `, [process.env.DB_NAME]);

    console.log(`📋 Found ${tables.length} tables`);

    const schema = {
      database: process.env.DB_NAME,
      extractedAt: new Date().toISOString(),
      tables: {}
    };

    // Extract schema for each table
    for (const table of tables) {
      const tableName = table.TABLE_NAME;
      console.log(`  📊 Extracting ${tableName}...`);

      // Get columns
      const [columns] = await connection.query(`
        SELECT 
          COLUMN_NAME,
          DATA_TYPE,
          COLUMN_TYPE,
          IS_NULLABLE,
          COLUMN_DEFAULT,
          COLUMN_KEY,
          EXTRA,
          COLUMN_COMMENT
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        ORDER BY ORDINAL_POSITION
      `, [process.env.DB_NAME, tableName]);

      // Get foreign keys
      const [foreignKeys] = await connection.query(`
        SELECT 
          COLUMN_NAME,
          REFERENCED_TABLE_NAME,
          REFERENCED_COLUMN_NAME,
          CONSTRAINT_NAME
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE TABLE_SCHEMA = ? 
          AND TABLE_NAME = ?
          AND REFERENCED_TABLE_NAME IS NOT NULL
      `, [process.env.DB_NAME, tableName]);

      // Get indexes
      const [indexes] = await connection.query(`
        SELECT 
          INDEX_NAME,
          COLUMN_NAME,
          NON_UNIQUE,
          INDEX_TYPE
        FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
        ORDER BY INDEX_NAME, SEQ_IN_INDEX
      `, [process.env.DB_NAME, tableName]);

      schema.tables[tableName] = {
        columns: columns.map(col => ({
          name: col.COLUMN_NAME,
          type: col.DATA_TYPE,
          fullType: col.COLUMN_TYPE,
          nullable: col.IS_NULLABLE === 'YES',
          default: col.COLUMN_DEFAULT,
          key: col.COLUMN_KEY,
          extra: col.EXTRA,
          comment: col.COLUMN_COMMENT
        })),
        foreignKeys: foreignKeys.map(fk => ({
          column: fk.COLUMN_NAME,
          referencedTable: fk.REFERENCED_TABLE_NAME,
          referencedColumn: fk.REFERENCED_COLUMN_NAME,
          constraintName: fk.CONSTRAINT_NAME
        })),
        indexes: indexes.reduce((acc, idx) => {
          if (!acc[idx.INDEX_NAME]) {
            acc[idx.INDEX_NAME] = {
              columns: [],
              unique: idx.NON_UNIQUE === 0,
              type: idx.INDEX_TYPE
            };
          }
          acc[idx.INDEX_NAME].columns.push(idx.COLUMN_NAME);
          return acc;
        }, {})
      };
    }

    // Write to file
    const outputPath = path.join(__dirname, '..', 'docs', 'database-schema.json');
    await fs.writeFile(outputPath, JSON.stringify(schema, null, 2));

    console.log(`\n✅ Schema extracted successfully!`);
    console.log(`📄 Output: ${outputPath}`);
    console.log(`📊 Total tables: ${tables.length}`);
    
    // Summary
    console.log('\n📊 Summary:');
    for (const [tableName, tableSchema] of Object.entries(schema.tables)) {
      console.log(`  - ${tableName}: ${tableSchema.columns.length} columns, ${tableSchema.foreignKeys.length} FKs`);
    }

  } catch (error) {
    console.error('❌ Error extracting schema:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// Run if called directly
if (require.main === module) {
  extractSchema();
}

module.exports = extractSchema;
