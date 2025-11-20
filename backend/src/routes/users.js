const express = require('express');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation Schema
const usersSchema = Joi.object({
  username: Joi.string().required(),
  passwordHash: Joi.string().required(),
  fullName: Joi.string().required(),
  role: Joi.string().allow(null, ''),
  isActive: Joi.number().allow(null, '')
});

// GET /api/users
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, query } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const params = [];

    let sql = 'SELECT id, username, password_hash, full_name, role, is_active, created_at, updated_at FROM users WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM users WHERE 1=1';

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
        username: item.username,
        passwordHash: item.password_hash,
        fullName: item.full_name,
        role: item.role,
        isActive: item.is_active === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// GET /api/users/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, username, password_hash, full_name, role, is_active, created_at, updated_at FROM users WHERE id = ?',
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    const item = rows[0];
    res.json({
        id: item.id,
        username: item.username,
        passwordHash: item.password_hash,
        fullName: item.full_name,
        role: item.role,
        isActive: item.is_active === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at
    });
  } catch (error) {
    console.error('Get users by id error:', error);
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// POST /api/users
router.post('/', authenticate, async (req, res) => {
  try {
    const { error, value } = usersSchema.validate(req.body);
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
      `INSERT INTO users (${columns}) VALUES (${placeholders})`,
      values
    );

    // Fetch created item
    const [rows] = await pool.query(
      'SELECT id, username, password_hash, full_name, role, is_active, created_at, updated_at FROM users WHERE id = ?',
      [id]
    );

    const item = rows[0];
    res.status(201).json({
        id: item.id,
        username: item.username,
        passwordHash: item.password_hash,
        fullName: item.full_name,
        role: item.role,
        isActive: item.is_active === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at
    });
  } catch (error) {
    console.error('Create users error:', error);
    res.status(500).json({ error: 'خطا در ایجاد رکورد' });
  }
});

// PUT /api/users/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    // For PUT, allow partial updates by making all fields optional
    const updateSchema = usersSchema.fork(
      Object.keys(usersSchema.describe().keys),
      (schema) => schema.optional()
    );
    
    const { error, value } = updateSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    // Check if exists
    const [check] = await pool.query('SELECT id FROM users WHERE id = ?', [req.params.id]);
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
        `UPDATE users SET ${setClause} WHERE id = ?`,
        values
      );
    }

    // Fetch updated item
    const [rows] = await pool.query(
      'SELECT id, username, password_hash, full_name, role, is_active, created_at, updated_at FROM users WHERE id = ?',
      [req.params.id]
    );

    const item = rows[0];
    res.json({
        id: item.id,
        username: item.username,
        passwordHash: item.password_hash,
        fullName: item.full_name,
        role: item.role,
        isActive: item.is_active === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at
    });
  } catch (error) {
    console.error('Update users error:', error);
    res.status(500).json({ error: 'خطا در ویرایش رکورد' });
  }
});

// DELETE /api/users/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM users WHERE id = ?', [req.params.id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    res.json({ message: 'رکورد با موفقیت حذف شد' });
  } catch (error) {
    console.error('Delete users error:', error);
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ error: 'این رکورد دارای وابستگی است و قابل حذف نیست' });
    }
    res.status(500).json({ error: 'خطا در حذف رکورد' });
  }
});

module.exports = router;
