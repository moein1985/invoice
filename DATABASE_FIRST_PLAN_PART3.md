# طرح جامع - بخش 3: Code Generators و Contract Testing

## 5. مرحله 4: ساخت Code Generators

### گام 4.1: Generator برای Backend Routes

**مکان:** `backend/scripts/generate-route-from-schema.js`

**هدف:** از MySQL table به صورت خودکار Express route + Joi validation ساخته می‌شود

**کد کامل:**
```javascript
const fs = require('fs');
const path = require('path');

// Helper functions
function toPascalCase(str) {
  return str
    .replace(/(\w)(\w*)/g, (_, first, rest) => first.toUpperCase() + rest.toLowerCase())
    .replace(/[_-]/g, '');
}

function toCamelCase(str) {
  return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

function toSnakeCase(str) {
  return str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
}

function mysqlTypeToJoiType(mysqlType, columnName) {
  const baseType = mysqlType.toLowerCase().split('(')[0];
  
  // Special case: TINYINT(1) is boolean
  if (mysqlType === 'tinyint(1)') {
    return 'Joi.boolean()';
  }
  
  const typeMap = {
    'varchar': 'Joi.string()',
    'text': 'Joi.string()',
    'char': 'Joi.string()',
    'int': 'Joi.number().integer()',
    'tinyint': 'Joi.number().integer()',
    'bigint': 'Joi.number().integer()',
    'decimal': 'Joi.number()',
    'float': 'Joi.number()',
    'double': 'Joi.number()',
    'timestamp': 'Joi.date()',
    'datetime': 'Joi.date()',
    'date': 'Joi.date()',
    'json': 'Joi.object()',
    'enum': 'Joi.string().valid()'
  };
  
  return typeMap[baseType] || 'Joi.any()';
}

function generateRoute(tableName, tableSchema) {
  const entityName = tableName.slice(0, -1); // customers → customer
  const EntityName = toPascalCase(entityName);
  const columns = tableSchema.columns;
  
  // Filter columns
  const autoFields = ['id', 'created_at', 'updated_at'];
  const editableColumns = columns.filter(col => 
    !autoFields.includes(col.COLUMN_NAME.toLowerCase())
  );
  
  const requiredColumns = editableColumns.filter(col => 
    col.IS_NULLABLE === 'NO' && col.COLUMN_DEFAULT === null
  );
  
  // Generate Joi schemas
  const createSchemaFields = editableColumns.map(col => {
    const fieldName = toCamelCase(col.COLUMN_NAME);
    let joiDef = mysqlTypeToJoiType(col.COLUMN_TYPE, col.COLUMN_NAME);
    
    // Add max length for strings
    if (col.CHARACTER_MAXIMUM_LENGTH) {
      joiDef = joiDef.replace(')', `.max(${col.CHARACTER_MAXIMUM_LENGTH})`);
    }
    
    // Add min for numbers
    if (col.DATA_TYPE.includes('decimal') || col.DATA_TYPE.includes('int')) {
      if (['credit_limit', 'current_debt', 'amount', 'price'].some(kw => col.COLUMN_NAME.includes(kw))) {
        joiDef = joiDef.replace(')', '.min(0)');
      }
    }
    
    // Required or optional
    if (requiredColumns.includes(col)) {
      joiDef += '.required()';
    } else if (col.COLUMN_DEFAULT !== null) {
      joiDef += `.default(${col.COLUMN_DEFAULT})`;
    } else {
      joiDef += ".allow('')";
    }
    
    return `  ${fieldName}: ${joiDef}`;
  }).join(',\n');
  
  const updateSchemaFields = editableColumns.map(col => {
    const fieldName = toCamelCase(col.COLUMN_NAME);
    let joiDef = mysqlTypeToJoiType(col.COLUMN_TYPE, col.COLUMN_NAME);
    
    if (col.CHARACTER_MAXIMUM_LENGTH) {
      joiDef = joiDef.replace(')', `.max(${col.CHARACTER_MAXIMUM_LENGTH})`);
    }
    
    if (col.DATA_TYPE.includes('decimal') || col.DATA_TYPE.includes('int')) {
      if (['credit_limit', 'current_debt', 'amount', 'price'].some(kw => col.COLUMN_NAME.includes(kw))) {
        joiDef = joiDef.replace(')', '.min(0)');
      }
    }
    
    joiDef += ".optional()";
    
    return `  ${fieldName}: ${joiDef}`;
  }).join(',\n');
  
  // Generate field mappings
  const apiToDbMapping = editableColumns.map(col => {
    const camelCase = toCamelCase(col.COLUMN_NAME);
    if (camelCase !== col.COLUMN_NAME) {
      return { api: camelCase, db: col.COLUMN_NAME };
    }
    return null;
  }).filter(Boolean);
  
  // Generate INSERT columns
  const insertColumns = editableColumns.map(col => col.COLUMN_NAME).join(', ');
  const insertPlaceholders = editableColumns.map(() => '?').join(', ');
  const insertValues = editableColumns.map(col => {
    const camelCase = toCamelCase(col.COLUMN_NAME);
    if (col.COLUMN_DEFAULT !== null) {
      return `${camelCase} || ${col.COLUMN_DEFAULT}`;
    }
    return `${camelCase} || ''`;
  }).join(', ');
  
  // Generate SELECT columns with mapping
  const selectColumns = columns.map(col => col.COLUMN_NAME).join(', ');
  const responseMapping = columns.map(col => {
    const camelCase = toCamelCase(col.COLUMN_NAME);
    return `      ${camelCase}: ${entityName}.${col.COLUMN_NAME}`;
  }).join(',\n');
  
  // Generate UPDATE conditions
  const updateConditions = editableColumns.map(col => {
    const camelCase = toCamelCase(col.COLUMN_NAME);
    return `    if (req.body.${camelCase} !== undefined) {
      updates.push('${col.COLUMN_NAME} = ?');
      values.push(req.body.${camelCase});
    }`;
  }).join('\n');
  
  // Template
  const template = `const express = require('express');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const create${EntityName}Schema = Joi.object({
${createSchemaFields}
});

const update${EntityName}Schema = Joi.object({
${updateSchemaFields}
});

// GET /api/${tableName}
router.get('/', authenticate, async (req, res) => {
  try {
    const { query, isActive, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let sql = 'SELECT ${selectColumns} FROM ${tableName} WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM ${tableName} WHERE 1=1';
    const params = [];
    const countParams = [];

    if (typeof isActive !== 'undefined') {
      sql += ' AND is_active = ?';
      countSql += ' AND is_active = ?';
      params.push(isActive === 'true' || isActive === '1');
      countParams.push(isActive === 'true' || isActive === '1');
    }

    if (query) {
      // Add search conditions based on string columns
      ${columns.filter(c => c.DATA_TYPE.includes('varchar') || c.DATA_TYPE.includes('text')).slice(0, 3).map(c => 
        `sql += ' AND ${c.COLUMN_NAME} LIKE ?';\n      countSql += ' AND ${c.COLUMN_NAME} LIKE ?';\n      params.push(\`%\${query}%\`);\n      countParams.push(\`%\${query}%\`);`
      ).join('\n      ')}
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const [rows] = await pool.query(sql, params);
    const [countResult] = await pool.query(countSql, countParams);
    const total = countResult[0].total;

    res.json({
      data: rows.map(row => ({
${columns.map(col => `        ${toCamelCase(col.COLUMN_NAME)}: row.${col.COLUMN_NAME}`).join(',\n')}
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get ${tableName} error:', error);
    res.status(500).json({ error: 'خطا در دریافت ${tableName}' });
  }
});

// GET /api/${tableName}/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT ${selectColumns} FROM ${tableName} WHERE id = ?',
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: '${entityName} یافت نشد' });
    }

    const ${entityName} = rows[0];
    res.json({
${responseMapping}
    });
  } catch (error) {
    console.error('Get ${entityName} error:', error);
    res.status(500).json({ error: 'خطا در دریافت ${entityName}' });
  }
});

// POST /api/${tableName}
router.post('/', authenticate, async (req, res) => {
  try {
    const { error } = create${EntityName}Schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { ${editableColumns.map(c => toCamelCase(c.COLUMN_NAME)).join(', ')} } = req.body;

    const id = require('uuid').v4();
    await pool.query(
      'INSERT INTO ${tableName} (id, ${insertColumns}) VALUES (?, ${insertPlaceholders})',
      [id, ${editableColumns.map(c => {
        const camel = toCamelCase(c.COLUMN_NAME);
        if (c.COLUMN_DEFAULT !== null) {
          return `${camel} !== undefined ? ${camel} : ${c.COLUMN_DEFAULT}`;
        }
        return `${camel} || ''`;
      }).join(', ')}]
    );

    const [newRows] = await pool.query(
      'SELECT ${selectColumns} FROM ${tableName} WHERE id = ?',
      [id]
    );

    const ${entityName} = newRows[0];
    res.status(201).json({
${responseMapping}
    });
  } catch (error) {
    console.error('Create ${entityName} error:', error);
    res.status(500).json({ error: 'خطا در ایجاد ${entityName}' });
  }
});

// PUT /api/${tableName}/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { error } = update${EntityName}Schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const updates = [];
    const values = [];

${updateConditions}

    if (updates.length === 0) {
      return res.status(400).json({ error: 'هیچ فیلدی برای بروزرسانی ارسال نشده' });
    }

    values.push(req.params.id);
    await pool.query(
      \`UPDATE ${tableName} SET \${updates.join(', ')} WHERE id = ?\`,
      values
    );

    const [updatedRows] = await pool.query(
      'SELECT ${selectColumns} FROM ${tableName} WHERE id = ?',
      [req.params.id]
    );

    if (updatedRows.length === 0) {
      return res.status(404).json({ error: '${entityName} یافت نشد' });
    }

    const ${entityName} = updatedRows[0];
    res.json({
${responseMapping}
    });
  } catch (error) {
    console.error('Update ${entityName} error:', error);
    res.status(500).json({ error: 'خطا در بروزرسانی ${entityName}' });
  }
});

// DELETE /api/${tableName}/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM ${tableName} WHERE id = ?',
      [req.params.id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: '${entityName} یافت نشد' });
    }

    res.json({ message: '${entityName} با موفقیت حذف شد' });
  } catch (error) {
    console.error('Delete ${entityName} error:', error);
    
    // Check for foreign key constraint
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ 
        error: 'این ${entityName} در سایر بخش‌ها استفاده شده و قابل حذف نیست' 
      });
    }
    
    res.status(500).json({ error: 'خطا در حذف ${entityName}' });
  }
});

module.exports = router;
`;

  return template;
}

// Main function
async function main() {
  const schema = JSON.parse(
    fs.readFileSync('./docs/database-schema.json', 'utf8')
  );
  
  const tableName = process.argv[2];
  
  if (!tableName) {
    console.error('Usage: node generate-route-from-schema.js <table_name>');
    process.exit(1);
  }
  
  if (!schema[tableName]) {
    console.error(`Table '${tableName}' not found in schema`);
    process.exit(1);
  }
  
  const routeCode = generateRoute(tableName, schema[tableName]);
  
  const outputPath = `./src/routes/${tableName}.js`;
  fs.writeFileSync(outputPath, routeCode);
  
  console.log(`✅ Route generated: ${outputPath}`);
  console.log('⚠️  Remember to:');
  console.log('   1. Review and adjust the generated code');
  console.log('   2. Add to server.js: app.use(\'/api/${tableName}\', require(\'./routes/${tableName}\'));');
  console.log('   3. Write integration tests');
}

main().catch(console.error);
```

**استفاده:**
```bash
node scripts/generate-route-from-schema.js customers
node scripts/generate-route-from-schema.js users
node scripts/generate-route-from-schema.js documents
```

---

### گام 4.2: Generator برای Flutter Models

**مکان:** `backend/scripts/generate-dart-model.js`

**کد کامل:**
```javascript
const fs = require('fs');

function toPascalCase(str) {
  return str
    .replace(/(\w)(\w*)/g, (_, first, rest) => first.toUpperCase() + rest.toLowerCase())
    .replace(/[_-]/g, '');
}

function toCamelCase(str) {
  return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

function mysqlTypeToDartType(mysqlType, isNullable) {
  const baseType = mysqlType.toLowerCase().split('(')[0];
  
  // Special case: TINYINT(1) is bool
  if (mysqlType.toLowerCase() === 'tinyint(1)') {
    return isNullable ? 'bool?' : 'bool';
  }
  
  const typeMap = {
    'varchar': 'String',
    'text': 'String',
    'char': 'String',
    'int': 'int',
    'tinyint': 'int',
    'bigint': 'int',
    'decimal': 'double',
    'float': 'double',
    'double': 'double',
    'timestamp': 'DateTime',
    'datetime': 'DateTime',
    'date': 'DateTime',
    'json': 'Map<String, dynamic>',
    'enum': 'String'
  };
  
  const dartType = typeMap[baseType] || 'dynamic';
  return isNullable ? `${dartType}?` : dartType;
}

function generateDartModel(tableName, tableSchema) {
  const entityName = tableName.slice(0, -1); // customers → customer
  const ClassName = toPascalCase(entityName);
  const columns = tableSchema.columns;
  
  // Generate class fields
  const fields = columns.map(col => {
    const fieldName = toCamelCase(col.COLUMN_NAME);
    const isNullable = col.IS_NULLABLE === 'YES' || col.COLUMN_DEFAULT !== null;
    const dartType = mysqlTypeToDartType(col.COLUMN_TYPE, isNullable);
    
    return `  final ${dartType} ${fieldName};`;
  }).join('\n');
  
  // Generate constructor parameters
  const constructorParams = columns.map(col => {
    const fieldName = toCamelCase(col.COLUMN_NAME);
    const isNullable = col.IS_NULLABLE === 'YES' || col.COLUMN_DEFAULT !== null;
    
    if (isNullable) {
      return `    this.${fieldName}`;
    } else {
      return `    required this.${fieldName}`;
    }
  }).join(',\n');
  
  // Generate fromJson with type conversions
  const fromJsonFields = columns.map(col => {
    const fieldName = toCamelCase(col.COLUMN_NAME);
    const colName = col.COLUMN_NAME;
    const mysqlType = col.COLUMN_TYPE.toLowerCase();
    
    // Special handling for TINYINT(1) → bool
    if (mysqlType === 'tinyint(1)') {
      return `      ${fieldName}: _parseBool(json['${colName}'])`;
    }
    
    // Special handling for DECIMAL → double
    if (mysqlType.startsWith('decimal')) {
      return `      ${fieldName}: _parseDouble(json['${colName}'])`;
    }
    
    // DateTime conversion
    if (['timestamp', 'datetime', 'date'].includes(mysqlType.split('(')[0])) {
      if (col.IS_NULLABLE === 'YES') {
        return `      ${fieldName}: json['${colName}'] != null ? DateTime.parse(json['${colName}'].toString()) : null`;
      }
      return `      ${fieldName}: DateTime.parse(json['${colName}'].toString())`;
    }
    
    // Default
    return `      ${fieldName}: json['${colName}']`;
  }).join(',\n');
  
  // Generate toJson
  const toJsonFields = columns
    .filter(col => !['id', 'created_at', 'updated_at'].includes(col.COLUMN_NAME.toLowerCase()))
    .map(col => {
      const fieldName = toCamelCase(col.COLUMN_NAME);
      const colName = col.COLUMN_NAME;
      
      return `      '${colName}': ${fieldName}`;
    }).join(',\n');
  
  // Generate copyWith parameters
  const copyWithParams = columns.map(col => {
    const fieldName = toCamelCase(col.COLUMN_NAME);
    const dartType = mysqlTypeToDartType(col.COLUMN_TYPE, true); // Always nullable in copyWith
    
    return `    ${dartType} ${fieldName}`;
  }).join(',\n');
  
  // Generate copyWith body
  const copyWithBody = columns.map(col => {
    const fieldName = toCamelCase(col.COLUMN_NAME);
    return `      ${fieldName}: ${fieldName} ?? this.${fieldName}`;
  }).join(',\n');
  
  const template = `import 'package:equatable/equatable.dart';

class ${ClassName}Model extends Equatable {
${fields}

  const ${ClassName}Model({
${constructorParams},
  });

  factory ${ClassName}Model.fromJson(Map<String, dynamic> json) {
    return ${ClassName}Model(
${fromJsonFields},
    );
  }

  Map<String, dynamic> toJson() {
    return {
${toJsonFields},
    };
  }

  ${ClassName}Model copyWith({
${copyWithParams},
  }) {
    return ${ClassName}Model(
${copyWithBody},
    );
  }

  @override
  List<Object?> get props => [
${columns.map(col => `    ${toCamelCase(col.COLUMN_NAME)}`).join(',\n')},
  ];

  // Helper functions for type conversion
  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
`;

  return template;
}

// Main function
async function main() {
  const schema = JSON.parse(
    fs.readFileSync('./docs/database-schema.json', 'utf8')
  );
  
  const tableName = process.argv[2];
  
  if (!tableName) {
    console.error('Usage: node generate-dart-model.js <table_name>');
    process.exit(1);
  }
  
  if (!schema[tableName]) {
    console.error(`Table '${tableName}' not found in schema`);
    process.exit(1);
  }
  
  const dartCode = generateDartModel(tableName, schema[tableName]);
  
  const entityName = tableName.slice(0, -1);
  const outputPath = `../lib/features/${entityName}/data/models/${entityName}_model.dart`;
  
  // Create directory if not exists
  const fs = require('fs');
  const path = require('path');
  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
  
  fs.writeFileSync(outputPath, dartCode);
  
  console.log(`✅ Dart model generated: ${outputPath}`);
  console.log('⚠️  Remember to:');
  console.log('   1. Add equatable to pubspec.yaml if not present');
  console.log('   2. Review nullable fields');
  console.log('   3. Add any business logic methods');
  console.log('   4. Write unit tests for fromJson/toJson');
}

main().catch(console.error);
```

**استفاده:**
```bash
node scripts/generate-dart-model.js customers
node scripts/generate-dart-model.js users
node scripts/generate-dart-model.js documents
```

---

ادامه در فایل بعدی...
