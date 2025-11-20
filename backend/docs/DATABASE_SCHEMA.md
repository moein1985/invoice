# Database Schema Documentation

**Database:** invoice_db  
**Extracted:** ۱۴۰۴/۸/۲۹, ۰:۴۶:۱۰  
**Total Tables:** 4

---

## Table: `customers`

### Columns

| Column | Type | Nullable | Default | Key | Extra | Comment |
|--------|------|----------|---------|-----|-------|----------|
| id | varchar(36) | ❌ | - | PRI | - | - |
| name | varchar(100) | ❌ | - | MUL | - | - |
| phone | varchar(20) | ✅ | - | MUL | - | - |
| email | varchar(100) | ✅ | - | - | - | - |
| company | varchar(200) | ✅ | - | - | - | - |
| credit_limit | decimal(15,2) | ✅ | 0.00 | - | - | - |
| current_debt | decimal(15,2) | ✅ | 0.00 | - | - | - |
| address | text | ✅ | - | - | - | - |
| is_active | tinyint(1) | ✅ | 1 | - | - | - |
| created_at | timestamp | ✅ | CURRENT_TIMESTAMP | - | DEFAULT_GENERATED | - |
| updated_at | timestamp | ✅ | CURRENT_TIMESTAMP | - | DEFAULT_GENERATED on update CURRENT_TIMESTAMP | - |
| phone_numbers | json | ✅ | - | - | - | - |

### Indexes

| Index Name | Columns | Unique | Type |
|------------|---------|--------|------|
| idx_name | name | ❌ | BTREE |
| idx_phone | phone | ❌ | BTREE |
| PRIMARY | id | ✅ | BTREE |

### Sample Queries

```sql
-- Select all
SELECT * FROM customers LIMIT 10;

-- Select by ID
SELECT * FROM customers WHERE id = ?;

-- Count records
SELECT COUNT(*) as total FROM customers;
```

### Type Conversions

**MySQL → Dart:**

- `credit_limit` (decimal(15,2)) → `double` (requires `_parseDouble()`)
- `current_debt` (decimal(15,2)) → `double` (requires `_parseDouble()`)
- `is_active` (tinyint(1)) → `bool` (requires `_parseBool()`)
- `created_at` (timestamp) → `DateTime` (use `DateTime.parse()`)
- `updated_at` (timestamp) → `DateTime` (use `DateTime.parse()`)

---

## Table: `document_items`

### Columns

| Column | Type | Nullable | Default | Key | Extra | Comment |
|--------|------|----------|---------|-----|-------|----------|
| id | varchar(36) | ❌ | - | PRI | - | - |
| document_id | varchar(36) | ❌ | - | MUL | - | - |
| product_name | varchar(100) | ❌ | - | - | - | - |
| quantity | decimal(10,2) | ❌ | - | - | - | - |
| unit | varchar(20) | ❌ | - | - | - | - |
| purchase_price | decimal(15,2) | ❌ | - | - | - | - |
| sell_price | decimal(15,2) | ❌ | - | - | - | - |
| total_price | decimal(15,2) | ❌ | - | - | - | - |
| profit_percentage | decimal(5,2) | ❌ | - | - | - | - |
| supplier | varchar(100) | ✅ | - | - | - | - |
| created_at | timestamp | ✅ | CURRENT_TIMESTAMP | - | DEFAULT_GENERATED | - |

### Foreign Keys

| Column | References | Constraint |
|--------|------------|------------|
| document_id | documents.id | document_items_ibfk_1 |

### Indexes

| Index Name | Columns | Unique | Type |
|------------|---------|--------|------|
| idx_document_id | document_id | ❌ | BTREE |
| PRIMARY | id | ✅ | BTREE |

### Sample Queries

```sql
-- Select all
SELECT * FROM document_items LIMIT 10;

-- Select by ID
SELECT * FROM document_items WHERE id = ?;

-- Count records
SELECT COUNT(*) as total FROM document_items;
```

### Type Conversions

**MySQL → Dart:**

- `quantity` (decimal(10,2)) → `double` (requires `_parseDouble()`)
- `purchase_price` (decimal(15,2)) → `double` (requires `_parseDouble()`)
- `sell_price` (decimal(15,2)) → `double` (requires `_parseDouble()`)
- `total_price` (decimal(15,2)) → `double` (requires `_parseDouble()`)
- `profit_percentage` (decimal(5,2)) → `double` (requires `_parseDouble()`)
- `created_at` (timestamp) → `DateTime` (use `DateTime.parse()`)

---

## Table: `documents`

### Columns

| Column | Type | Nullable | Default | Key | Extra | Comment |
|--------|------|----------|---------|-----|-------|----------|
| id | varchar(36) | ❌ | - | PRI | - | - |
| user_id | varchar(36) | ❌ | - | MUL | - | - |
| document_number | varchar(50) | ❌ | - | UNI | - | - |
| document_type | enum('tempProforma','proforma','invoice','returnInvoice') | ❌ | - | MUL | - | - |
| customer_id | varchar(36) | ❌ | - | MUL | - | - |
| document_date | timestamp | ❌ | - | - | - | - |
| total_amount | decimal(15,2) | ❌ | - | - | - | - |
| discount | decimal(15,2) | ✅ | 0.00 | - | - | - |
| final_amount | decimal(15,2) | ❌ | - | - | - | - |
| status | enum('paid','unpaid','pending') | ✅ | unpaid | - | - | - |
| notes | text | ✅ | - | - | - | - |
| attachment | varchar(255) | ✅ | - | - | - | - |
| default_profit_percentage | decimal(5,2) | ✅ | 22.00 | - | - | - |
| converted_from_id | varchar(36) | ✅ | - | MUL | - | - |
| approval_status | enum('notRequired','pending','approved','rejected') | ✅ | notRequired | MUL | - | - |
| approved_by | varchar(36) | ✅ | - | MUL | - | - |
| approved_at | timestamp | ✅ | - | - | - | - |
| rejection_reason | text | ✅ | - | - | - | - |
| requires_approval | tinyint(1) | ✅ | 0 | - | - | - |
| created_at | timestamp | ✅ | CURRENT_TIMESTAMP | MUL | DEFAULT_GENERATED | - |
| updated_at | timestamp | ✅ | CURRENT_TIMESTAMP | - | DEFAULT_GENERATED on update CURRENT_TIMESTAMP | - |

### Foreign Keys

| Column | References | Constraint |
|--------|------------|------------|
| user_id | users.id | documents_ibfk_1 |
| customer_id | customers.id | documents_ibfk_2 |
| converted_from_id | documents.id | documents_ibfk_3 |
| approved_by | users.id | documents_ibfk_4 |

### Indexes

| Index Name | Columns | Unique | Type |
|------------|---------|--------|------|
| approved_by | approved_by | ❌ | BTREE |
| converted_from_id | converted_from_id | ❌ | BTREE |
| document_number | document_number | ✅ | BTREE |
| idx_approval_status | approval_status | ❌ | BTREE |
| idx_created_at | created_at | ❌ | BTREE |
| idx_customer_id | customer_id | ❌ | BTREE |
| idx_document_number | document_number | ❌ | BTREE |
| idx_document_type | document_type | ❌ | BTREE |
| idx_user_id | user_id | ❌ | BTREE |
| PRIMARY | id | ✅ | BTREE |

### Sample Queries

```sql
-- Select all
SELECT * FROM documents LIMIT 10;

-- Select by ID
SELECT * FROM documents WHERE id = ?;

-- Count records
SELECT COUNT(*) as total FROM documents;
```

### Type Conversions

**MySQL → Dart:**

- `document_date` (timestamp) → `DateTime` (use `DateTime.parse()`)
- `total_amount` (decimal(15,2)) → `double` (requires `_parseDouble()`)
- `discount` (decimal(15,2)) → `double` (requires `_parseDouble()`)
- `final_amount` (decimal(15,2)) → `double` (requires `_parseDouble()`)
- `default_profit_percentage` (decimal(5,2)) → `double` (requires `_parseDouble()`)
- `approved_at` (timestamp) → `DateTime` (use `DateTime.parse()`)
- `requires_approval` (tinyint(1)) → `bool` (requires `_parseBool()`)
- `created_at` (timestamp) → `DateTime` (use `DateTime.parse()`)
- `updated_at` (timestamp) → `DateTime` (use `DateTime.parse()`)

---

## Table: `users`

### Columns

| Column | Type | Nullable | Default | Key | Extra | Comment |
|--------|------|----------|---------|-----|-------|----------|
| id | varchar(36) | ❌ | - | PRI | - | - |
| username | varchar(50) | ❌ | - | UNI | - | - |
| password_hash | varchar(255) | ❌ | - | - | - | - |
| full_name | varchar(100) | ❌ | - | - | - | - |
| role | enum('employee','supervisor','manager','admin') | ✅ | employee | MUL | - | - |
| is_active | tinyint(1) | ✅ | 1 | - | - | - |
| created_at | timestamp | ✅ | CURRENT_TIMESTAMP | - | DEFAULT_GENERATED | - |
| updated_at | timestamp | ✅ | CURRENT_TIMESTAMP | - | DEFAULT_GENERATED on update CURRENT_TIMESTAMP | - |

### Indexes

| Index Name | Columns | Unique | Type |
|------------|---------|--------|------|
| idx_role | role | ❌ | BTREE |
| idx_username | username | ❌ | BTREE |
| PRIMARY | id | ✅ | BTREE |
| username | username | ✅ | BTREE |

### Sample Queries

```sql
-- Select all
SELECT * FROM users LIMIT 10;

-- Select by ID
SELECT * FROM users WHERE id = ?;

-- Count records
SELECT COUNT(*) as total FROM users;
```

### Type Conversions

**MySQL → Dart:**

- `is_active` (tinyint(1)) → `bool` (requires `_parseBool()`)
- `created_at` (timestamp) → `DateTime` (use `DateTime.parse()`)
- `updated_at` (timestamp) → `DateTime` (use `DateTime.parse()`)

---

