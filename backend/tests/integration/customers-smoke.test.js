const request = require('supertest');
const express = require('express');
const { setupTestDb, cleanDatabase, closeDatabase, seedTestUser, generateTestToken } = require('./setup');

// Import routes
const customersRouter = require('../../src/routes/customers');

describe('Customers API - Quick Smoke Test', () => {
  let app;
  let authToken;

  beforeAll(async () => {
    setupTestDb();
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    app = express();
    app.use(express.json());
    app.use('/api/customers', customersRouter);
  });

  beforeEach(async () => {
    await cleanDatabase();
    const userId = await seedTestUser();
    authToken = generateTestToken(userId, 'admin');
  });

  afterAll(async () => {
    await closeDatabase();
  });

  test('should create and retrieve a customer', async () => {
    // Create customer
    const newCustomer = {
      name: 'Test Customer',
      phone: '09123456789',
      email: 'test@example.com',
      creditLimit: 10000,
      currentDebt: 0
    };

    const createResponse = await request(app)
      .post('/api/customers')
      .set('Authorization', `Bearer ${authToken}`)
      .send(newCustomer);

    expect(createResponse.status).toBe(201);
    expect(createResponse.body).toHaveProperty('id');
    expect(createResponse.body.name).toBe(newCustomer.name);
    
    // Check type conversions
    expect(typeof createResponse.body.creditLimit).toBe('number');
    expect(createResponse.body.creditLimit).toBe(10000);
    expect(typeof createResponse.body.isActive).toBe('boolean');
    expect(createResponse.body.isActive).toBe(true);

    const customerId = createResponse.body.id;

    // Retrieve customer
    const getResponse = await request(app)
      .get(`/api/customers/${customerId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(getResponse.status).toBe(200);
    expect(getResponse.body.id).toBe(customerId);
    expect(getResponse.body.name).toBe(newCustomer.name);
  });

  test('should update customer', async () => {
    // Create first
    const createResponse = await request(app)
      .post('/api/customers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Original Name', creditLimit: 5000 });

    const customerId = createResponse.body.id;

    // Update
    const updateResponse = await request(app)
      .put(`/api/customers/${customerId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Updated Name', creditLimit: 15000 });

    expect(updateResponse.status).toBe(200);
    expect(updateResponse.body.name).toBe('Updated Name');
    expect(updateResponse.body.creditLimit).toBe(15000);
  });

  test('should handle partial update', async () => {
    // Create first
    const createResponse = await request(app)
      .post('/api/customers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'Test Customer', creditLimit: 5000 });

    const customerId = createResponse.body.id;

    // Partial update (only isActive) - باید 0 یا 1 بفرستیم نه boolean
    const updateResponse = await request(app)
      .put(`/api/customers/${customerId}`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ isActive: 0 }); // تبدیل false به 0

    expect(updateResponse.status).toBe(200);
    expect(updateResponse.body.isActive).toBe(false); // Backend برمی‌گرداند boolean
    expect(updateResponse.body.name).toBe('Test Customer'); // Should remain unchanged
  });

  test('should delete customer', async () => {
    // Create first
    const createResponse = await request(app)
      .post('/api/customers')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ name: 'To Be Deleted' });

    const customerId = createResponse.body.id;

    // Delete
    const deleteResponse = await request(app)
      .delete(`/api/customers/${customerId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(deleteResponse.status).toBe(200);

    // Verify deleted
    const getResponse = await request(app)
      .get(`/api/customers/${customerId}`)
      .set('Authorization', `Bearer ${authToken}`);

    expect(getResponse.status).toBe(404);
  });

  test('should require authentication', async () => {
    const response = await request(app)
      .get('/api/customers')
      .expect(401);
  });
});
