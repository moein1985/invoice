# 🚀 Invoice Backend API

Backend REST API برای سیستم مدیریت فاکتور با Node.js + MySQL

## 📦 نصب و راه‌اندازی

### 1. نصب Dependencies

```bash
cd invoice-backend
npm install
```

### 2. تنظیمات دیتابیس

فایل `.env` را از `.env.example` کپی کنید:

```bash
copy .env.example .env
```

در فایل `.env` تنظیمات MySQL را وارد کنید:

```env
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=invoice_db
JWT_SECRET=your-secret-key-here
```

### 3. ساخت دیتابیس و جداول

```bash
npm run init-db
```

این دستور:
- ✅ دیتابیس `invoice_db` را می‌سازد
- ✅ جداول را ایجاد می‌کند
- ✅ کاربر admin پیش‌فرض می‌سازد (username: `admin`, password: `admin123`)

### 4. اجرای سرور

```bash
# Development mode (با nodemon)
npm run dev

# Production mode
npm start
```

سرور روی `http://localhost:3000` اجرا می‌شود.

---

## 📚 API Endpoints

### 🔐 Authentication

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "admin123"
}

Response:
{
  "token": "eyJhbGciOiJIUzI1...",
  "user": {
    "id": "...",
    "username": "admin",
    "fullName": "مدیر سیستم",
    "role": "admin"
  }
}
```

#### Get Current User
```http
GET /api/auth/me
Authorization: Bearer YOUR_TOKEN
```

---

### 👥 Users

#### Get All Users
```http
GET /api/users
Authorization: Bearer YOUR_TOKEN
```

#### Create User
```http
POST /api/users
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "username": "employee1",
  "password": "password123",
  "fullName": "علی احمدی",
  "role": "employee"
}
```

#### Update User
```http
PUT /api/users/:id
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "fullName": "علی احمدی",
  "role": "supervisor",
  "isActive": true
}
```

---

### 🏢 Customers

#### Get All Customers
```http
GET /api/customers
Authorization: Bearer YOUR_TOKEN
```

#### Create Customer
```http
POST /api/customers
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "name": "شرکت ABC",
  "phone": "09123456789",
  "address": "تهران، خیابان ..."
}
```

---

### 📄 Documents

#### Get All Documents
```http
GET /api/documents
Authorization: Bearer YOUR_TOKEN

Query Parameters:
  - type: tempProforma | proforma | invoice | returnInvoice
  - status: paid | unpaid | pending
```

#### Create Document
```http
POST /api/documents
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "documentNumber": "INV-1001",
  "documentType": "invoice",
  "customerId": "customer-uuid",
  "documentDate": "2025-11-18T10:00:00Z",
  "totalAmount": 1000000,
  "discount": 0,
  "finalAmount": 1000000,
  "status": "unpaid",
  "notes": "توضیحات",
  "items": [
    {
      "productName": "محصول A",
      "quantity": 10,
      "unit": "عدد",
      "purchasePrice": 80000,
      "sellPrice": 100000,
      "totalPrice": 1000000,
      "profitPercentage": 25,
      "supplier": "تأمین‌کننده X"
    }
  ]
}
```

#### Get Pending Approvals
```http
GET /api/documents/approvals/pending
Authorization: Bearer YOUR_TOKEN
```

#### Approve Document
```http
POST /api/documents/:id/approve
Authorization: Bearer YOUR_TOKEN
```

#### Reject Document
```http
POST /api/documents/:id/reject
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "reason": "دلیل رد"
}
```

---

## 🔧 تست API

با استفاده از Thunder Client یا Postman:

1. **Login**: `POST http://localhost:3000/api/auth/login`
2. **Copy token** از response
3. در header درخواست‌های بعدی اضافه کنید:
   ```
   Authorization: Bearer YOUR_TOKEN_HERE
   ```

---

## 📊 Database Schema

```sql
users
  - id (UUID)
  - username (UNIQUE)
  - password_hash
  - full_name
  - role (employee | supervisor | manager | admin)
  - is_active
  - created_at

customers
  - id (UUID)
  - name
  - phone
  - address
  - is_active
  - created_at

documents
  - id (UUID)
  - user_id (FK)
  - document_number (UNIQUE)
  - document_type
  - customer_id (FK)
  - approval_status
  - ...

document_items
  - id (UUID)
  - document_id (FK)
  - product_name
  - quantity
  - ...
```

---

## 🌟 Features

- ✅ JWT Authentication
- ✅ Role-based Authorization
- ✅ CRUD Operations for Users/Customers/Documents
- ✅ Approval Workflow
- ✅ Transaction Support
- ✅ Input Validation (Joi)
- ✅ Password Hashing (bcrypt)
- ✅ CORS Support

---

## 🛠️ مشکلات رایج

### خطای اتصال به MySQL
```
Error: ER_ACCESS_DENIED_ERROR
```
**راه حل**: رمز عبور MySQL را در `.env` درست وارد کنید.

### خطای Database not found
```
Error: ER_BAD_DB_ERROR
```
**راه حل**: `npm run init-db` را اجرا کنید.

---

## 📝 License

MIT
