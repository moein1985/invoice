const express = require('express');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation Schema
const documentsSchema = Joi.object({
  userId: Joi.string().required(),
  documentNumber: Joi.string().required(),
  documentType: Joi.string().required(),
  customerId: Joi.string().required(),
  documentDate: Joi.date().required(),
  totalAmount: Joi.number().required(),
  discount: Joi.number().allow(null, ''),
  finalAmount: Joi.number().required(),
  status: Joi.string().allow(null, ''),
  notes: Joi.string().allow(null, ''),
  attachment: Joi.string().allow(null, ''),
  defaultProfitPercentage: Joi.number().allow(null, ''),
  convertedFromId: Joi.string().allow(null, ''),
  approvalStatus: Joi.string().allow(null, ''),
  approvedBy: Joi.string().allow(null, ''),
  approvedAt: Joi.date().allow(null, ''),
  rejectionReason: Joi.string().allow(null, ''),
  requiresApproval: Joi.number().allow(null, '')
});

// GET /api/documents
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, query } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const params = [];

    let sql = 'SELECT id, user_id, document_number, document_type, customer_id, document_date, total_amount, discount, final_amount, status, notes, attachment, default_profit_percentage, converted_from_id, approval_status, approved_by, approved_at, rejection_reason, requires_approval, created_at, updated_at FROM documents WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM documents WHERE 1=1';

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
        userId: item.user_id,
        documentNumber: item.document_number,
        documentType: item.document_type,
        customerId: item.customer_id,
        documentDate: item.document_date,
        totalAmount: item.total_amount !== null ? parseFloat(item.total_amount) : null,
        discount: item.discount !== null ? parseFloat(item.discount) : null,
        finalAmount: item.final_amount !== null ? parseFloat(item.final_amount) : null,
        status: item.status,
        notes: item.notes,
        attachment: item.attachment,
        defaultProfitPercentage: item.default_profit_percentage !== null ? parseFloat(item.default_profit_percentage) : null,
        convertedFromId: item.converted_from_id,
        approvalStatus: item.approval_status,
        approvedBy: item.approved_by,
        approvedAt: item.approved_at,
        rejectionReason: item.rejection_reason,
        requiresApproval: item.requires_approval === 1,
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
    console.error('Get documents error:', error);
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// GET /api/documents/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, user_id, document_number, document_type, customer_id, document_date, total_amount, discount, final_amount, status, notes, attachment, default_profit_percentage, converted_from_id, approval_status, approved_by, approved_at, rejection_reason, requires_approval, created_at, updated_at FROM documents WHERE id = ?',
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    const item = rows[0];
    res.json({
        id: item.id,
        userId: item.user_id,
        documentNumber: item.document_number,
        documentType: item.document_type,
        customerId: item.customer_id,
        documentDate: item.document_date,
        totalAmount: item.total_amount !== null ? parseFloat(item.total_amount) : null,
        discount: item.discount !== null ? parseFloat(item.discount) : null,
        finalAmount: item.final_amount !== null ? parseFloat(item.final_amount) : null,
        status: item.status,
        notes: item.notes,
        attachment: item.attachment,
        defaultProfitPercentage: item.default_profit_percentage !== null ? parseFloat(item.default_profit_percentage) : null,
        convertedFromId: item.converted_from_id,
        approvalStatus: item.approval_status,
        approvedBy: item.approved_by,
        approvedAt: item.approved_at,
        rejectionReason: item.rejection_reason,
        requiresApproval: item.requires_approval === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at
    });
  } catch (error) {
    console.error('Get documents by id error:', error);
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// POST /api/documents
router.post('/', authenticate, async (req, res) => {
  try {
    const { error, value } = documentsSchema.validate(req.body);
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
      `INSERT INTO documents (${columns}) VALUES (${placeholders})`,
      values
    );

    // Fetch created item
    const [rows] = await pool.query(
      'SELECT id, user_id, document_number, document_type, customer_id, document_date, total_amount, discount, final_amount, status, notes, attachment, default_profit_percentage, converted_from_id, approval_status, approved_by, approved_at, rejection_reason, requires_approval, created_at, updated_at FROM documents WHERE id = ?',
      [id]
    );

    const item = rows[0];
    res.status(201).json({
        id: item.id,
        userId: item.user_id,
        documentNumber: item.document_number,
        documentType: item.document_type,
        customerId: item.customer_id,
        documentDate: item.document_date,
        totalAmount: item.total_amount !== null ? parseFloat(item.total_amount) : null,
        discount: item.discount !== null ? parseFloat(item.discount) : null,
        finalAmount: item.final_amount !== null ? parseFloat(item.final_amount) : null,
        status: item.status,
        notes: item.notes,
        attachment: item.attachment,
        defaultProfitPercentage: item.default_profit_percentage !== null ? parseFloat(item.default_profit_percentage) : null,
        convertedFromId: item.converted_from_id,
        approvalStatus: item.approval_status,
        approvedBy: item.approved_by,
        approvedAt: item.approved_at,
        rejectionReason: item.rejection_reason,
        requiresApproval: item.requires_approval === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at
    });
  } catch (error) {
    console.error('Create documents error:', error);
    res.status(500).json({ error: 'خطا در ایجاد رکورد' });
  }
});

// PUT /api/documents/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    // For PUT, allow partial updates by making all fields optional
    const updateSchema = documentsSchema.fork(
      Object.keys(documentsSchema.describe().keys),
      (schema) => schema.optional()
    );
    
    const { error, value } = updateSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    // Check if exists
    const [check] = await pool.query('SELECT id FROM documents WHERE id = ?', [req.params.id]);
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
        `UPDATE documents SET ${setClause} WHERE id = ?`,
        values
      );
    }

    // Fetch updated item
    const [rows] = await pool.query(
      'SELECT id, user_id, document_number, document_type, customer_id, document_date, total_amount, discount, final_amount, status, notes, attachment, default_profit_percentage, converted_from_id, approval_status, approved_by, approved_at, rejection_reason, requires_approval, created_at, updated_at FROM documents WHERE id = ?',
      [req.params.id]
    );

    const item = rows[0];
    res.json({
        id: item.id,
        userId: item.user_id,
        documentNumber: item.document_number,
        documentType: item.document_type,
        customerId: item.customer_id,
        documentDate: item.document_date,
        totalAmount: item.total_amount !== null ? parseFloat(item.total_amount) : null,
        discount: item.discount !== null ? parseFloat(item.discount) : null,
        finalAmount: item.final_amount !== null ? parseFloat(item.final_amount) : null,
        status: item.status,
        notes: item.notes,
        attachment: item.attachment,
        defaultProfitPercentage: item.default_profit_percentage !== null ? parseFloat(item.default_profit_percentage) : null,
        convertedFromId: item.converted_from_id,
        approvalStatus: item.approval_status,
        approvedBy: item.approved_by,
        approvedAt: item.approved_at,
        rejectionReason: item.rejection_reason,
        requiresApproval: item.requires_approval === 1,
        createdAt: item.created_at,
        updatedAt: item.updated_at
    });
  } catch (error) {
    console.error('Update documents error:', error);
    res.status(500).json({ error: 'خطا در ویرایش رکورد' });
  }
});

// DELETE /api/documents/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM documents WHERE id = ?', [req.params.id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    res.json({ message: 'رکورد با موفقیت حذف شد' });
  } catch (error) {
    console.error('Delete documents error:', error);
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ error: 'این رکورد دارای وابستگی است و قابل حذف نیست' });
    }
    res.status(500).json({ error: 'خطا در حذف رکورد' });
  }
});

module.exports = router;
