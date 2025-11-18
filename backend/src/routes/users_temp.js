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
