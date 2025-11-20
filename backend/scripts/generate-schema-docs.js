const fs = require('fs').promises;
const path = require('path');

async function generateSchemaDocs() {
  try {
    console.log('📖 Generating schema documentation...');

    // Read schema JSON
    const schemaPath = path.join(__dirname, '..', 'docs', 'database-schema.json');
    const schemaContent = await fs.readFile(schemaPath, 'utf8');
    const schema = JSON.parse(schemaContent);

    let markdown = `# Database Schema Documentation

**Database:** ${schema.database}  
**Extracted:** ${new Date(schema.extractedAt).toLocaleString('fa-IR')}  
**Total Tables:** ${Object.keys(schema.tables).length}

---

`;

    // Generate documentation for each table
    for (const [tableName, tableSchema] of Object.entries(schema.tables)) {
      markdown += `## Table: \`${tableName}\`\n\n`;

      // Columns table
      markdown += `### Columns\n\n`;
      markdown += `| Column | Type | Nullable | Default | Key | Extra | Comment |\n`;
      markdown += `|--------|------|----------|---------|-----|-------|----------|\n`;
      
      for (const col of tableSchema.columns) {
        markdown += `| ${col.name} | ${col.fullType} | ${col.nullable ? '✅' : '❌'} | ${col.default || '-'} | ${col.key || '-'} | ${col.extra || '-'} | ${col.comment || '-'} |\n`;
      }

      // Foreign Keys
      if (tableSchema.foreignKeys && tableSchema.foreignKeys.length > 0) {
        markdown += `\n### Foreign Keys\n\n`;
        markdown += `| Column | References | Constraint |\n`;
        markdown += `|--------|------------|------------|\n`;
        
        for (const fk of tableSchema.foreignKeys) {
          markdown += `| ${fk.column} | ${fk.referencedTable}.${fk.referencedColumn} | ${fk.constraintName} |\n`;
        }
      }

      // Indexes
      if (tableSchema.indexes && Object.keys(tableSchema.indexes).length > 0) {
        markdown += `\n### Indexes\n\n`;
        markdown += `| Index Name | Columns | Unique | Type |\n`;
        markdown += `|------------|---------|--------|------|\n`;
        
        for (const [indexName, indexInfo] of Object.entries(tableSchema.indexes)) {
          const unique = indexInfo.unique ? '✅' : '❌';
          markdown += `| ${indexName} | ${indexInfo.columns.join(', ')} | ${unique} | ${indexInfo.type} |\n`;
        }
      }

      // Generate sample SQL
      markdown += `\n### Sample Queries\n\n`;
      markdown += `\`\`\`sql\n`;
      markdown += `-- Select all\n`;
      markdown += `SELECT * FROM ${tableName} LIMIT 10;\n\n`;
      
      const pkColumn = tableSchema.columns.find(c => c.key === 'PRI');
      if (pkColumn) {
        markdown += `-- Select by ID\n`;
        markdown += `SELECT * FROM ${tableName} WHERE ${pkColumn.name} = ?;\n\n`;
      }

      markdown += `-- Count records\n`;
      markdown += `SELECT COUNT(*) as total FROM ${tableName};\n`;
      markdown += `\`\`\`\n\n`;

      // Type conversions for Flutter
      markdown += `### Type Conversions\n\n`;
      const specialTypes = tableSchema.columns.filter(c => 
        c.fullType.includes('tinyint(1)') || 
        c.type === 'decimal' || 
        c.type === 'timestamp' ||
        c.type === 'datetime'
      );

      if (specialTypes.length > 0) {
        markdown += `**MySQL → Dart:**\n\n`;
        for (const col of specialTypes) {
          if (col.fullType.includes('tinyint(1)')) {
            markdown += `- \`${col.name}\` (${col.fullType}) → \`bool\` (requires \`_parseBool()\`)\n`;
          } else if (col.type === 'decimal') {
            markdown += `- \`${col.name}\` (${col.fullType}) → \`double\` (requires \`_parseDouble()\`)\n`;
          } else if (col.type === 'timestamp' || col.type === 'datetime') {
            markdown += `- \`${col.name}\` (${col.fullType}) → \`DateTime\` (use \`DateTime.parse()\`)\n`;
          }
        }
        markdown += `\n`;
      } else {
        markdown += `*No special type conversions needed.*\n\n`;
      }

      markdown += `---\n\n`;
    }

    // Write markdown file
    const outputPath = path.join(__dirname, '..', 'docs', 'DATABASE_SCHEMA.md');
    await fs.writeFile(outputPath, markdown);

    console.log(`✅ Documentation generated successfully!`);
    console.log(`📄 Output: ${outputPath}`);

  } catch (error) {
    console.error('❌ Error generating documentation:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  generateSchemaDocs();
}

module.exports = generateSchemaDocs;
