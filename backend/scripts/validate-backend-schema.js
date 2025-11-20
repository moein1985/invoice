const fs = require('fs').promises;
const path = require('path');

async function validateBackendSchema() {
  try {
    console.log('🔍 Validating Backend schema against MySQL...\n');

    // Read MySQL schema
    const schemaPath = path.join(__dirname, '..', 'docs', 'database-schema.json');
    const schemaContent = await fs.readFile(schemaPath, 'utf8');
    const mysqlSchema = JSON.parse(schemaContent);

    let hasErrors = false;
    let warnings = [];
    let passed = [];

    // Check each route file
    const routesDir = path.join(__dirname, '..', 'src', 'routes');
    const routeFiles = await fs.readdir(routesDir);

    for (const file of routeFiles) {
      if (!file.endsWith('.js') || file.endsWith('_old.js') || file.endsWith('_temp.js') || file === 'auth.js') {
        continue;
      }

      const tableName = file.replace('.js', '');
      console.log(`📋 Checking ${tableName}...`);

      // Check if table exists in MySQL
      if (!mysqlSchema.tables[tableName]) {
        console.log(`  ⚠️  Warning: Table '${tableName}' not found in MySQL schema`);
        warnings.push(`Table '${tableName}' has route but no MySQL table`);
        continue;
      }

      const mysqlTable = mysqlSchema.tables[tableName];
      const mysqlColumns = mysqlTable.columns.reduce((acc, col) => {
        acc[col.name] = col;
        return acc;
      }, {});

      // Try to read route file and find Joi schema
      const routePath = path.join(routesDir, file);
      const routeContent = await fs.readFile(routePath, 'utf8');

      // Look for Joi validation patterns
      const joiSchemaMatch = routeContent.match(/Joi\.object\(\{([^}]+)\}\)/s);
      if (!joiSchemaMatch) {
        console.log(`  ⚠️  No Joi schema found in ${file}`);
        warnings.push(`${file}: No Joi validation schema detected`);
        continue;
      }

      // Parse Joi fields (basic pattern matching)
      const joiFields = [];
      const fieldMatches = routeContent.matchAll(/(\w+):\s*Joi\.(string|number|boolean|date)/g);
      for (const match of fieldMatches) {
        joiFields.push(match[1]);
      }

      if (joiFields.length === 0) {
        console.log(`  ⚠️  Could not parse Joi fields from ${file}`);
        warnings.push(`${file}: Could not parse Joi schema`);
        continue;
      }

      // Check for missing required fields
      const requiredMysqlFields = mysqlTable.columns
        .filter(col => !col.nullable && !col.default && col.extra !== 'auto_increment' && col.key !== 'PRI')
        .map(col => col.name);

      const missingInJoi = requiredMysqlFields.filter(field => 
        !joiFields.includes(field) && !joiFields.includes(snakeToCamel(field))
      );

      if (missingInJoi.length > 0) {
        console.log(`  ❌ Missing required fields in Joi: ${missingInJoi.join(', ')}`);
        hasErrors = true;
      } else {
        console.log(`  ✅ All required fields validated`);
        passed.push(tableName);
      }

      // Check for extra fields in Joi that don't exist in MySQL
      const extraInJoi = joiFields.filter(field => {
        const snakeCase = camelToSnake(field);
        return !mysqlColumns[field] && !mysqlColumns[snakeCase];
      });

      if (extraInJoi.length > 0) {
        console.log(`  ⚠️  Extra fields in Joi (not in MySQL): ${extraInJoi.join(', ')}`);
        warnings.push(`${file}: Extra fields - ${extraInJoi.join(', ')}`);
      }

      console.log('');
    }

    // Check for tables without routes
    console.log('🔍 Checking for tables without routes...\n');
    for (const tableName of Object.keys(mysqlSchema.tables)) {
      if (tableName === 'users' || tableName === 'sessions') {
        continue; // Skip auth-related tables
      }

      const routeFile = `${tableName}.js`;
      if (!routeFiles.includes(routeFile)) {
        console.log(`  ⚠️  Table '${tableName}' has no route file`);
        warnings.push(`Missing route for table '${tableName}'`);
      }
    }

    // Summary
    console.log('\n' + '='.repeat(50));
    console.log('📊 Validation Summary:\n');
    console.log(`✅ Passed: ${passed.length} tables`);
    console.log(`⚠️  Warnings: ${warnings.length}`);
    console.log(`❌ Errors: ${hasErrors ? 'Yes' : 'No'}`);

    if (warnings.length > 0) {
      console.log('\n⚠️  Warnings:');
      warnings.forEach(w => console.log(`   - ${w}`));
    }

    if (hasErrors) {
      console.log('\n❌ Validation failed! Please fix the errors above.');
      process.exit(1);
    } else {
      console.log('\n✅ Validation passed!');
    }

  } catch (error) {
    console.error('❌ Error during validation:', error.message);
    process.exit(1);
  }
}

// Helper functions
function snakeToCamel(str) {
  return str.replace(/_([a-z])/g, (g) => g[1].toUpperCase());
}

function camelToSnake(str) {
  return str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
}

// Run if called directly
if (require.main === module) {
  validateBackendSchema();
}

module.exports = validateBackendSchema;
