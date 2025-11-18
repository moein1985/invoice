# پیاده‌سازی Backend برای SIP Phone Integration

## 1. اضافه کردن فیلد phone_numbers به جدول customers

```sql
-- در MySQL Workbench یا terminal اجرا کنید:
ALTER TABLE customers ADD COLUMN phone_numbers JSON DEFAULT NULL;

-- مثال داده:
-- phone_numbers = ["09123456789", "02112345678", "12345678"]
```

## 2. افزودن Route جدید به backend/src/routes/customers.js

در **انتهای فایل** `backend/src/routes/customers.js` این route را اضافه کنید:

```javascript
// GET /api/customers/by-phone/:phoneNumber - جستجوی مشتری با شماره تلفن
router.get('/by-phone/:phoneNumber', authenticate, async (req, res) => {
  try {
    const { phoneNumber } = req.params;
    
    console.log('🔍 Searching for customer with phone:', phoneNumber);
    
    // جستجو در آرایه JSON با JSON_CONTAINS
    const [customers] = await pool.query(
      `SELECT id, name, phone_numbers, email, address, created_at 
       FROM customers 
       WHERE JSON_CONTAINS(phone_numbers, ?, '$')`,
      [`"${phoneNumber}"`]
    );

    if (customers.length === 0) {
      return res.status(404).json({ 
        error: 'مشتری با این شماره تلفن یافت نشد',
        phoneNumber: phoneNumber 
      });
    }

    const customer = customers[0];
    
    // گرفتن آخرین سند این مشتری
    const [documents] = await pool.query(
      `SELECT id, document_number, document_type, total_amount, status, created_at
       FROM documents 
       WHERE customer_id = ?
       ORDER BY created_at DESC
       LIMIT 1`,
      [customer.id]
    );

    res.json({
      customer: {
        id: customer.id,
        name: customer.name,
        phoneNumbers: customer.phone_numbers,
        email: customer.email,
        address: customer.address,
        createdAt: customer.created_at
      },
      lastDocument: documents.length > 0 ? {
        id: documents[0].id,
        documentNumber: documents[0].document_number,
        documentType: documents[0].document_type,
        totalAmount: documents[0].total_amount,
        status: documents[0].status,
        createdAt: documents[0].created_at
      } : null
    });

    console.log('✅ Customer found:', customer.name);
  } catch (error) {
    console.error('❌ Error searching customer by phone:', error);
    res.status(500).json({ error: 'خطا در جستجوی مشتری' });
  }
});
```

## 3. تست API با داده نمونه

```sql
-- اضافه کردن داده نمونه برای تست:
UPDATE customers 
SET phone_numbers = JSON_ARRAY('09123456789', '12345678') 
WHERE name = 'خلیلی';
```

```bash
# تست با curl:
curl -X GET "http://localhost:3000/api/customers/by-phone/12345678" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# انتظار می‌رود:
# {
#   "customer": {
#     "id": "...",
#     "name": "خلیلی",
#     "phoneNumbers": ["09123456789", "12345678"],
#     ...
#   },
#   "lastDocument": {
#     "documentNumber": "INV-001",
#     ...
#   }
# }
```

## 4. راه‌اندازی مجدد Backend

```bash
cd backend
node src/server.js
```

---

**نکته:** اگر جدول customers فعلاً خالی است، با SQL زیر داده نمونه اضافه کنید:

```sql
INSERT INTO customers (id, name, phone_numbers, email, address) 
VALUES (
  UUID(),
  'خلیلی',
  JSON_ARRAY('09123456789', '12345678'),
  'khalili@example.com',
  'تهران'
);
```
