const express = require('express');
const Joi = require('joi');
const pool = require('../config/database');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

// Validation Schema
const documentItemsSchema = Joi.object({
  documentId: Joi.string().required(),
  productName: Joi.string().required(),
  quantity: Joi.number().required(),
  unit: Joi.string().required(),
  purchasePrice: Joi.number().required(),
  sellPrice: Joi.number().required(),
  totalPrice: Joi.number().required(),
  profitPercentage: Joi.number().required(),
  supplier: Joi.string().allow(null, '')
});

// GET /api/document_items
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 20, query } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);
    const params = [];

    let sql = 'SELECT id, document_id, product_name, quantity, unit, purchase_price, sell_price, total_price, profit_percentage, supplier, created_at FROM document_items WHERE 1=1';
    let countSql = 'SELECT COUNT(*) as total FROM document_items WHERE 1=1';

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
        documentId: item.document_id,
        productName: item.product_name,
        quantity: item.quantity !== null ? parseFloat(item.quantity) : null,
        unit: item.unit,
        purchasePrice: item.purchase_price !== null ? parseFloat(item.purchase_price) : null,
        sellPrice: item.sell_price !== null ? parseFloat(item.sell_price) : null,
        totalPrice: item.total_price !== null ? parseFloat(item.total_price) : null,
        profitPercentage: item.profit_percentage !== null ? parseFloat(item.profit_percentage) : null,
        supplier: item.supplier,
        createdAt: item.created_at
      })),
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        totalPages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get document_items error:', error);
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// GET /api/document_items/:id
router.get('/:id', authenticate, async (req, res) => {
  try {
    const [rows] = await pool.query(
      'SELECT id, document_id, product_name, quantity, unit, purchase_price, sell_price, total_price, profit_percentage, supplier, created_at FROM document_items WHERE id = ?',
      [req.params.id]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    const item = rows[0];
    res.json({
        id: item.id,
        documentId: item.document_id,
        productName: item.product_name,
        quantity: item.quantity !== null ? parseFloat(item.quantity) : null,
        unit: item.unit,
        purchasePrice: item.purchase_price !== null ? parseFloat(item.purchase_price) : null,
        sellPrice: item.sell_price !== null ? parseFloat(item.sell_price) : null,
        totalPrice: item.total_price !== null ? parseFloat(item.total_price) : null,
        profitPercentage: item.profit_percentage !== null ? parseFloat(item.profit_percentage) : null,
        supplier: item.supplier,
        createdAt: item.created_at
    });
  } catch (error) {
    console.error('Get document_items by id error:', error);
    res.status(500).json({ error: 'خطا در دریافت اطلاعات' });
  }
});

// POST /api/document_items
router.post('/', authenticate, async (req, res) => {
  try {
    const { error, value } = documentItemsSchema.validate(req.body);
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
      `INSERT INTO document_items (${columns}) VALUES (${placeholders})`,
      values
    );

    // Fetch created item
    const [rows] = await pool.query(
      'SELECT id, document_id, product_name, quantity, unit, purchase_price, sell_price, total_price, profit_percentage, supplier, created_at FROM document_items WHERE id = ?',
      [id]
    );

    const item = rows[0];
    res.status(201).json({
        id: item.id,
        documentId: item.document_id,
        productName: item.product_name,
        quantity: item.quantity !== null ? parseFloat(item.quantity) : null,
        unit: item.unit,
        purchasePrice: item.purchase_price !== null ? parseFloat(item.purchase_price) : null,
        sellPrice: item.sell_price !== null ? parseFloat(item.sell_price) : null,
        totalPrice: item.total_price !== null ? parseFloat(item.total_price) : null,
        profitPercentage: item.profit_percentage !== null ? parseFloat(item.profit_percentage) : null,
        supplier: item.supplier,
        createdAt: item.created_at
    });
  } catch (error) {
    console.error('Create document_items error:', error);
    res.status(500).json({ error: 'خطا در ایجاد رکورد' });
  }
});

// PUT /api/document_items/:id
router.put('/:id', authenticate, async (req, res) => {
  try {
    // For PUT, allow partial updates by making all fields optional
    const updateSchema = documentItemsSchema.fork(
      Object.keys(documentItemsSchema.describe().keys),
      (schema) => schema.optional()
    );
    
    const { error, value } = updateSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }

    // Check if exists
    const [check] = await pool.query('SELECT id FROM document_items WHERE id = ?', [req.params.id]);
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
        `UPDATE document_items SET ${setClause} WHERE id = ?`,
        values
      );
    }

    // Fetch updated item
    const [rows] = await pool.query(
      'SELECT id, document_id, product_name, quantity, unit, purchase_price, sell_price, total_price, profit_percentage, supplier, created_at FROM document_items WHERE id = ?',
      [req.params.id]
    );

    const item = rows[0];
    res.json({
        id: item.id,
        documentId: item.document_id,
        productName: item.product_name,
        quantity: item.quantity !== null ? parseFloat(item.quantity) : null,
        unit: item.unit,
        purchasePrice: item.purchase_price !== null ? parseFloat(item.purchase_price) : null,
        sellPrice: item.sell_price !== null ? parseFloat(item.sell_price) : null,
        totalPrice: item.total_price !== null ? parseFloat(item.total_price) : null,
        profitPercentage: item.profit_percentage !== null ? parseFloat(item.profit_percentage) : null,
        supplier: item.supplier,
        createdAt: item.created_at
    });
  } catch (error) {
    console.error('Update document_items error:', error);
    res.status(500).json({ error: 'خطا در ویرایش رکورد' });
  }
});

// DELETE /api/document_items/:id
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const [result] = await pool.query('DELETE FROM document_items WHERE id = ?', [req.params.id]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'رکورد یافت نشد' });
    }

    res.json({ message: 'رکورد با موفقیت حذف شد' });
  } catch (error) {
    console.error('Delete document_items error:', error);
    if (error.code === 'ER_ROW_IS_REFERENCED_2') {
      return res.status(400).json({ error: 'این رکورد دارای وابستگی است و قابل حذف نیست' });
    }
    res.status(500).json({ error: 'خطا در حذف رکورد' });
  }
});

module.exports = router;
