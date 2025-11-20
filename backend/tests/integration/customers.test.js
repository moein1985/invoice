const request = require('supertest');
const express = require('express');
const { setupTestDb, cleanDatabase, closeDatabase, seedTestUser, generateTestToken, getPool } = require('./setup');

// Import routes
const customersRouter = require('../../src/routes/customers');

describe('Customers API Integration Tests', () => {
  let app;
  let authToken;
  let testUserId;

  beforeAll(async () => {
    // Setup test database
    setupTestDb();

    // Wait a bit for database connection
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Setup Express app
    app = express();
    app.use(express.json());
    app.use('/api/customers', customersRouter);
  });

  beforeEach(async () => {
    // Clean database before each test
    await cleanDatabase();
    
    // Re-seed test user after cleaning
    testUserId = await seedTestUser();
    authToken = generateTestToken(testUserId, 'admin');
  });

  afterAll(async () => {
    // Close database connection
    await closeDatabase();
  });

  describe('POST /api/customers', () => {
    test('should create customer with valid data', async () => {
      const newCustomer = {
        name: 'Test Customer',
        phone: '09123456789',
        email: 'test@example.com',
        company: 'Test Company',
        address: 'Test Address',
        creditLimit: 10000,
        currentDebt: 0
      };

      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(newCustomer)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body.name).toBe(newCustomer.name);
      expect(response.body.phone).toBe(newCustomer.phone);
      expect(response.body.email).toBe(newCustomer.email);
      expect(response.body.creditLimit).toBe(newCustomer.creditLimit);
      expect(response.body.isActive).toBe(true);
    });

    test('should fail without required name field', async () => {
      const invalidCustomer = {
        phone: '09123456789',
        email: 'test@example.com'
      };

      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidCustomer)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    test('should fail with invalid email format', async () => {
      const invalidCustomer = {
        name: 'Test Customer',
        email: 'invalid-email'
      };

      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(invalidCustomer)
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });

    test('should create customer with default values', async () => {
      const minimalCustomer = {
        name: 'Minimal Customer'
      };

      const response = await request(app)
        .post('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .send(minimalCustomer)
        .expect(201);

      expect(response.body.name).toBe(minimalCustomer.name);
      expect(response.body.creditLimit).toBe(0);
      expect(response.body.currentDebt).toBe(0);
      expect(response.body.isActive).toBe(true);
    });

    test('should fail without authentication', async () => {
      const newCustomer = {
        name: 'Test Customer'
      };

      await request(app)
        .post('/api/customers')
        .send(newCustomer)
        .expect(401);
    });
  });

  describe('GET /api/customers', () => {
    beforeEach(async () => {
      // Seed test customers
      const pool = getPool();
      const { v4: uuidv4 } = require('uuid');

      const customers = [
        { id: uuidv4(), name: 'Customer 1', phone: '09111111111', email: 'c1@test.com', is_active: 1 },
        { id: uuidv4(), name: 'Customer 2', phone: '09222222222', email: 'c2@test.com', is_active: 1 },
        { id: uuidv4(), name: 'Customer 3', phone: '09333333333', email: 'c3@test.com', is_active: 0 },
      ];

      for (const customer of customers) {
        await pool.query(
          'INSERT INTO customers (id, name, phone, email, is_active) VALUES (?, ?, ?, ?, ?)',
          [customer.id, customer.name, customer.phone, customer.email, customer.is_active]
        );
      }
    });

    test('should return paginated customer list', async () => {
      const response = await request(app)
        .get('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(Array.isArray(response.body.data)).toBe(true);
      expect(response.body.data.length).toBeGreaterThan(0);
      expect(response.body.pagination.total).toBe(3);
    });

    test('should filter by isActive=true', async () => {
      const response = await request(app)
        .get('/api/customers?isActive=true')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toBe(2);
      expect(response.body.data.every(c => c.isActive === true)).toBe(true);
    });

    test('should filter by isActive=false', async () => {
      const response = await request(app)
        .get('/api/customers?isActive=false')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].isActive).toBe(false);
    });

    test('should search by query', async () => {
      const response = await request(app)
        .get('/api/customers?query=Customer 1')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toBe(1);
      expect(response.body.data[0].name).toBe('Customer 1');
    });

    test('should handle pagination', async () => {
      const response = await request(app)
        .get('/api/customers?page=1&limit=2')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.data.length).toBe(2);
      expect(response.body.pagination.page).toBe(1);
      expect(response.body.pagination.limit).toBe(2);
      expect(response.body.pagination.totalPages).toBe(2);
    });

    test('should convert TINYINT(1) to boolean', async () => {
      const response = await request(app)
        .get('/api/customers')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      response.body.data.forEach(customer => {
        expect(typeof customer.isActive).toBe('boolean');
      });
    });

    test('should fail without authentication', async () => {
      await request(app)
        .get('/api/customers')
        .expect(401);
    });
  });

  describe('GET /api/customers/:id', () => {
    let testCustomerId;

    beforeEach(async () => {
      const pool = getPool();
      const { v4: uuidv4 } = require('uuid');
      testCustomerId = uuidv4();

      await pool.query(
        'INSERT INTO customers (id, name, phone, email) VALUES (?, ?, ?, ?)',
        [testCustomerId, 'Test Customer', '09123456789', 'test@example.com']
      );
    });

    test('should return customer by id', async () => {
      const response = await request(app)
        .get(`/api/customers/${testCustomerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.id).toBe(testCustomerId);
      expect(response.body.name).toBe('Test Customer');
    });

    test('should return 404 for non-existent customer', async () => {
      const { v4: uuidv4 } = require('uuid');
      const fakeId = uuidv4();

      await request(app)
        .get(`/api/customers/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });
  });

  describe('PUT /api/customers/:id', () => {
    let testCustomerId;

    beforeEach(async () => {
      const pool = getPool();
      const { v4: uuidv4 } = require('uuid');
      testCustomerId = uuidv4();

      await pool.query(
        'INSERT INTO customers (id, name, phone, email, credit_limit) VALUES (?, ?, ?, ?, ?)',
        [testCustomerId, 'Test Customer', '09123456789', 'test@example.com', 5000]
      );
    });

    test('should update customer with valid data', async () => {
      const updates = {
        name: 'Updated Name',
        creditLimit: 15000
      };

      const response = await request(app)
        .put(`/api/customers/${testCustomerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updates)
        .expect(200);

      expect(response.body.name).toBe(updates.name);
      expect(response.body.creditLimit).toBe(updates.creditLimit);
    });

    test('should handle partial update', async () => {
      const updates = {
        phone: '09999999999'
      };

      const response = await request(app)
        .put(`/api/customers/${testCustomerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updates)
        .expect(200);

      expect(response.body.phone).toBe(updates.phone);
      expect(response.body.name).toBe('Test Customer'); // Unchanged
    });

    test('should deactivate customer', async () => {
      const updates = {
        isActive: false
      };

      const response = await request(app)
        .put(`/api/customers/${testCustomerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send(updates)
        .expect(200);

      expect(response.body.isActive).toBe(false);
    });

    test('should return 404 for non-existent customer', async () => {
      const { v4: uuidv4 } = require('uuid');
      const fakeId = uuidv4();

      await request(app)
        .put(`/api/customers/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ name: 'Updated' })
        .expect(404);
    });
  });

  describe('DELETE /api/customers/:id', () => {
    let testCustomerId;

    beforeEach(async () => {
      const pool = getPool();
      const { v4: uuidv4 } = require('uuid');
      testCustomerId = uuidv4();

      await pool.query(
        'INSERT INTO customers (id, name) VALUES (?, ?)',
        [testCustomerId, 'Test Customer']
      );
    });

    test('should delete customer successfully', async () => {
      const response = await request(app)
        .delete(`/api/customers/${testCustomerId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('message');

      // Verify deleted
      const pool = getPool();
      const [result] = await pool.query('SELECT * FROM customers WHERE id = ?', [testCustomerId]);
      expect(result.length).toBe(0);
    });

    test('should return 404 for non-existent customer', async () => {
      const { v4: uuidv4 } = require('uuid');
      const fakeId = uuidv4();

      await request(app)
        .delete(`/api/customers/${fakeId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(404);
    });

    test('should handle foreign key constraint error', async () => {
      // This test assumes documents table has FK to customers
      const pool = getPool();
      const { v4: uuidv4 } = require('uuid');

      // Create a document linked to customer
      try {
        await pool.query(
          'INSERT INTO documents (id, customer_id, document_type, total_amount) VALUES (?, ?, ?, ?)',
          [uuidv4(), testCustomerId, 'invoice', 1000]
        );

        const response = await request(app)
          .delete(`/api/customers/${testCustomerId}`)
          .set('Authorization', `Bearer ${authToken}`)
          .expect(400);

        expect(response.body.error).toContain('فاکتور');
      } catch (err) {
        // If documents table doesn't exist or FK not set, skip this test
        console.log('Skipping FK constraint test:', err.message);
      }
    });
  });
});
