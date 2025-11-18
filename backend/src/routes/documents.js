const express = require('express');
const { v4: uuidv4 } = require('uuid');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation schemas
const documentItemSchema = Joi.object({
  productName: Joi.string().required(),
  quantity: Joi.number().required(),
  unit: Joi.string().required(),
  purchasePrice: Joi.number().required(),
  sellPrice: Joi.number().required(),
  totalPrice: Joi.number().required(),
  profitPercentage: Joi.number().required(),
  supplier: Joi.string().allow('', null)
});

const documentSchema = Joi.object({
  documentNumber: Joi.string().required(),
  documentType: Joi.string().valid('tempProforma', 'proforma', 'invoice', 'returnInvoice').required(),
  customerId: Joi.string().required(),
  documentDate: Joi.date().required(),
  totalAmount: Joi.number().required(),
  discount: Joi.number().default(0),
  finalAmount: Joi.number().required(),
  status: Joi.string().valid('paid', 'unpaid', 'pending').default('unpaid'),
  notes: Joi.string().allow('', null),
  items: Joi.array().items(documentItemSchema).required()
});

// GET /api/documents
router.get('/', authenticate, async (req, res) => {
  try {
    const { type, status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let sql = 'SELECT * FROM documents WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM documents WHERE 1=1';
    const params = [];
    const countParams = [];

    if (type) {
      sql += ' AND document_type = ?';
      countSql += ' AND document_type = ?';
      params.push(type);
      countParams.push(type);
    }

    if (status) {
      sql += ' AND status = ?';
      countSql += ' AND status = ?';
      params.push(status);
      countParams.push(status);
    }

    sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const [documents] = await pool.query(sql, params);
    const [countResult] = await pool.query(countSql, countParams);
    const total = countResult[0].total;

    // Get items for each document
    for (const doc of documents) {
      const [items] = await pool.query('SELECT * FROM document_items WHERE document_id = ?', [doc.id]);
      doc.items = items;
    }

    res.json({
      data: documents,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get documents error:', error);
    res.status(500).json({ error: 'خطا در دریافت اسناد' });
  }
});

// GET /api/documents/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [documents] = await pool.query('SELECT * FROM documents WHERE id = ?', [req.params.id]);

    if (documents.length === 0) {
      return res.status(404).json({ error: 'سند یافت نشد' });
    }

    const doc = documents[0];
    const [items] = await pool.query('SELECT * FROM document_items WHERE document_id = ?', [doc.id]);
    doc.items = items;

    res.json(doc);
  } catch (error) {
    console.error('Get document error:', error);
    res.status(500).json({ error: 'خطا در دریافت سند' });
  }
});

// POST /api/documents
router.post('/', authenticate, async (req, res) => {
  const connection = await pool.getConnection();

  try {
    await connection.beginTransaction();

    const { error } = documentSchema.validate(req.body);
    if (error) {
      await connection.rollback();
      return res.status(400).json({ error: error.details[0].message });
    }

    const { documentNumber, documentType, customerId, documentDate, totalAmount, discount, finalAmount, status, notes, items } = req.body;
    const id = uuidv4();

    await connection.query(
      'INSERT INTO documents (id, user_id, document_number, document_type, customer_id, document_date, total_amount, discount, final_amount, status, notes, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())',
      [id, req.userId, documentNumber, documentType, customerId, documentDate, totalAmount, discount || 0, finalAmount, status || 'unpaid', notes || null]
    );

    // Insert items
    for (const item of items) {
      const itemId = uuidv4();
      await connection.query(
        'INSERT INTO document_items (id, document_id, product_name, quantity, unit, purchase_price, sell_price, total_price, profit_percentage, supplier, description, is_manual_price) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [itemId, id, item.productName, item.quantity, item.unit, item.purchasePrice, item.sellPrice, item.totalPrice, item.profitPercentage, item.supplier || '', item.description || '', item.isManualPrice || false]
      );
    }

    await connection.commit();

    const [newDocument] = await pool.query('SELECT * FROM documents WHERE id = ?', [id]);
    const doc = newDocument[0];
    const [newItems] = await pool.query('SELECT * FROM document_items WHERE document_id = ?', [doc.id]);
    doc.items = newItems;

    res.status(201).json(doc);
  } catch (error) {
    await connection.rollback();
    console.error('Create document error:', error);
    res.status(500).json({ error: 'خطا در ایجاد سند' });
  } finally {
    connection.release();
  }
});

// PUT /api/documents/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    const updates = [];
    const values = [];

    const m = req.body || {};
    if (m.status) { updates.push('status = ?'); values.push(m.status); }
    if (typeof m.notes !== 'undefined') { updates.push('notes = ?'); values.push(m.notes || null); }
    if (typeof m.approvalStatus !== 'undefined') { updates.push('approval_status = ?'); values.push(m.approvalStatus); }
    if (typeof m.requiresApproval !== 'undefined') { updates.push('requires_approval = ?'); values.push(!!m.requiresApproval); }
    if (typeof m.approvedBy !== 'undefined') { updates.push('approved_by = ?'); values.push(m.approvedBy || null); }
    if (typeof m.approvedAt !== 'undefined') { updates.push('approved_at = ?'); values.push(m.approvedAt ? new Date(m.approvedAt) : null); }
    if (typeof m.rejectionReason !== 'undefined') { updates.push('rejection_reason = ?'); values.push(m.rejectionReason || null); }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    values.push(req.params.id);

    await pool.query(`UPDATE documents SET ${updates.join(', ')}, updated_at = NOW() WHERE id = ?`, values);

    const [rows] = await pool.query('SELECT * FROM documents WHERE id = ?', [req.params.id]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'سند یافت نشد' });
    }
    const doc = rows[0];
    const [items] = await pool.query('SELECT * FROM document_items WHERE document_id = ?', [doc.id]);
    doc.items = items;
    res.json(doc);
  } catch (error) {
    console.error('Update document error:', error);
    res.status(500).json({ error: 'خطا در بروزرسانی سند' });
  }
});

// DELETE /api/documents/:id
router.delete('/:id', authenticate, async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    const [exists] = await connection.query('SELECT id FROM documents WHERE id = ?', [req.params.id]);
    if (exists.length === 0) {
      await connection.rollback();
      return res.status(404).json({ error: 'سند یافت نشد' });
    }
    await connection.query('DELETE FROM document_items WHERE document_id = ?', [req.params.id]);
    await connection.query('DELETE FROM documents WHERE id = ?', [req.params.id]);
    await connection.commit();
    res.json({ message: 'سند با موفقیت حذف شد' });
  } catch (error) {
    await connection.rollback();
    console.error('Delete document error:', error);
    res.status(500).json({ error: 'خطا در حذف سند' });
  } finally {
    connection.release();
  }
});

// GET /api/documents/approvals/pending
router.get('/approvals/pending', authenticate, async (req, res) => {
  try {
    const [documents] = await pool.query(
      'SELECT * FROM documents WHERE approval_status = ? AND document_type = ? ORDER BY created_at DESC',
      ['pending', 'tempProforma']
    );

    for (const doc of documents) {
      const [items] = await pool.query('SELECT * FROM document_items WHERE document_id = ?', [doc.id]);
      doc.items = items;
    }

    res.json(documents);
  } catch (error) {
    console.error('Get pending approvals error:', error);
    res.status(500).json({ error: 'خطا در دریافت اسناد منتظر تایید' });
  }
});

// POST /api/documents/:id/approve
router.post('/:id/approve', authenticate, async (req, res) => {
  try {
    await pool.query(
      'UPDATE documents SET approval_status = ?, approved_by = ?, approved_at = NOW() WHERE id = ?',
      ['approved', req.userId, req.params.id]
    );

    const [updated] = await pool.query('SELECT * FROM documents WHERE id = ?', [req.params.id]);

    if (updated.length === 0) {
      return res.status(404).json({ error: 'سند یافت نشد' });
    }

    res.json(updated[0]);
  } catch (error) {
    console.error('Approve document error:', error);
    res.status(500).json({ error: 'خطا در تایید سند' });
  }
});

// POST /api/documents/:id/reject
router.post('/:id/reject', authenticate, async (req, res) => {
  try {
    const { reason } = req.body;

    if (!reason) {
      return res.status(400).json({ error: 'دلیل رد الزامی است' });
    }

    await pool.query(
      'UPDATE documents SET approval_status = ?, approved_by = ?, approved_at = NOW(), rejection_reason = ? WHERE id = ?',
      ['rejected', req.userId, reason, req.params.id]
    );

    const [updated] = await pool.query('SELECT * FROM documents WHERE id = ?', [req.params.id]);

    if (updated.length === 0) {
      return res.status(404).json({ error: 'سند یافت نشد' });
    }

    res.json(updated[0]);
  } catch (error) {
    console.error('Reject document error:', error);
    res.status(500).json({ error: 'خطا در رد سند' });
  }
});

module.exports = router;
