const express = require('express');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation Schema
const customersSchema = Joi.object({
  name: Joi.string().required(),
  phone: Joi.string().allow(null, ''),
  email: Joi.string().allow(null, '').email(),
  company: Joi.string().allow(null, ''),
  creditLimit: Joi.number().allow(null, ''),
  currentDebt: Joi.number().allow(null, ''),
  address: Joi.string().allow(null, ''),
  isActive: Joi.number().allow(null, ''),
  phoneNumbers: Joi.string().allow(null, '')
});

// GET /api/customers
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, query } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const params = [];

    let sql = 'SELECT id, name, phone, email, company, credit_limit, current_debt, address, is_active, created_at, updated_at, phone_numbers FROM customers WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM customers WHERE 1=1';

    if (query) {
      // Add search logic here based on text columns
      // sql += ' AND (name LIKE ?)';
      // params.push(`%${query}%`);
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const [rows] = await pool.query(sql, params);
    const [countResult] = await pool.query(countSql, params.slice(0, -2));
    const total = countResult[0].total;

    res.json({
      data: rows.map(item => ({
        id: item.id,
        name: item.name,
        phone: item.phone,
        email: item.email,
        company: item.company,
        creditLimit: item.credit_limit !== null ? parseFloat(item.credit_limit) : null,
        currentDebt: item.current_debt !== null ? parseFloat(item.current_debt) : null,
        address: item.address,
        isActive: item.is_active === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
        phoneNumbers: item.phone_numbers
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
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// GET /api/customers/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, name, phone, email, company, credit_limit, current_debt, address, is_active, created_at, updated_at, phone_numbers FROM customers WHERE id = ?',
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    const item = rows[0];
    res.json({
        id: item.id,
        name: item.name,
        phone: item.phone,
        email: item.email,
        company: item.company,
        creditLimit: item.credit_limit !== null ? parseFloat(item.credit_limit) : null,
        currentDebt: item.current_debt !== null ? parseFloat(item.current_debt) : null,
        address: item.address,
        isActive: item.is_active === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
        phoneNumbers: item.phone_numbers
    });
  } catch (error) {
    console.error('Get customers by id error:', error);
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// POST /api/customers
router.post('/', authenticate, async (req, res) => {
  try {
    const { error, value } = customersSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { v4: uuidv4 } = require('uuid');
    const id = uuidv4();
    
    // Map camelCase to snake_case for DB
    const dbData = {
      id: id,
      ...Object.keys(value).reduce((acc, key) => {
        const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
        acc[snakeKey] = value[key];
        return acc;
      }, {})
    };

    const columns = Object.keys(dbData).join(', ');
    const placeholders = Object.keys(dbData).map(() => '?').join(', ');
    const values = Object.values(dbData);

    await pool.query(
      `INSERT INTO customers (${columns}) VALUES (${placeholders})`,
      values
    );

    // Fetch created item
    const [rows] = await pool.query(
      'SELECT id, name, phone, email, company, credit_limit, current_debt, address, is_active, created_at, updated_at, phone_numbers FROM customers WHERE id = ?',
      [id]
    );

    const item = rows[0];
    res.status(201).json({
        id: item.id,
        name: item.name,
        phone: item.phone,
        email: item.email,
        company: item.company,
        creditLimit: item.credit_limit !== null ? parseFloat(item.credit_limit) : null,
        currentDebt: item.current_debt !== null ? parseFloat(item.current_debt) : null,
        address: item.address,
        isActive: item.is_active === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
        phoneNumbers: item.phone_numbers
    });
  } catch (error) {
    console.error('Create customers error:', error);
    res.status(500).json({ error: 'خطا در ایجاد رکورد' });
  }
});

// PUT /api/customers/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    // For PUT, allow partial updates by making all fields optional
    const updateSchema = customersSchema.fork(
      Object.keys(customersSchema.describe().keys),
      (schema) => schema.optional()
    );
    
    const { error, value } = updateSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    // Check if exists
    const [check] = await pool.query('SELECT id FROM customers WHERE id = ?', [req.params.id]);
    if (check.length === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    // Map camelCase to snake_case - only for fields that were sent
    const updates = Object.keys(req.body).reduce((acc, key) => {
      if (value[key] !== undefined) {
        const snakeKey = key.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
        acc[snakeKey] = value[key];
      }
      return acc;
    }, {});

    if (Object.keys(updates).length > 0) {
      const setClause = Object.keys(updates).map(k => `${k} = ?`).join(', ');
      const values = [...Object.values(updates), req.params.id];

      await pool.query(
        `UPDATE customers SET ${setClause} WHERE id = ?`,
        values
      );
    }

    // Fetch updated item
    const [rows] = await pool.query(
      'SELECT id, name, phone, email, company, credit_limit, current_debt, address, is_active, created_at, updated_at, phone_numbers FROM customers WHERE id = ?',
      [req.params.id]
    );

    const item = rows[0];
    res.json({
        id: item.id,
        name: item.name,
        phone: item.phone,
        email: item.email,
        company: item.company,
        creditLimit: item.credit_limit !== null ? parseFloat(item.credit_limit) : null,
        currentDebt: item.current_debt !== null ? parseFloat(item.current_debt) : null,
        address: item.address,
        isActive: item.is_active === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at,
        phoneNumbers: item.phone_numbers
    });
  } catch (error) {
    console.error('Update customers error:', error);
    res.status(500).json({ error: 'خطا در ویرایش رکورد' });
  }
});

// DELETE /api/customers/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM customers WHERE id = ?', [req.params.id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    res.json({ message: 'رکورد با موفقیت حذف شد' });
  } catch (error) {
    console.error('Delete customers error:', error);
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ error: 'این رکورد دارای وابستگی است و قابل حذف نیست' });
    }
    res.status(500).json({ error: 'خطا در حذف رکورد' });
  }
});

module.exports = router;
