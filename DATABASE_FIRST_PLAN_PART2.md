# طرح جامع - بخش 2: Validation و Testing

## 3. مرحله 2: ایجاد ابزارهای Validation

### گام 2.1: Schema Validator Script

**مکان:** `backend/scripts/validate-backend-schema.js`

**هدف:** مقایسه Joi validation schemas در routes با MySQL schema

**نحوه کار:**
1. خواندن `database-schema.json`
2. خواندن Joi schemas از فایل‌های route
3. مقایسه فیلد به فیلد
4. گزارش تفاوت‌ها

**کد کامل:**
```javascript
const fs = require('fs');
const path = require('path');

// Helper: MySQL type to Joi type mapping
function mysqlTypeToJoiType(mysqlType) {
  const typeMap = {
    'varchar': 'string',
    'text': 'string',
    'char': 'string',
    'int': 'number',
    'tinyint': 'number', // or boolean for TINYINT(1)
    'decimal': 'number',
    'float': 'number',
    'double': 'number',
    'timestamp': 'date',
    'datetime': 'date',
    'date': 'date',
    'enum': 'string',
    'json': 'object'
  };
  
  const baseType = mysqlType.toLowerCase().split('(')[0];
  return typeMap[baseType] || 'unknown';
}

async function validateBackendSchema() {
  console.log('🔍 Starting Backend Schema Validation...\n');
  
  // Load MySQL schema
  const mysqlSchema = JSON.parse(
    fs.readFileSync('./docs/database-schema.json', 'utf8')
  );
  
  // Load API contracts
  const contractFiles = fs.readdirSync('./docs/api-contracts')
    .filter(f => f.endsWith('.json'));
  
  let hasErrors = false;
  const results = [];
  
  for (const contractFile of contractFiles) {
    const contract = JSON.parse(
      fs.readFileSync(`./docs/api-contracts/${contractFile}`, 'utf8')
    );
    
    const tableName = contract.table;
    console.log(`📋 Validating table: ${tableName}`);
    
    if (!mysqlSchema[tableName]) {
      console.error(`  ❌ Table '${tableName}' not found in MySQL schema`);
      hasErrors = true;
      continue;
    }
    
    const mysqlColumns = mysqlSchema[tableName].columns;
    const apiFields = contract.endpoints['GET /api/customers']?.response?.properties?.data?.items?.properties || {};
    
    // Check MySQL → API mapping
    for (const col of mysqlColumns) {
      const colName = col.COLUMN_NAME;
      
      // Skip auto-generated fields in validation
      if (['id', 'created_at', 'updated_at'].includes(colName)) {
        continue;
      }
      
      // Check if field exists in API
      const apiFieldName = contract.fieldMapping?.mysql_to_api?.[colName] || colName;
      
      if (!apiFields[apiFieldName]) {
        console.error(`  ❌ MySQL column '${colName}' not found in API response`);
        hasErrors = true;
        continue;
      }
      
      // Check type compatibility
      const mysqlType = mysqlTypeToJoiType(col.DATA_TYPE);
      const apiType = apiFields[apiFieldName].type;
      
      if (mysqlType !== apiType && !(mysqlType === 'number' && apiType === 'boolean')) {
        console.warn(`  ⚠️  Type mismatch: ${colName} (MySQL: ${col.DATA_TYPE} → ${mysqlType}, API: ${apiType})`);
      }
      
      // Check nullable
      if (col.IS_NULLABLE === 'NO' && !contract.endpoints['POST /api/customers']?.request?.required?.includes(apiFieldName)) {
        console.warn(`  ⚠️  Field '${colName}' is NOT NULL in MySQL but not required in POST request`);
      }
    }
    
    console.log(`  ✅ Validation complete for ${tableName}\n`);
  }
  
  if (hasErrors) {
    console.error('\n❌ Schema validation FAILED. Please fix the errors above.\n');
    process.exit(1);
  } else {
    console.log('\n✅ All schemas are valid!\n');
  }
}

validateBackendSchema().catch(console.error);
```

**دستور اجرا:**
```bash
node scripts/validate-backend-schema.js
```

**زمان اجرا:**
- قبل از commit
- در CI/CD pipeline
- قبل از deploy

---

### گام 2.2: ساخت Pre-commit Hook

**مکان:** `.git/hooks/pre-commit`

**محتوا:**
```bash
#!/bin/bash

echo "🔍 Running pre-commit validations..."

# Validate backend schema
cd backend
npm run validate-schema

if [ $? -ne 0 ]; then
  echo ""
  echo "❌ Schema validation failed!"
  echo "Fix the errors above before committing."
  exit 1
fi

echo "✅ All validations passed!"
exit 0
```

**فعال‌سازی:**
```bash
chmod +x .git/hooks/pre-commit
```

**اضافه کردن به package.json:**
```json
{
  "scripts": {
    "validate-schema": "node scripts/validate-backend-schema.js",
    "extract-schema": "node scripts/extract-schema.js",
    "generate-docs": "node scripts/generate-schema-docs.js",
    "sync-all": "npm run extract-schema && npm run generate-docs && npm run validate-schema"
  }
}
```

---

## 4. مرحله 3: نوشتن Integration Tests

### گام 3.1: نصب ابزارهای تست

**دستورات:**
```bash
cd backend
npm install --save-dev jest supertest @types/jest @types/supertest
npm install --save-dev mysql2
```

**فایل پیکربندی:** `backend/jest.config.js`
```javascript
module.exports = {
  testEnvironment: 'node',
  coveragePathIgnorePatterns: ['/node_modules/'],
  testMatch: ['**/__tests__/**/*.js', '**/?(*.)+(spec|test).js'],
  collectCoverageFrom: [
    'src/**/*.js',
    '!src/server.js',
    '!src/config/**'
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  }
};
```

---

### گام 3.2: Setup Test Database

**مکان:** `backend/tests/setup.js`

```javascript
const mysql = require('mysql2/promise');
require('dotenv').config();

let pool;

async function setupTestDatabase() {
  pool = await mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD,
    database: process.env.TEST_DB_NAME || 'invoice_test',
    waitForConnections: true,
    connectionLimit: 10
  });
  
  // Clear all tables
  const tables = ['document_items', 'documents', 'customers', 'users'];
  for (const table of tables) {
    await pool.query(`DELETE FROM ${table}`);
  }
  
  console.log('✅ Test database ready');
  return pool;
}

async function teardownTestDatabase() {
  if (pool) {
    await pool.end();
  }
}

module.exports = { setupTestDatabase, teardownTestDatabase };
```

---

### گام 3.3: Integration Test برای Customers

**مکان:** `backend/tests/customers.test.js`

```javascript
const request = require('supertest');
const { setupTestDatabase, teardownTestDatabase } = require('./setup');
const app = require('../src/server');

let authToken;
let testUserId;

beforeAll(async () => {
  await setupTestDatabase();
  
  // Create test user
  const signupRes = await request(app)
    .post('/api/auth/signup')
    .send({
      username: 'testuser',
      password: 'Test1234!',
      fullName: 'Test User',
      role: 'admin'
    });
  
  testUserId = signupRes.body.user.id;
  authToken = signupRes.body.token;
});

afterAll(async () => {
  await teardownTestDatabase();
});

describe('Customer API Integration Tests', () => {
  
  describe('POST /api/customers', () => {
    test('should create customer with all required fields', async () => {
      const newCustomer = {
        name: 'Test Customer',
        phone: '09123456789',
        email: 'test@example.com',
        company: 'Test Company',
        address: 'Test Address',
        creditLimit: 10000.50,
        currentDebt: 5000.25
      };
      
      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(newCustomer)
        .expect(201);
      
      // Validate response structure
      expect(response.body).toHaveProperty('id');
      expect(response.body.name).toBe(newCustomer.name);
      expect(response.body.phone).toBe(newCustomer.phone);
      expect(response.body.email).toBe(newCustomer.email);
      expect(response.body.company).toBe(newCustomer.company);
      expect(response.body.address).toBe(newCustomer.address);
      expect(response.body.creditLimit).toBe(newCustomer.creditLimit);
      expect(response.body.currentDebt).toBe(newCustomer.currentDebt);
      expect(response.body.isActive).toBe(true);
      expect(response.body).toHaveProperty('createdAt');
      
      // Validate UUID format
      expect(response.body.id).toMatch(
        /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
      );
    });
    
    test('should fail when required field is missing', async () => {
      const invalidCustomer = {
        phone: '09123456789'
        // name is missing
      };
      
      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidCustomer)
        .expect(400);
      
      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toContain('required');
    });
    
    test('should handle invalid email format', async () => {
      const invalidCustomer = {
        name: 'Test',
        phone: '09123456789',
        email: 'not-an-email'
      };
      
      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidCustomer)
        .expect(400);
      
      expect(response.body.error).toContain('email');
    });
    
    test('should set default values for optional fields', async () => {
      const minimalCustomer = {
        name: 'Minimal Customer',
        phone: '09123456789'
      };
      
      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(minimalCustomer)
        .expect(201);
      
      expect(response.body.creditLimit).toBe(0);
      expect(response.body.currentDebt).toBe(0);
      expect(response.body.isActive).toBe(true);
    });
  });
  
  describe('GET /api/customers', () => {
    let customerId;
    
    beforeEach(async () => {
      // Create test customer
      const res = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Get Test Customer',
          phone: '09111111111',
          email: 'get@test.com',
          company: 'Get Test Co',
          address: 'Get Test Address',
          creditLimit: 5000,
          currentDebt: 1000
        });
      
      customerId = res.body.id;
    });
    
    test('should return paginated list of customers', async () => {
      const response = await request(app)
        .get('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
      
      // Validate first customer structure
      const customer = response.body.data[0];
      expect(customer).toHaveProperty('id');
      expect(customer).toHaveProperty('name');
      expect(customer).toHaveProperty('phone');
      expect(customer).toHaveProperty('email');
      expect(customer).toHaveProperty('company');
      expect(customer).toHaveProperty('address');
      expect(customer).toHaveProperty('creditLimit');
      expect(customer).toHaveProperty('currentDebt');
      expect(customer).toHaveProperty('isActive');
      expect(customer).toHaveProperty('createdAt');
    });
    
    test('should filter by query string', async () => {
      const response = await request(app)
        .get('/api/customers?query=Get%20Test')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      expect(response.body.data.length).toBeGreaterThan(0);
      expect(response.body.data[0].name).toContain('Get Test');
    });
    
    test('should paginate correctly', async () => {
      // Create multiple customers
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/api/customers')
          .set('Authorization', `Bearer ${authToken}`)
          .send({
            name: `Pagination Test ${i}`,
            phone: `0912345678${i}`
          });
      }
      
      const page1 = await request(app)
        .get('/api/customers?page=1&limit=3')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      expect(page1.body.data.length).toBe(3);
      expect(page1.body.pagination.page).toBe(1);
      expect(page1.body.pagination.limit).toBe(3);
      
      const page2 = await request(app)
        .get('/api/customers?page=2&limit=3')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      expect(page2.body.pagination.page).toBe(2);
      expect(page2.body.data[0].id).not.toBe(page1.body.data[0].id);
    });
  });
  
  describe('GET /api/customers/:id', () => {
    let customerId;
    
    beforeEach(async () => {
      const res = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'GetById Test',
          phone: '09122222222'
        });
      
      customerId = res.body.id;
    });
    
    test('should return single customer by id', async () => {
      const response = await request(app)
        .get(`/api/customers/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      expect(response.body.id).toBe(customerId);
      expect(response.body.name).toBe('GetById Test');
    });
    
    test('should return 404 for non-existent customer', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      await request(app)
        .get(`/api/customers/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });
  
  describe('PUT /api/customers/:id', () => {
    let customerId;
    
    beforeEach(async () => {
      const res = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Update Test',
          phone: '09133333333',
          email: 'update@test.com',
          creditLimit: 3000
        });
      
      customerId = res.body.id;
    });
    
    test('should update customer fields', async () => {
      const updates = {
        name: 'Updated Name',
        creditLimit: 5000,
        company: 'New Company'
      };
      
      const response = await request(app)
        .put(`/api/customers/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updates)
        .expect(200);
      
      expect(response.body.name).toBe(updates.name);
      expect(response.body.creditLimit).toBe(updates.creditLimit);
      expect(response.body.company).toBe(updates.company);
      
      // Unchanged fields should remain
      expect(response.body.phone).toBe('09133333333');
      expect(response.body.email).toBe('update@test.com');
    });
    
    test('should handle partial updates', async () => {
      const updates = {
        name: 'Partial Update'
      };
      
      const response = await request(app)
        .put(`/api/customers/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updates)
        .expect(200);
      
      expect(response.body.name).toBe('Partial Update');
      expect(response.body.phone).toBe('09133333333');
    });
    
    test('should deactivate customer', async () => {
      const response = await request(app)
        .put(`/api/customers/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ isActive: false })
        .expect(200);
      
      expect(response.body.isActive).toBe(false);
    });
  });
  
  describe('DELETE /api/customers/:id', () => {
    let customerId;
    
    beforeEach(async () => {
      const res = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Delete Test',
          phone: '09144444444'
        });
      
      customerId = res.body.id;
    });
    
    test('should delete customer', async () => {
      await request(app)
        .delete(`/api/customers/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
      
      // Verify deletion
      await request(app)
        .get(`/api/customers/${customerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
    
    test('should return 404 when deleting non-existent customer', async () => {
      const fakeId = '00000000-0000-0000-0000-000000000000';
      
      await request(app)
        .delete(`/api/customers/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });
  
  describe('Type Conversions', () => {
    test('should correctly convert MySQL TINYINT(1) to boolean', async () => {
      const res = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Type Test',
          phone: '09155555555'
        });
      
      expect(typeof res.body.isActive).toBe('boolean');
      expect(res.body.isActive).toBe(true);
    });
    
    test('should correctly convert MySQL DECIMAL to number', async () => {
      const res = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          name: 'Decimal Test',
          phone: '09166666666',
          creditLimit: 12345.67,
          currentDebt: 9876.54
        });
      
      expect(typeof res.body.creditLimit).toBe('number');
      expect(typeof res.body.currentDebt).toBe('number');
      expect(res.body.creditLimit).toBe(12345.67);
      expect(res.body.currentDebt).toBe(9876.54);
    });
  });
  
  describe('Authentication & Authorization', () => {
    test('should reject request without token', async () => {
      await request(app)
        .get('/api/customers')
        .expect(401);
    });
    
    test('should reject request with invalid token', async () => {
      await request(app)
        .get('/api/customers')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });
});
```

---

### گام 3.4: اجرای تست‌ها

**دستورات:**
```bash
# Run all tests
npm test

# Run with coverage
npm run test:coverage

# Run specific test file
npm test -- customers.test.js

# Run in watch mode
npm test -- --watch
```

**اضافه کردن به package.json:**
```json
{
  "scripts": {
    "test": "jest",
    "test:coverage": "jest --coverage",
    "test:watch": "jest --watch",
    "test:api": "jest tests/api"
  }
}
```

---

ادامه در فایل بعدی...
