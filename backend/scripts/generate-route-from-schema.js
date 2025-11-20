const fs = require('fs').promises;
const path = require('path');

async function generateRouteFromSchema(tableName) {
  try {
    if (!tableName) {
      console.error('❌ Please provide a table name');
      console.log('Usage: node scripts/generate-route-from-schema.js <table_name>');
      process.exit(1);
    }

    console.log(`🚀 Generating route for table: ${tableName}...`);

    // Read schema
    const schemaPath = path.join(__dirname, '..', 'docs', 'database-schema.json');
    const schemaContent = await fs.readFile(schemaPath, 'utf8');
    const schema = JSON.parse(schemaContent);

    if (!schema.tables[tableName]) {
      console.error(`❌ Table '${tableName}' not found in schema`);
      process.exit(1);
    }

    const table = schema.tables[tableName];
    const routeContent = generateRouteContent(tableName, table);
    
    // Write route file
    const routePath = path.join(__dirname, '..', 'src', 'routes', `${tableName}.js`);
    await fs.writeFile(routePath, routeContent);

    console.log(`✅ Route generated: src/routes/${tableName}.js`);

  } catch (error) {
    console.error('❌ Error generating route:', error.message);
    process.exit(1);
  }
}

function generateRouteContent(tableName, table) {
  const columns = table.columns;
  const pk = columns.find(c => c.key === 'PRI')?.name || 'id';
  
  // Helper to convert snake_case to camelCase
  const toCamel = (s) => s.replace(/_([a-z])/g, (g) => g[1].toUpperCase());

  // Generate Joi schema fields
  const joiFields = columns
    .filter(c => c.name !== pk && c.name !== 'created_at' && c.name !== 'updated_at')
    .map(c => {
      let joiType = 'Joi.string()';
      if (c.fullType.includes('int') || c.fullType.includes('decimal') || c.fullType.includes('double')) {
        joiType = 'Joi.number()';
      } else if (c.fullType.includes('tinyint(1)')) {
        joiType = 'Joi.boolean()';
      } else if (c.fullType.includes('date') || c.fullType.includes('timestamp')) {
        joiType = 'Joi.date()';
      }

      let validation = `  ${toCamel(c.name)}: ${joiType}`;
      
      if (!c.nullable && c.default === null) {
        validation += '.required()';
      } else {
        validation += '.allow(null, \'\')';
      }

      if (c.name === 'email') validation += '.email()';
      
      return validation;
    }).join(',\n');

  // Generate Select Fields
  const selectFields = columns.map(c => c.name).join(', ');
  
  // Generate Map Logic (DB -> API)
  const mapLogic = columns.map(c => {
    const camelName = toCamel(c.name);
    if (c.fullType.includes('tinyint(1)')) {
      return `        ${camelName}: item.${c.name} === 1`;
    }
    if (c.fullType.includes('decimal') || c.fullType.includes('numeric')) {
      return `        ${camelName}: item.${c.name} !== null ? parseFloat(item.${c.name}) : null`;
    }
    return `        ${camelName}: item.${c.name}`;
  }).join(',\n');

  return `const express = require('express');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation Schema
const ${toCamel(tableName)}Schema = Joi.object({
${joiFields}
});

// GET /api/${tableName}
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, query } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const params = [];

    let sql = 'SELECT ${selectFields} FROM ${tableName} WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM ${tableName} WHERE 1=1';

    if (query) {
      // Add search logic here based on text columns
      // sql += ' AND (name LIKE ?)';
      // params.push(\`%\${query}%\`);
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const [rows] = await pool.query(sql, params);
    const [countResult] = await pool.query(countSql, params.slice(0, -2));
    const total = countResult[0].total;

    res.json({
      data: rows.map(item => ({
${mapLogic}
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
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// GET /api/${tableName}/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT ${selectFields} FROM ${tableName} WHERE ${pk} = ?',
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    const item = rows[0];
    res.json({
${mapLogic}
    });
  } catch (error) {
    console.error('Get ${tableName} by id error:', error);
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// POST /api/${tableName}
router.post('/', authenticate, async (req, res) => {
  try {
    const { error, value } = ${toCamel(tableName)}Schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { v4: uuidv4 } = require('uuid');
    const id = uuidv4();
    
    // Map camelCase to snake_case for DB
    const dbData = {
      ${pk}: id,
      ...Object.keys(value).reduce((acc, key) => {
        const snakeKey = key.replace(/[A-Z]/g, letter => \`_\${letter.toLowerCase()}\`);
        acc[snakeKey] = value[key];
        return acc;
      }, {})
    };

    const columns = Object.keys(dbData).join(', ');
    const placeholders = Object.keys(dbData).map(() => '?').join(', ');
    const values = Object.values(dbData);

    await pool.query(
      \`INSERT INTO ${tableName} (\${columns}) VALUES (\${placeholders})\`,
      values
    );

    // Fetch created item
    const [rows] = await pool.query(
      'SELECT ${selectFields} FROM ${tableName} WHERE ${pk} = ?',
      [id]
    );

    const item = rows[0];
    res.status(201).json({
${mapLogic}
    });
  } catch (error) {
    console.error('Create ${tableName} error:', error);
    res.status(500).json({ error: 'خطا در ایجاد رکورد' });
  }
});

// PUT /api/${tableName}/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    // For PUT, allow partial updates by making all fields optional
    const updateSchema = ${toCamel(tableName)}Schema.fork(
      Object.keys(${toCamel(tableName)}Schema.describe().keys),
      (schema) => schema.optional()
    );
    
    const { error, value } = updateSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    // Check if exists
    const [check] = await pool.query('SELECT ${pk} FROM ${tableName} WHERE ${pk} = ?', [req.params.id]);
    if (check.length === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    // Map camelCase to snake_case - only for fields that were sent
    const updates = Object.keys(req.body).reduce((acc, key) => {
      if (value[key] !== undefined) {
        const snakeKey = key.replace(/[A-Z]/g, letter => \`_\${letter.toLowerCase()}\`);
        acc[snakeKey] = value[key];
      }
      return acc;
    }, {});

    if (Object.keys(updates).length > 0) {
      const setClause = Object.keys(updates).map(k => \`\${k} = ?\`).join(', ');
      const values = [...Object.values(updates), req.params.id];

      await pool.query(
        \`UPDATE ${tableName} SET \${setClause} WHERE ${pk} = ?\`,
        values
      );
    }

    // Fetch updated item
    const [rows] = await pool.query(
      'SELECT ${selectFields} FROM ${tableName} WHERE ${pk} = ?',
      [req.params.id]
    );

    const item = rows[0];
    res.json({
${mapLogic}
    });
  } catch (error) {
    console.error('Update ${tableName} error:', error);
    res.status(500).json({ error: 'خطا در ویرایش رکورد' });
  }
});

// DELETE /api/${tableName}/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM ${tableName} WHERE ${pk} = ?', [req.params.id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    res.json({ message: 'رکورد با موفقیت حذف شد' });
  } catch (error) {
    console.error('Delete ${tableName} error:', error);
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ error: 'این رکورد دارای وابستگی است و قابل حذف نیست' });
    }
    res.status(500).json({ error: 'خطا در حذف رکورد' });
  }
});

module.exports = router;
`;
}

// Run if called directly
if (require.main === module) {
  const tableName = process.argv[2];
  generateRouteFromSchema(tableName);
}

module.exports = generateRouteFromSchema;
