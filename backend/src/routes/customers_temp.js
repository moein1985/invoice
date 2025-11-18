// GET /api/customers
router.get('/', authenticate, async (req, res) => {
  try {
    const { query, isActive, page = 1, limit = 20 } = req.query;
    const offset = (parseInt(page) - 1) * parseInt(limit);

    let sql = 'SELECT * FROM customers WHERE 1=1';
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
      const searchTerm = `%${query}%`;
      params.push(searchTerm, searchTerm, searchTerm, searchTerm);
      countParams.push(searchTerm, searchTerm, searchTerm, searchTerm);
    }

    sql += ' ORDER BY name LIMIT ? OFFSET ?';
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
        address: c.address,
        company: c.company,
        creditLimit: parseFloat(c.credit_limit || 0),
        currentDebt: parseFloat(c.current_debt || 0),
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
