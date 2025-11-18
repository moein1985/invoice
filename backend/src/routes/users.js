const express = require('express');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate, authorize } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const createUserSchema = Joi.object({
  username: Joi.string().min(3).required(),
  password: Joi.string().min(6).required(),
  fullName: Joi.string().required(),
  role: Joi.string().valid('employee', 'supervisor', 'manager', 'admin').default('employee')
});

const updateUserSchema = Joi.object({
  fullName: Joi.string(),
  role: Joi.string().valid('employee', 'supervisor', 'manager', 'admin'),
  isActive: Joi.boolean()
});

// GET /api/users
router.get('/', authenticate, async (req, res) => {
  try {
    const { query, role, isActive, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let sql = 'SELECT id, username, full_name, role, is_active, created_at FROM users WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM users WHERE 1=1';
    const params = [];
    const countParams = [];

    if (role) {
      sql += ' AND role = ?';
      countSql += ' AND role = ?';
      params.push(role);
      countParams.push(role);
    }

    if (typeof isActive !== 'undefined') {
      sql += ' AND is_active = ?';
      countSql += ' AND is_active = ?';
      params.push(isActive === 'true' || isActive === '1');
      countParams.push(isActive === 'true' || isActive === '1');
    }

    if (query) {
      sql += ' AND (username LIKE ? OR full_name LIKE ?)';
      countSql += ' AND (username LIKE ? OR full_name LIKE ?)';
      params.push(`%${query}%`, `%${query}%`);
      countParams.push(`%${query}%`, `%${query}%`);
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const [users] = await pool.query(sql, params);
    const [countResult] = await pool.query(countSql, countParams);
    const total = countResult[0].total;

    res.json({
      data: users.map(u => ({
        id: u.id,
        username: u.username,
        fullName: u.full_name,
        role: u.role,
        isActive: u.is_active,
        createdAt: u.created_at
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
    res.status(500).json({ error: 'خطا در دریافت کاربران' });
  }
});

// GET /api/users/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [users] = await pool.query(
      'SELECT id, username, full_name, role, is_active, created_at FROM users WHERE id = ?',
      [req.params.id]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'کاربر یافت نشد' });
    }

    const user = users[0];
    res.json({
      id: user.id,
      username: user.username,
      fullName: user.full_name,
      role: user.role,
      isActive: user.is_active,
      createdAt: user.created_at
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'خطا در دریافت کاربر' });
  }
});

// POST /api/users
router.post('/', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { error } = createUserSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const { username, password, fullName, role } = req.body;

    // Check if username exists
    const [existing] = await pool.query('SELECT id FROM users WHERE username = ?', [username]);
    if (existing.length > 0) {
      return res.status(400).json({ error: 'نام کاربری تکراری است' });
    }

    const id = uuidv4();
    const hashedPassword = await bcrypt.hash(password, 10);

    await pool.query(
      'INSERT INTO users (id, username, password_hash, full_name, role) VALUES (?, ?, ?, ?, ?)',
      [id, username, hashedPassword, fullName, role || 'employee']
    );

    const [newUser] = await pool.query(
      'SELECT id, username, full_name, role, is_active, created_at FROM users WHERE id = ?',
      [id]
    );

    const user = newUser[0];
    res.status(201).json({
      id: user.id,
      username: user.username,
      fullName: user.full_name,
      role: user.role,
      isActive: user.is_active,
      createdAt: user.created_at
    });
  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ error: 'خطا در ایجاد کاربر' });
  }
});

// PUT /api/users/:id
router.put('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    const { error } = updateUserSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    const updates = [];
    const values = [];

    if (req.body.fullName) {
      updates.push('full_name = ?');
      values.push(req.body.fullName);
    }
    if (req.body.role) {
      updates.push('role = ?');
      values.push(req.body.role);
    }
    if (typeof req.body.isActive !== 'undefined') {
      updates.push('is_active = ?');
      values.push(req.body.isActive);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'هیچ فیلدی برای بروزرسانی ارسال نشده' });
    }

    values.push(req.params.id);
    await pool.query(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, values);

    const [updated] = await pool.query(
      'SELECT id, username, full_name, role, is_active, created_at FROM users WHERE id = ?',
      [req.params.id]
    );

    if (updated.length === 0) {
      return res.status(404).json({ error: 'کاربر یافت نشد' });
    }

    const user = updated[0];
    res.json({
      id: user.id,
      username: user.username,
      fullName: user.full_name,
      role: user.role,
      isActive: user.is_active,
      createdAt: user.created_at
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: 'خطا در بروزرسانی کاربر' });
  }
});

// DELETE /api/users/:id
router.delete('/:id', authenticate, authorize('admin'), async (req, res) => {
  try {
    // Prevent deleting self
    if (req.params.id === req.userId) {
      return res.status(400).json({ error: 'نمی‌توانید حساب خود را حذف کنید' });
    }

    const [result] = await pool.query('DELETE FROM users WHERE id = ?', [req.params.id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'کاربر یافت نشد' });
    }

    res.json({ message: 'کاربر با موفقیت حذف شد' });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ error: 'خطا در حذف کاربر' });
  }
});

module.exports = router;
