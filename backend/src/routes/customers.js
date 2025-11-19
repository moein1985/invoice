const express = require('express');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const createCustomerSchema = Joi.object({
  name: Joi.string().required(),
  phone: Joi.string().required(),
  email: Joi.string().email().allow(''),
  company: Joi.string().allow(''),
  creditLimit: Joi.number().min(0).default(0),
  currentDebt: Joi.number().min(0).default(0)
});

const updateCustomerSchema = Joi.object({
  name: Joi.string(),
  phone: Joi.string(),
  email: Joi.string().email().allow(''),
  company: Joi.string().allow(''),
  creditLimit: Joi.number().min(0),
  currentDebt: Joi.number().min(0),
  isActive: Joi.boolean()
});

// GET /api/customers
router.get('/', authenticate, async (req, res) => {
  try {
    const { query, isActive, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let sql = 'SELECT id, name, phone, email, company, credit_limit, current_debt, is_active, created_at FROM customers WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM customers WHERE 1=1';
    const params = [];
    const countParams = [];

    if (typeof isActive !== 'undefined') {
      sql += ' AND is_active = ?';
      countSql += ' AND is_active = ?';
      params.push(isActive === 'true' || isActive === '1');
      countParams.push(isActive === 'true' || isActive === '1');
    }

    if (query) {
      sql += ' AND (name LIKE ? OR phone LIKE ? OR email LIKE ? OR company LIKE ?)';
      countSql += ' AND (name LIKE ? OR phone LIKE ? OR email LIKE ? OR company LIKE ?)';
      params.push(`%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`);
      countParams.push(`%${query}%`, `%${query}%`, `%${query}%`, `%${query}%`);
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const [customers] = await pool.query(sql, params);
    const [countResult] = await pool.query(countSql, countParams);
    const total = countResult[0].total;

    res.json({
      data: customers.map(c => ({
        id: c.id,
        name: c.name,
        phone: c.phone,
        email: c.email,
        company: c.company,
        creditLimit: c.credit_limit,
        currentDebt: c.current_debt,
        isActive: c.is_active,
        createdAt: c.created_at
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get customers error:', error);
    res.status(500).json({ error: 'خطا در دریافت مشتریان' });
  }
});

// GET /api/customers/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [customers] = await pool.query(
      'SELECT id, name, phone, email, company, credit_limit, current_debt, is_active, created_at FROM customers WHERE id = ?',
      [req.params.id]
    );

    if (customers.length === 0) {
      return res.status(404).json({ error: 'مشتری یافت نشد' });
    }

    const customer = customers[0];
    res.json({
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      company: customer.company,
      creditLimit: customer.credit_limit,
      currentDebt: customer.current_debt,
      isActive: customer.is_active,
      createdAt: customer.created_at
    });
  } catch (error) {
    console.error('Get customer error:', error);
    res.status(500).json({ error: 'خطا در دریافت مشتری' });
  }
});

// POST /api/customers
router.post('/', authenticate, async (req, res) => {
  try {
    const { error } = createCustomerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { name, phone, email, company, creditLimit, currentDebt } = req.body;

    const id = require('uuid').v4();
    await pool.query(
      'INSERT INTO customers (id, name, phone, email, company, credit_limit, current_debt) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [id, name, phone, email || '', company || '', creditLimit || 0, currentDebt || 0]
    );

    const [newCustomer] = await pool.query(
      'SELECT id, name, phone, email, company, credit_limit, current_debt, is_active, created_at FROM customers WHERE id = ?',
      [id]
    );

    const customer = newCustomer[0];
    res.status(201).json({
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      company: customer.company,
      creditLimit: customer.credit_limit,
      currentDebt: customer.current_debt,
      isActive: customer.is_active,
      createdAt: customer.created_at
    });
  } catch (error) {
    console.error('Create customer error:', error);
    res.status(500).json({ error: 'خطا در ایجاد مشتری' });
  }
});

// PUT /api/customers/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    const { error } = updateCustomerSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const updates = [];
    const values = [];

    if (req.body.name) {
      updates.push('name = ?');
      values.push(req.body.name);
    }
    if (req.body.phone) {
      updates.push('phone = ?');
      values.push(req.body.phone);
    }
    if (req.body.email !== undefined) {
      updates.push('email = ?');
      values.push(req.body.email);
    }
    if (req.body.company !== undefined) {
      updates.push('company = ?');
      values.push(req.body.company);
    }
    if (req.body.creditLimit !== undefined) {
      updates.push('credit_limit = ?');
      values.push(req.body.creditLimit);
    }
    if (req.body.currentDebt !== undefined) {
      updates.push('current_debt = ?');
      values.push(req.body.currentDebt);
    }
    if (typeof req.body.isActive !== 'undefined') {
      updates.push('is_active = ?');
      values.push(req.body.isActive);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'هیچ فیلدی برای بروزرسانی ارسال نشده' });
    }

    values.push(req.params.id);
    await pool.query(`UPDATE customers SET ${updates.join(', ')} WHERE id = ?`, values);

    const [updated] = await pool.query(
      'SELECT id, name, phone, email, company, credit_limit, current_debt, is_active, created_at FROM customers WHERE id = ?',
      [req.params.id]
    );

    if (updated.length === 0) {
      return res.status(404).json({ error: 'مشتری یافت نشد' });
    }

    const customer = updated[0];
    res.json({
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      company: customer.company,
      creditLimit: customer.credit_limit,
      currentDebt: customer.current_debt,
      isActive: customer.is_active,
      createdAt: customer.created_at
    });
  } catch (error) {
    console.error('Update customer error:', error);
    res.status(500).json({ error: 'خطا در بروزرسانی مشتری' });
  }
});

// DELETE /api/customers/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM customers WHERE id = ?', [req.params.id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'مشتری یافت نشد' });
    }

    res.json({ message: 'مشتری با موفقیت حذف شد' });
  } catch (error) {
    console.error('Delete customer error:', error);
    res.status(500).json({ error: 'خطا در حذف مشتری' });
  }
});

// GET /api/customers/by-phone/:phoneNumber - جستجوی مشتری با شماره تلفن (بدون auth برای SIP)
router.get('/by-phone/:phoneNumber', async (req, res) => {
  try {
    const { phoneNumber } = req.params;
    
    console.log('🔍 Searching for customer with phone:', phoneNumber);
    
    // جستجو در آرایه JSON با JSON_CONTAINS
    const [customers] = await pool.query(
      `SELECT id, name, phone_numbers, phone, address, created_at 
       FROM customers 
       WHERE JSON_CONTAINS(phone_numbers, ?, '$')`,
      [`"${phoneNumber}"`]
    );

    if (customers.length === 0) {
      return res.status(404).json({ 
        error: 'مشتری با این شماره تلفن یافت نشد',
        phoneNumber: phoneNumber 
      });
    }

    const customer = customers[0];
    
    // گرفتن آخرین سند این مشتری
    const [documents] = await pool.query(
      `SELECT id, document_number, document_type, total_amount, status, created_at
       FROM documents 
       WHERE customer_id = ?
       ORDER BY created_at DESC
       LIMIT 1`,
      [customer.id]
    );

    res.json({
      customer: {
        id: customer.id,
        name: customer.name,
        phoneNumbers: customer.phone_numbers,
        phone: customer.phone,
        address: customer.address,
        createdAt: customer.created_at
      },
      lastDocument: documents.length > 0 ? {
        id: documents[0].id,
        documentNumber: documents[0].document_number,
        documentType: documents[0].document_type,
        totalAmount: documents[0].total_amount,
        status: documents[0].status,
        createdAt: documents[0].created_at
      } : null
    });

    console.log('✅ Customer found:', customer.name);
  } catch (error) {
    console.error('❌ Error searching customer by phone:', error);
    res.status(500).json({ error: 'خطا در جستجوی مشتری' });
  }
});

module.exports = router;
