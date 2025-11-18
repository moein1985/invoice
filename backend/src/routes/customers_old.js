router.get('/', authenticate, async (req, res) => {
  try {
    const { query, isActive } = req.query;
    
    let sql = 'SELECT * FROM customers WHERE 1=1';
    const params = [];
    
    if (typeof isActive !== 'undefined') {
      sql += ' AND is_active = ?';
      params.push(isActive === 'true' || isActive === '1');
    }
    
    if (query) {
      sql += ' AND (name LIKE ? OR phone LIKE ? OR email LIKE ? OR company LIKE ?)';
      const searchTerm = `%${query}%`;
      params.push(searchTerm, searchTerm, searchTerm, searchTerm);
    }
    
    sql += ' ORDER BY name';
    
    const [customers] = await pool.query(sql, params);

    res.json(customers.map(c => ({
      id: c.id,
      name: c.name,
      phone: c.phone,
      email: c.email,
      address: c.address,
      company: c.company,
      creditLimit: parseFloat(c.credit_limit || 0),
