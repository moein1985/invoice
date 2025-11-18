// GET /api/documents
router.get('/', authenticate, async (req, res) => {
  try {
    const { type, status, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let query = 'SELECT * FROM documents WHERE 1=1';
    let countQuery = 'SELECT COUNT(*) as total FROM documents WHERE 1=1';
    const params = [];
    const countParams = [];

    if (type) {
      query += ' AND document_type = ?';
      countQuery += ' AND document_type = ?';
      params.push(type);
      countParams.push(type);
    }

    if (status) {
      query += ' AND status = ?';
      countQuery += ' AND status = ?';
      params.push(status);
      countParams.push(status);
    }

    query += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);

    const [documents] = await pool.query(query, params);
    const [countResult] = await pool.query(countQuery, countParams);
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
