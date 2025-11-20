const fs = require('fs').promises;
const path = require('path');
const generateRoute = require('./generate-route-from-schema');
const generateModel = require('./generate-dart-model');

async function generateAll() {
  try {
    console.log('🚀 Generating all routes and models...');

    const schemaPath = path.join(__dirname, '..', 'docs', 'database-schema.json');
    const schemaContent = await fs.readFile(schemaPath, 'utf8');
    const schema = JSON.parse(schemaContent);

    for (const tableName of Object.keys(schema.tables)) {
      // Skip auth tables if needed, or generate for all
      if (tableName === 'schema_migrations') continue;

      console.log(`\n📦 Processing table: ${tableName}`);
      
      // Generate Route
      await generateRoute(tableName);
      
      // Generate Model
      await generateModel(tableName);
    }

    console.log('\n✨ All files generated successfully!');

  } catch (error) {
    console.error('❌ Error generating all:', error.message);
    process.exit(1);
  }
}

generateAll();
