const mysql = require('mysql2/promise');
require('dotenv').config();

async function setupDatabase() {
  let connection;
  
  try {
    console.log('📊 شروع تنظیم دیتابیس...\n');
    
    // اتصال به MySQL بدون انتخاب دیتابیس
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      user: 'root', // استفاده از root برای ایجاد دیتابیس
      password: process.env.DB_ROOT_PASSWORD || '12345678',
    });
    
    console.log('✅ اتصال به MySQL برقرار شد');
    
    // بررسی وجود دیتابیس
    const dbName = process.env.DB_NAME || 'invoice_db';
    const [databases] = await connection.query(
      `SHOW DATABASES LIKE '${dbName}'`
    );
    
    if (databases.length === 0) {
      console.log(`⚠️  دیتابیس ${dbName} وجود ندارد - در حال ایجاد...`);
      await connection.query(`CREATE DATABASE ${dbName}`);
      console.log(`✅ دیتابیس ${dbName} ایجاد شد`);
    } else {
      console.log(`✅ دیتابیس ${dbName} موجود است`);
    }
    
    // انتخاب دیتابیس
    await connection.query(`USE ${dbName}`);
    
    // بررسی جدول customers
    const [tables] = await connection.query(`SHOW TABLES LIKE 'customers'`);
    
    if (tables.length === 0) {
      console.log('⚠️  جدول customers وجود ندارد - لطفاً migration ها را اجرا کنید');
      await connection.end();
      return;
    }
    
    console.log('✅ جدول customers موجود است');
    
    // بررسی وجود فیلد phone_numbers
    const [columns] = await connection.query(
      `SHOW COLUMNS FROM customers LIKE 'phone_numbers'`
    );
    
    if (columns.length === 0) {
      console.log('📝 در حال اضافه کردن فیلد phone_numbers...');
      await connection.query(
        `ALTER TABLE customers ADD COLUMN phone_numbers JSON DEFAULT NULL`
      );
      console.log('✅ فیلد phone_numbers اضافه شد');
    } else {
      console.log('✅ فیلد phone_numbers موجود است');
    }
    
    // بررسی داده تست
    const [customers] = await connection.query(
      `SELECT id, name, phone_numbers FROM customers WHERE phone_numbers IS NOT NULL LIMIT 1`
    );
    
    if (customers.length === 0) {
      console.log('\n📝 در حال اضافه کردن داده تست...');
      
      // جستجو برای مشتری با نام شامل "خلیلی"
      const [existingCustomer] = await connection.query(
        `SELECT id FROM customers WHERE name LIKE '%خلیلی%' LIMIT 1`
      );
      
      if (existingCustomer.length > 0) {
        // آپدیت مشتری موجود
        await connection.query(
          `UPDATE customers 
           SET phone_numbers = JSON_ARRAY('09123456789', '12345678') 
           WHERE id = ?`,
          [existingCustomer[0].id]
        );
        console.log('✅ شماره تلفن برای مشتری خلیلی اضافه شد');
      } else {
        // ایجاد مشتری جدید
        const customerId = require('crypto').randomUUID();
        await connection.query(
          `INSERT INTO customers (id, name, phone_numbers, email, address, is_active, created_at) 
           VALUES (?, ?, ?, ?, ?, ?, NOW())`,
          [
            customerId,
            'خلیلی',
            JSON.stringify(['09123456789', '12345678']),
            'khalili@example.com',
            'تهران، میدان آزادی',
            1
          ]
        );
        console.log('✅ مشتری تست (خلیلی) ایجاد شد');
      }
    } else {
      console.log('✅ داده تست موجود است:', customers[0].name);
    }
    
    // نمایش تمام مشتریان با شماره تلفن
    console.log('\n📋 لیست مشتریان با شماره تلفن:');
    const [allCustomers] = await connection.query(
      `SELECT id, name, phone_numbers FROM customers WHERE phone_numbers IS NOT NULL`
    );
    
    if (allCustomers.length > 0) {
      allCustomers.forEach(customer => {
        console.log(`   - ${customer.name}: ${JSON.stringify(customer.phone_numbers)}`);
      });
    } else {
      console.log('   (هیچ مشتری با شماره تلفنی یافت نشد)');
    }
    
    console.log('\n✅ تنظیم دیتابیس با موفقیت انجام شد!');
    console.log('\n📞 برای تست API:');
    console.log('   curl -X POST http://localhost:3000/api/auth/login \\');
    console.log('     -H "Content-Type: application/json" \\');
    console.log('     -d \'{"username":"admin","password":"admin123"}\'');
    console.log('\n   سپس:');
    console.log('   curl http://localhost:3000/api/customers/by-phone/12345678 \\');
    console.log('     -H "Authorization: Bearer YOUR_TOKEN"');
    
  } catch (error) {
    console.error('\n❌ خطا:', error.message);
    
    if (error.code === 'ER_ACCESS_DENIED_ERROR') {
      console.error('\n💡 راهنمایی:');
      console.error('   - رمز عبور root را بررسی کنید');
      console.error('   - متغیر محیطی DB_ROOT_PASSWORD را تنظیم کنید');
    } else if (error.code === 'ECONNREFUSED') {
      console.error('\n💡 راهنمایی:');
      console.error('   - MySQL Server در حال اجرا نیست');
      console.error('   - دستور: net start MySQL80');
    }
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

setupDatabase();
