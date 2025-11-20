const mysql = require('mysql2/promise');
require('dotenv').config();

const SQL_SCHEMA = `
-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id VARCHAR(36) PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100) NOT NULL,
  role ENUM('employee', 'supervisor', 'manager', 'admin') DEFAULT 'employee',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_username (username),
  INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Customers Table
CREATE TABLE IF NOT EXISTS customers (
  id VARCHAR(36) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  phone VARCHAR(20),
  email VARCHAR(100) DEFAULT '',
  company VARCHAR(200) DEFAULT '',
  credit_limit DECIMAL(15, 2) DEFAULT 0,
  current_debt DECIMAL(15, 2) DEFAULT 0,
  address TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_name (name),
  INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Documents Table
CREATE TABLE IF NOT EXISTS documents (
  id VARCHAR(36) PRIMARY KEY,
  user_id VARCHAR(36) NOT NULL,
  document_number VARCHAR(50) UNIQUE NOT NULL,
  document_type ENUM('tempProforma', 'proforma', 'invoice', 'returnInvoice') NOT NULL,
  customer_id VARCHAR(36) NOT NULL,
  document_date TIMESTAMP NOT NULL,
  total_amount DECIMAL(15, 2) NOT NULL,
  discount DECIMAL(15, 2) DEFAULT 0,
  final_amount DECIMAL(15, 2) NOT NULL,
  status ENUM('paid', 'unpaid', 'pending') DEFAULT 'unpaid',
  notes TEXT,
  attachment VARCHAR(255),
  default_profit_percentage DECIMAL(5, 2) DEFAULT 22.0,
  converted_from_id VARCHAR(36),
  approval_status ENUM('notRequired', 'pending', 'approved', 'rejected') DEFAULT 'notRequired',
  approved_by VARCHAR(36),
  approved_at TIMESTAMP NULL,
  rejection_reason TEXT,
  requires_approval BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE RESTRICT,
  FOREIGN KEY (converted_from_id) REFERENCES documents(id) ON DELETE SET NULL,
  FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_document_number (document_number),
  INDEX idx_user_id (user_id),
  INDEX idx_customer_id (customer_id),
  INDEX idx_document_type (document_type),
  INDEX idx_approval_status (approval_status),
  INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Document Items Table
CREATE TABLE IF NOT EXISTS document_items (
  id VARCHAR(36) PRIMARY KEY,
  document_id VARCHAR(36) NOT NULL,
  product_name VARCHAR(100) NOT NULL,
  quantity DECIMAL(10, 2) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  purchase_price DECIMAL(15, 2) NOT NULL,
  sell_price DECIMAL(15, 2) NOT NULL,
  total_price DECIMAL(15, 2) NOT NULL,
  profit_percentage DECIMAL(5, 2) NOT NULL,
  supplier VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (document_id) REFERENCES documents(id) ON DELETE CASCADE,
  INDEX idx_document_id (document_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
`;

async function initDatabase() {
  let connection;
  try {
    // اتصال بدون database برای ساخت database
    connection = await mysql.createConnection({
      host: process.env.DB_HOST,
      port: process.env.DB_PORT,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD
    });

    console.log('📦 Connected to MySQL server');

    // ساخت database
    await connection.query(`CREATE DATABASE IF NOT EXISTS ${process.env.DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`);
    console.log(`✅ Database '${process.env.DB_NAME}' created or already exists`);

    await connection.query(`USE ${process.env.DB_NAME}`);

    // اجرای schema
    const statements = SQL_SCHEMA.split(';').filter(s => s.trim());
    for (const statement of statements) {
      if (statement.trim()) {
        await connection.query(statement);
      }
    }
    console.log('✅ Tables created successfully');

    // ساخت admin پیش‌فرض
    const bcrypt = require('bcryptjs');
    const { v4: uuidv4 } = require('uuid');
    
    const adminId = uuidv4();
    const hashedPassword = await bcrypt.hash('admin123', 10);
    
    const [existing] = await connection.query('SELECT id FROM users WHERE username = ?', ['admin']);
    
    if (existing.length === 0) {
      await connection.query(
        'INSERT INTO users (id, username, password_hash, full_name, role) VALUES (?, ?, ?, ?, ?)',
        [adminId, 'admin', hashedPassword, 'مدیر سیستم', 'admin']
      );
      console.log('✅ Default admin user created (username: admin, password: admin123)');
    } else {
      console.log('ℹ️  Admin user already exists');
    }

    console.log('\n🎉 Database initialization completed successfully!\n');
    
  } catch (error) {
    console.error('❌ Database initialization failed:', error.message);
    process.exit(1);
  } finally {
    if (connection) await connection.end();
  }
}

// اگر مستقیماً اجرا شود
if (require.main === module) {
  initDatabase();
}

module.exports = initDatabase;
