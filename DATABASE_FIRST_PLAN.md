# طرح جامع: توسعه سیستم به روش Database-First

## 📋 فهرست مطالب

1. [مقدمه و فلسفه](#1-مقدمه-و-فلسفه)
2. [مرحله 1: استخراج و مستندسازی Schema](#2-مرحله-1-استخراج-و-مستندسازی-schema)
3. [مرحله 2: ایجاد ابزارهای Validation](#3-مرحله-2-ایجاد-ابزارهای-validation)
4. [مرحله 3: نوشتن Integration Tests](#4-مرحله-3-نوشتن-integration-tests)
5. [مرحله 4: ساخت Code Generators](#5-مرحله-4-ساخت-code-generators)
6. [مرحله 5: پیاده‌سازی Contract Testing](#6-مرحله-5-پیاده‌سازی-contract-testing)
7. [مرحله 6: Checklist برای هر Feature](#7-مرحله-6-checklist-برای-هر-feature)

---

## 1. مقدمه و فلسفه

### 🎯 هدف اصلی
جلوگیری از خطاهای سعی و خطا با تعیین **MySQL به عنوان Source of Truth**

### 📊 جریان داده
```
MySQL Schema (واقعیت دیتابیس)
    ↓
Backend API (پل ارتباطی)
    ↓
Flutter Models (مصرف‌کننده)
```

### ✅ مزایا
1. **Schema ثابت و قابل اعتماد** - دیتابیس مرجع اصلی است
2. **کاهش باگ‌ها** - type mismatch ها از قبل شناسایی می‌شوند
3. **مستندسازی خودکار** - از دیتابیس مستقیماً documentation ساخته می‌شود
4. **تست‌پذیری بالا** - هر لایه به صورت مستقل تست می‌شود
5. **Scale پذیری** - افزودن feature جدید با روال مشخص انجام می‌شود

### ⚠️ مشکلات فعلی سیستم
- Backend validation (Joi schema) با MySQL جداول match نمی‌کند
- Flutter models فیلدهای اضافی یا ناقص دارند
- Type conversion ها (int→bool, String→double) به صورت دستی انجام می‌شود
- هیچ تست خودکاری وجود ندارد
- CORS configuration اشتباه است

---

## 2. مرحله 1: استخراج و مستندسازی Schema

### گام 1.1: استخراج Schema از MySQL

**مکان:** `backend/scripts/extract-schema.js`

**عملکرد:**
- اتصال به دیتابیس MySQL
- استخراج تمام جداول
- استخراج ستون‌ها با نوع داده، nullable, default value
- استخراج Foreign Keys و Relations
- استخراج Index ها

**Output:** فایل `backend/docs/database-schema.json`

**نمونه کد:**
```javascript
const mysql = require('mysql2/promise');
const fs = require('fs');

async function extractSchema() {
  const pool = await mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME || 'invoice_db'
  });

  const schema = {};
  
  // Get all tables
  const [tables] = await pool.query(
    "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ?",
    [process.env.DB_NAME || 'invoice_db']
  );
  
  for (const table of tables) {
    const tableName = table.TABLE_NAME;
    
    // Get columns
    const [columns] = await pool.query(`
      SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        IS_NULLABLE,
        COLUMN_DEFAULT,
        CHARACTER_MAXIMUM_LENGTH,
        NUMERIC_PRECISION,
        NUMERIC_SCALE,
        COLUMN_TYPE,
        COLUMN_KEY,
        EXTRA
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?
      ORDER BY ORDINAL_POSITION
    `, [process.env.DB_NAME || 'invoice_db', tableName]);
    
    // Get foreign keys
    const [foreignKeys] = await pool.query(`
      SELECT 
        COLUMN_NAME,
        REFERENCED_TABLE_NAME,
        REFERENCED_COLUMN_NAME,
        CONSTRAINT_NAME
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
      WHERE TABLE_SCHEMA = ? 
        AND TABLE_NAME = ?
        AND REFERENCED_TABLE_NAME IS NOT NULL
    `, [process.env.DB_NAME || 'invoice_db', tableName]);
    
    // Get indexes
    const [indexes] = await pool.query(
      "SHOW INDEX FROM ??",
      [tableName]
    );
    
    schema[tableName] = {
      columns,
      foreignKeys,
      indexes
    };
  }
  
  // Save to file
  fs.writeFileSync(
    './docs/database-schema.json',
    JSON.stringify(schema, null, 2)
  );
  
  console.log('✅ Schema extracted successfully');
  await pool.end();
}

extractSchema().catch(console.error);
```

**دستور اجرا:**
```bash
cd backend
node scripts/extract-schema.js
```

---

### گام 1.2: تولید مستندات Markdown

**مکان:** `backend/scripts/generate-schema-docs.js`

**عملکرد:**
- خواندن `database-schema.json`
- تبدیل به فرمت Markdown قابل خواندن
- نمایش روابط بین جداول
- نمایش نوع داده‌ها و constraints

**Output:** فایل `backend/docs/DATABASE_SCHEMA.md`

**نمونه کد:**
```javascript
const fs = require('fs');

function generateSchemaDocs() {
  const schema = JSON.parse(
    fs.readFileSync('./docs/database-schema.json', 'utf8')
  );
  
  let markdown = '# Database Schema Documentation\n\n';
  markdown += `Generated on: ${new Date().toISOString()}\n\n`;
  markdown += '## Tables\n\n';
  
  for (const [tableName, tableData] of Object.entries(schema)) {
    markdown += `### ${tableName}\n\n`;
    markdown += '| Column | Type | Nullable | Default | Key | Extra |\n';
    markdown += '|--------|------|----------|---------|-----|-------|\n';
    
    for (const col of tableData.columns) {
      markdown += `| ${col.COLUMN_NAME} `;
      markdown += `| ${col.COLUMN_TYPE} `;
      markdown += `| ${col.IS_NULLABLE} `;
      markdown += `| ${col.COLUMN_DEFAULT || 'NULL'} `;
      markdown += `| ${col.COLUMN_KEY || '-'} `;
      markdown += `| ${col.EXTRA || '-'} |\n`;
    }
    
    markdown += '\n';
    
    // Foreign Keys
    if (tableData.foreignKeys.length > 0) {
      markdown += '**Foreign Keys:**\n';
      for (const fk of tableData.foreignKeys) {
        markdown += `- \`${fk.COLUMN_NAME}\` → \`${fk.REFERENCED_TABLE_NAME}.${fk.REFERENCED_COLUMN_NAME}\`\n`;
      }
      markdown += '\n';
    }
    
    // Indexes
    const uniqueIndexes = [...new Set(tableData.indexes.map(i => i.Key_name))];
    if (uniqueIndexes.length > 0) {
      markdown += '**Indexes:**\n';
      for (const idx of uniqueIndexes) {
        const indexCols = tableData.indexes
          .filter(i => i.Key_name === idx)
          .map(i => i.Column_name);
        markdown += `- \`${idx}\` on (${indexCols.join(', ')})\n`;
      }
      markdown += '\n';
    }
    
    markdown += '---\n\n';
  }
  
  fs.writeFileSync('./docs/DATABASE_SCHEMA.md', markdown);
  console.log('✅ Schema documentation generated');
}

generateSchemaDocs();
```

**دستور اجرا:**
```bash
node scripts/generate-schema-docs.js
```

---

### گام 1.3: ایجاد API Contract Specification

**مکان:** `backend/docs/api-contracts/`

**هدف:** برای هر جدول، مشخص کردن:
- چه فیلدهایی در GET برگردانده می‌شوند
- چه فیلدهایی در POST الزامی هستند
- چه فیلدهایی در PUT قابل ویرایش هستند
- چه فیلدهایی read-only هستند

**نمونه:** `backend/docs/api-contracts/customers.json`
```json
{
  "table": "customers",
  "endpoints": {
    "GET /api/customers": {
      "response": {
        "type": "object",
        "properties": {
          "data": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["id", "name", "phone", "email", "company", "address", "creditLimit", "currentDebt", "isActive", "createdAt"],
              "properties": {
                "id": {"type": "string", "format": "uuid", "readOnly": true},
                "name": {"type": "string", "maxLength": 100},
                "phone": {"type": "string", "maxLength": 20},
                "email": {"type": "string", "format": "email", "maxLength": 100},
                "company": {"type": "string", "maxLength": 200},
                "address": {"type": "string"},
                "creditLimit": {"type": "number", "format": "decimal(15,2)"},
                "currentDebt": {"type": "number", "format": "decimal(15,2)"},
                "isActive": {"type": "boolean"},
                "createdAt": {"type": "string", "format": "date-time", "readOnly": true},
                "updatedAt": {"type": "string", "format": "date-time", "readOnly": true}
              }
            }
          },
          "pagination": {
            "type": "object",
            "properties": {
              "page": {"type": "integer"},
              "limit": {"type": "integer"},
              "total": {"type": "integer"},
              "totalPages": {"type": "integer"}
            }
          }
        }
      }
    },
    "POST /api/customers": {
      "request": {
        "type": "object",
        "required": ["name"],
        "properties": {
          "name": {"type": "string", "maxLength": 100},
          "phone": {"type": "string", "maxLength": 20},
          "email": {"type": "string", "format": "email", "maxLength": 100},
          "company": {"type": "string", "maxLength": 200},
          "address": {"type": "string"},
          "creditLimit": {"type": "number", "default": 0},
          "currentDebt": {"type": "number", "default": 0}
        }
      },
      "response": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "name": {"type": "string"},
          "phone": {"type": "string"},
          "email": {"type": "string"},
          "company": {"type": "string"},
          "address": {"type": "string"},
          "creditLimit": {"type": "number"},
          "currentDebt": {"type": "number"},
          "isActive": {"type": "boolean"},
          "createdAt": {"type": "string"}
        }
      }
    },
    "PUT /api/customers/:id": {
      "request": {
        "type": "object",
        "properties": {
          "name": {"type": "string", "maxLength": 100},
          "phone": {"type": "string", "maxLength": 20},
          "email": {"type": "string", "format": "email"},
          "company": {"type": "string"},
          "address": {"type": "string"},
          "creditLimit": {"type": "number"},
          "currentDebt": {"type": "number"},
          "isActive": {"type": "boolean"}
        }
      }
    }
  },
  "fieldMapping": {
    "mysql_to_api": {
      "credit_limit": "creditLimit",
      "current_debt": "currentDebt",
      "is_active": "isActive",
      "created_at": "createdAt",
      "updated_at": "updatedAt"
    }
  },
  "typeConversions": {
    "is_active": {
      "mysqlType": "TINYINT(1)",
      "apiType": "boolean",
      "conversionNote": "MySQL stores as 0/1, API returns true/false"
    },
    "credit_limit": {
      "mysqlType": "DECIMAL(15,2)",
      "apiType": "number",
      "conversionNote": "MySQL DECIMAL becomes JavaScript Number"
    }
  }
}
```

**Action Item:** این فایل را **برای تمام جداول** (users, documents, document_items, ...) تکرار کنید.

---

ادامه در فایل بعدی...
