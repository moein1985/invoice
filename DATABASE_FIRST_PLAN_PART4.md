# طرح جامع - بخش 4: Contract Testing و Checklist

## 6. مرحله 5: پیاده‌سازی Contract Testing

### گام 5.1: نصب Pact برای Contract Testing

**مفهوم Contract Testing:**
مطمئن می‌شویم Flutter (Consumer) و Backend (Provider) روی یک قرارداد API توافق دارند و هیچکدام آن را نمی‌شکنند.

**نصب در Backend:**
```bash
cd backend
npm install --save-dev @pact-foundation/pact
```

**نصب در Flutter:**
```bash
cd ..
flutter pub add --dev pact_consumer_dart
```

---

### گام 5.2: Consumer Contract (Flutter)

**مکان:** `test/contracts/customer_contract_test.dart`

```dart
import 'package:pact_consumer_dart/pact_consumer_dart.dart';
import 'package:test/test.dart';
import 'package:dio/dio.dart';

void main() {
  late PactMockService mockService;
  late Dio dio;

  setUp(() async {
    mockService = PactMockService(
      consumer: 'InvoiceFlutterApp',
      provider: 'InvoiceBackendAPI',
      port: 1234,
      pactDir: 'test/pacts',
    );

    await mockService.start();
    
    dio = Dio(BaseOptions(
      baseUrl: mockService.baseUrl,
    ));
  });

  tearDown(() async {
    await mockService.writePact();
    await mockService.stop();
  });

  group('Customer API Contract', () {
    test('GET /api/customers returns paginated list', () async {
      // Define expected interaction
      await mockService
          .given('customers exist in database')
          .uponReceiving('a request for all customers')
          .withRequest(
            method: 'GET',
            path: '/api/customers',
            headers: {
              'Authorization': 'Bearer some-token',
            },
          )
          .willRespondWith(
            status: 200,
            headers: {
              'Content-Type': 'application/json',
            },
            body: {
              'data': eachLike({
                'id': like('550e8400-e29b-41d4-a716-446655440000'),
                'name': like('Test Customer'),
                'phone': like('09123456789'),
                'email': like('test@example.com'),
                'company': like('Test Company'),
                'address': like('Test Address'),
                'creditLimit': like(10000.50),
                'currentDebt': like(5000.25),
                'isActive': like(true),
                'createdAt': like('2025-11-20T00:00:00.000Z'),
              }),
              'pagination': like({
                'page': like(1),
                'limit': like(20),
                'total': like(100),
                'totalPages': like(5),
              }),
            },
          );

      // Make actual request
      final response = await dio.get(
        '/api/customers',
        options: Options(headers: {'Authorization': 'Bearer some-token'}),
      );

      // Verify
      expect(response.statusCode, 200);
      expect(response.data['data'], isA<List>());
      expect(response.data['data'][0]['id'], isA<String>());
      expect(response.data['data'][0]['name'], isA<String>());
      expect(response.data['data'][0]['creditLimit'], isA<num>());
      expect(response.data['data'][0]['isActive'], isA<bool>());
      expect(response.data['pagination'], isA<Map>());
    });

    test('POST /api/customers creates new customer', () async {
      final newCustomer = {
        'name': 'New Customer',
        'phone': '09123456789',
        'email': 'new@example.com',
        'company': 'New Company',
        'address': 'New Address',
        'creditLimit': 5000.0,
        'currentDebt': 0.0,
      };

      await mockService
          .given('user is authenticated')
          .uponReceiving('a request to create a customer')
          .withRequest(
            method: 'POST',
            path: '/api/customers',
            headers: {
              'Authorization': 'Bearer some-token',
              'Content-Type': 'application/json',
            },
            body: newCustomer,
          )
          .willRespondWith(
            status: 201,
            headers: {'Content-Type': 'application/json'},
            body: {
              'id': like('550e8400-e29b-41d4-a716-446655440000'),
              ...newCustomer,
              'isActive': true,
              'createdAt': like('2025-11-20T00:00:00.000Z'),
            },
          );

      final response = await dio.post(
        '/api/customers',
        data: newCustomer,
        options: Options(headers: {'Authorization': 'Bearer some-token'}),
      );

      expect(response.statusCode, 201);
      expect(response.data['id'], isA<String>());
      expect(response.data['name'], newCustomer['name']);
      expect(response.data['isActive'], true);
    });

    test('PUT /api/customers/:id updates customer', () async {
      final customerId = '550e8400-e29b-41d4-a716-446655440000';
      final updates = {
        'name': 'Updated Name',
        'creditLimit': 15000.0,
      };

      await mockService
          .given('customer exists with id $customerId')
          .uponReceiving('a request to update customer')
          .withRequest(
            method: 'PUT',
            path: '/api/customers/$customerId',
            headers: {
              'Authorization': 'Bearer some-token',
              'Content-Type': 'application/json',
            },
            body: updates,
          )
          .willRespondWith(
            status: 200,
            headers: {'Content-Type': 'application/json'},
            body: {
              'id': customerId,
              'name': 'Updated Name',
              'phone': like('09123456789'),
              'email': like('test@example.com'),
              'company': like('Test Company'),
              'address': like('Test Address'),
              'creditLimit': 15000.0,
              'currentDebt': like(5000.25),
              'isActive': like(true),
              'createdAt': like('2025-11-20T00:00:00.000Z'),
            },
          );

      final response = await dio.put(
        '/api/customers/$customerId',
        data: updates,
        options: Options(headers: {'Authorization': 'Bearer some-token'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['id'], customerId);
      expect(response.data['name'], 'Updated Name');
      expect(response.data['creditLimit'], 15000.0);
    });

    test('DELETE /api/customers/:id removes customer', () async {
      final customerId = '550e8400-e29b-41d4-a716-446655440000';

      await mockService
          .given('customer exists with id $customerId')
          .uponReceiving('a request to delete customer')
          .withRequest(
            method: 'DELETE',
            path: '/api/customers/$customerId',
            headers: {'Authorization': 'Bearer some-token'},
          )
          .willRespondWith(
            status: 200,
            headers: {'Content-Type': 'application/json'},
            body: {
              'message': like('مشتری با موفقیت حذف شد'),
            },
          );

      final response = await dio.delete(
        '/api/customers/$customerId',
        options: Options(headers: {'Authorization': 'Bearer some-token'}),
      );

      expect(response.statusCode, 200);
      expect(response.data['message'], isA<String>());
    });

    test('GET /api/customers returns 401 without auth', () async {
      await mockService
          .given('no authentication provided')
          .uponReceiving('a request without token')
          .withRequest(
            method: 'GET',
            path: '/api/customers',
          )
          .willRespondWith(
            status: 401,
            headers: {'Content-Type': 'application/json'},
            body: {
              'error': like('Authentication required'),
            },
          );

      try {
        await dio.get('/api/customers');
        fail('Should have thrown DioException');
      } on DioException catch (e) {
        expect(e.response?.statusCode, 401);
      }
    });
  });
}
```

**اجرای تست:**
```bash
flutter test test/contracts/customer_contract_test.dart
```

این تست فایل `test/pacts/InvoiceFlutterApp-InvoiceBackendAPI.json` تولید می‌کند.

---

### گام 5.3: Provider Verification (Backend)

**مکان:** `backend/tests/contract/verify-pact.test.js`

```javascript
const { Verifier } = require('@pact-foundation/pact');
const path = require('path');

describe('Pact Verification', () => {
  test('validates the expectations of InvoiceFlutterApp', async () => {
    const opts = {
      provider: 'InvoiceBackendAPI',
      
      // Path to pact file generated by Flutter
      pactUrls: [
        path.resolve(__dirname, '../../../test/pacts/InvoiceFlutterApp-InvoiceBackendAPI.json')
      ],
      
      // Provider API URL
      providerBaseUrl: 'http://localhost:3000',
      
      // Provider state setup
      stateHandlers: {
        'customers exist in database': async () => {
          // Seed database with test customers
          const pool = require('../../src/config/database');
          await pool.query('DELETE FROM customers');
          await pool.query(`
            INSERT INTO customers (id, name, phone, email, company, address, credit_limit, current_debt, is_active)
            VALUES (
              '550e8400-e29b-41d4-a716-446655440000',
              'Test Customer',
              '09123456789',
              'test@example.com',
              'Test Company',
              'Test Address',
              10000.50,
              5000.25,
              1
            )
          `);
          return 'Customers seeded';
        },
        
        'user is authenticated': async () => {
          // Create test user and return token
          return 'User authenticated';
        },
        
        'customer exists with id 550e8400-e29b-41d4-a716-446655440000': async () => {
          const pool = require('../../src/config/database');
          await pool.query('DELETE FROM customers WHERE id = ?', [
            '550e8400-e29b-41d4-a716-446655440000'
          ]);
          await pool.query(`
            INSERT INTO customers (id, name, phone, email, company, address, credit_limit, current_debt, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
          `, [
            '550e8400-e29b-41d4-a716-446655440000',
            'Test Customer',
            '09123456789',
            'test@example.com',
            'Test Company',
            'Test Address',
            10000.50,
            5000.25,
            1
          ]);
          return 'Customer exists';
        },
        
        'no authentication provided': async () => {
          return 'No auth setup needed';
        }
      },
      
      // Request filters for authentication
      requestFilter: (req, res, next) => {
        // Add valid auth token to requests that need it
        if (req.headers['authorization'] === 'Bearer some-token') {
          // Replace with valid JWT token for testing
          const jwt = require('jsonwebtoken');
          const token = jwt.sign(
            { userId: 'test-user-id', role: 'admin' },
            process.env.JWT_SECRET || 'test-secret'
          );
          req.headers['authorization'] = `Bearer ${token}`;
        }
        next();
      },
      
      publishVerificationResult: false,
      logLevel: 'info',
    };

    const output = await new Verifier(opts).verifyProvider();
    console.log('Pact Verification Complete!');
    console.log(output);
  }, 30000); // 30 second timeout
});
```

**اجرای verification:**
```bash
# Start backend first
npm start

# In another terminal, run verification
npm run test:pact
```

**اضافه کردن به package.json:**
```json
{
  "scripts": {
    "test:pact": "jest tests/contract/verify-pact.test.js"
  }
}
```

---

### گام 5.4: CI/CD Pipeline Integration

**مکان:** `.github/workflows/pact-verification.yml`

```yaml
name: Contract Testing

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  consumer-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run contract tests
        run: flutter test test/contracts/
      
      - name: Upload pact files
        uses: actions/upload-artifact@v3
        with:
          name: pacts
          path: test/pacts/*.json

  provider-verification:
    needs: consumer-tests
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: test_password
          MYSQL_DATABASE: invoice_test
        ports:
          - 3306:3306
        options: >-
          --health-cmd="mysqladmin ping"
          --health-interval=10s
          --health-timeout=5s
          --health-retries=3
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        working-directory: backend
        run: npm ci
      
      - name: Download pact files
        uses: actions/download-artifact@v3
        with:
          name: pacts
          path: test/pacts/
      
      - name: Setup test database
        working-directory: backend
        env:
          DB_HOST: localhost
          DB_USER: root
          DB_PASSWORD: test_password
          DB_NAME: invoice_test
        run: npm run db:setup
      
      - name: Start backend
        working-directory: backend
        env:
          DB_HOST: localhost
          DB_USER: root
          DB_PASSWORD: test_password
          DB_NAME: invoice_test
          JWT_SECRET: test_secret
        run: npm start &
      
      - name: Wait for backend
        run: |
          timeout 30 bash -c 'until curl -f http://localhost:3000/health; do sleep 1; done'
      
      - name: Verify pact
        working-directory: backend
        env:
          DB_HOST: localhost
          DB_USER: root
          DB_PASSWORD: test_password
          DB_NAME: invoice_test
        run: npm run test:pact
```

---

## 7. مرحله 6: Checklist برای هر Feature

### گام 6.1: Template Checklist

**مکان:** `docs/checklists/FEATURE_CHECKLIST.md`

```markdown
# Feature Development Checklist

## Feature: [Feature Name]
**Table:** [MySQL Table Name]
**Developer:** [Your Name]
**Date:** [YYYY-MM-DD]

---

### ✅ Phase 1: Database Schema Validation

- [ ] جدول MySQL موجود است
- [ ] تمام ستون‌های مورد نیاز با نوع داده صحیح ایجاد شده‌اند
- [ ] Index های مناسب اضافه شده‌اند
- [ ] Foreign Key ها تعریف شده‌اند (در صورت نیاز)
- [ ] ON DELETE و ON UPDATE constraints صحیح هستند
- [ ] Default values مناسب تنظیم شده‌اند
- [ ] Test data نمونه در دیتابیس ایجاد شده است

**دستورات تست:**
```sql
DESCRIBE [table_name];
SHOW CREATE TABLE [table_name];
SELECT * FROM [table_name] LIMIT 5;
```

---

### ✅ Phase 2: API Contract Definition

- [ ] فایل API contract در `docs/api-contracts/[table].json` ایجاد شده
- [ ] تمام endpoints (GET, POST, PUT, DELETE) تعریف شده‌اند
- [ ] Request/Response schemas با MySQL schema match می‌کنند
- [ ] Field mappings (snake_case ↔ camelCase) مشخص شده‌اند
- [ ] Type conversions مستند شده‌اند
- [ ] Required fields مشخص شده‌اند
- [ ] Default values مستند شده‌اند

---

### ✅ Phase 3: Backend Implementation

- [ ] Joi validation schema با MySQL جدول match می‌کند
- [ ] GET endpoint:
  - [ ] Pagination پیاده‌سازی شده
  - [ ] Search/filter کار می‌کند
  - [ ] تمام فیلدها در response هستند
  - [ ] snake_case به camelCase تبدیل می‌شود
  - [ ] TINYINT(1) به boolean تبدیل می‌شود
  - [ ] DECIMAL به number تبدیل می‌شود
- [ ] POST endpoint:
  - [ ] تمام فیلدهای required validate می‌شوند
  - [ ] UUID برای id استفاده می‌شود
  - [ ] Default values اعمال می‌شوند
  - [ ] Response شامل تمام فیلدهاست
- [ ] PUT endpoint:
  - [ ] Partial update پشتیبانی می‌شود
  - [ ] فقط فیلدهای ارسال شده update می‌شوند
  - [ ] Validation اعمال می‌شود
- [ ] DELETE endpoint:
  - [ ] Foreign key constraints handle می‌شوند
  - [ ] Soft delete در نظر گرفته شده (اگر نیاز است)
- [ ] Error handling مناسب است
- [ ] Error messages فارسی و معنادار هستند

**دستورات تست:**
```bash
npm run validate-schema
node scripts/generate-route-from-schema.js [table_name]
```

---

### ✅ Phase 4: Backend Integration Tests

- [ ] Setup و teardown test database
- [ ] Test: POST با داده‌های valid
- [ ] Test: POST با داده‌های invalid
- [ ] Test: POST بدون required fields
- [ ] Test: POST با type های اشتباه
- [ ] Test: GET لیست با pagination
- [ ] Test: GET لیست با filter
- [ ] Test: GET لیست خالی
- [ ] Test: GET by ID موفق
- [ ] Test: GET by ID با ID نامعتبر (404)
- [ ] Test: PUT با داده‌های valid
- [ ] Test: PUT partial update
- [ ] Test: PUT با ID نامعتبر (404)
- [ ] Test: DELETE موفق
- [ ] Test: DELETE با ID نامعتبر (404)
- [ ] Test: DELETE با foreign key constraint
- [ ] Test: Authentication required (401)
- [ ] Test: Authorization بر اساس role
- [ ] Test: Type conversion صحیح (bool, decimal)
- [ ] Coverage حداقل 70%

**دستورات تست:**
```bash
npm test -- [table_name].test.js
npm run test:coverage
```

---

### ✅ Phase 5: Flutter Model

- [ ] Model class در `lib/features/[feature]/data/models/` ایجاد شده
- [ ] تمام فیلدهای API در model هستند
- [ ] Type های Dart صحیح هستند (bool, double, DateTime)
- [ ] fromJson با type conversion صحیح پیاده‌سازی شده:
  - [ ] TINYINT(1) → bool
  - [ ] DECIMAL/String → double
  - [ ] timestamp → DateTime
- [ ] toJson برای POST/PUT درست کار می‌کند
- [ ] copyWith برای state management
- [ ] Equatable برای مقایسه اشیاء
- [ ] Null safety رعایت شده
- [ ] Helper functions برای parsing

**نمونه کد:**
```dart
class [Entity]Model extends Equatable {
  final String id;
  final String name;
  // ...
  
  factory [Entity]Model.fromJson(Map<String, dynamic> json) {
    return [Entity]Model(
      id: json['id'],
      name: json['name'],
      isActive: _parseBool(json['isActive']),
      amount: _parseDouble(json['amount']),
    );
  }
  
  static bool _parseBool(dynamic value) { /* ... */ }
  static double _parseDouble(dynamic value) { /* ... */ }
}
```

---

### ✅ Phase 6: Flutter DataSource

- [ ] DataSource در `lib/features/[feature]/data/datasources/` پیاده‌سازی شده
- [ ] getAll() method:
  - [ ] Response format `{data: [], pagination: {}}` handle می‌شود
  - [ ] Fallback برای direct array
  - [ ] Pagination parameters ارسال می‌شوند
  - [ ] Exception logging
- [ ] getById() method پیاده‌سازی شده
- [ ] create() method:
  - [ ] تمام فیلدهای required ارسال می‌شوند
  - [ ] Response parse می‌شود
  - [ ] Error messages معنادار
- [ ] update() method:
  - [ ] Partial update پشتیبانی می‌شود
  - [ ] فقط فیلدهای تغییر یافته ارسال می‌شوند
- [ ] delete() method پیاده‌سازی شده
- [ ] DioException handling با log مناسب
- [ ] Generic exception handling

**نمونه کد:**
```dart
@override
Future<List<[Entity]Model>> getAll() async {
  try {
    final response = await dio.get('/api/[entities]');
    
    // Handle {data: [], pagination: {}}
    if (response.data is Map && response.data.containsKey('data')) {
      final data = response.data['data'];
      if (data is List) {
        return data.map((json) => [Entity]Model.fromJson(json)).toList();
      }
    }
    
    // Fallback for direct array
    if (response.data is List) {
      return (response.data as List)
          .map((json) => [Entity]Model.fromJson(json))
          .toList();
    }
    
    return [];
  } on DioException catch (e) {
    debugPrint('🔴 [DataSource] Error: ${e.type} - ${e.message}');
    debugPrint('🔴 [DataSource] Response: ${e.response?.data}');
    throw CacheException('خطا در دریافت [entities]');
  } catch (e, stackTrace) {
    debugPrint('🔴 [DataSource] Unexpected: $e');
    debugPrint('🔴 [DataSource] Stack: $stackTrace');
    throw CacheException('خطای نامشخص');
  }
}
```

---

### ✅ Phase 7: Flutter Tests

- [ ] Unit tests برای model:
  - [ ] fromJson با داده‌های valid
  - [ ] fromJson با داده‌های null
  - [ ] toJson
  - [ ] copyWith
  - [ ] Equality
- [ ] Mock tests برای datasource:
  - [ ] getAll با mock response
  - [ ] getById
  - [ ] create
  - [ ] update
  - [ ] delete
  - [ ] Exception handling
- [ ] Widget tests برای UI:
  - [ ] List view rendering
  - [ ] Create form validation
  - [ ] Edit form
  - [ ] Delete confirmation

**دستورات تست:**
```bash
flutter test test/features/[feature]/
flutter test --coverage
```

---

### ✅ Phase 8: Contract Testing

- [ ] Consumer contract test (Flutter) نوشته شده
- [ ] تمام endpoints cover شده‌اند
- [ ] Pact file generate شده
- [ ] Provider verification (Backend) موفق است
- [ ] State handlers برای تست setup شده‌اند

**دستورات:**
```bash
flutter test test/contracts/[feature]_contract_test.dart
npm run test:pact
```

---

### ✅ Phase 9: Manual Testing

- [ ] List view:
  - [ ] لیست صحیح نمایش داده می‌شود
  - [ ] Pagination کار می‌کند
  - [ ] Search/filter عمل می‌کند
  - [ ] Empty state نمایش داده می‌شود
  - [ ] Loading state نمایش داده می‌شود
- [ ] Create form:
  - [ ] تمام فیلدها موجود هستند
  - [ ] Validation کار می‌کند
  - [ ] Submit موفق است
  - [ ] Error handling صحیح است
- [ ] Edit form:
  - [ ] داده‌های موجود load می‌شوند
  - [ ] Update موفق است
  - [ ] Partial update کار می‌کند
- [ ] Delete:
  - [ ] Confirmation dialog نمایش داده می‌شود
  - [ ] Delete موفق است
  - [ ] Foreign key error handle می‌شود

---

### ✅ Phase 10: Documentation

- [ ] API endpoint در README مستند شده
- [ ] Model fields شرح داده شده‌اند
- [ ] Business logic توضیح داده شده
- [ ] Edge cases مستند شده‌اند
- [ ] Troubleshooting guide نوشته شده

---

### 📊 Coverage Report

**Backend:**
- Line Coverage: ___%
- Branch Coverage: ___%
- Function Coverage: ___%

**Flutter:**
- Line Coverage: ___%
- Branch Coverage: ___%

---

### ✅ Final Approval

- [ ] Code review انجام شده
- [ ] تمام تست‌ها pass می‌شوند
- [ ] Documentation کامل است
- [ ] Performance مناسب است
- [ ] Security considerations بررسی شده
- [ ] Ready for merge

**Reviewer:** _______________
**Date:** _______________
```

---

### گام 6.2: استفاده از Checklist

برای هر feature جدید یا اصلاح موجود:

1. کپی کردن template
2. تغییر نام به `[feature]_checklist_[date].md`
3. تکمیل مرحله به مرحله
4. Commit کردن همراه با کد

**مثال:**
```bash
cp docs/checklists/FEATURE_CHECKLIST.md docs/checklists/customer_checklist_20251120.md
# Complete checklist items as you work
git add docs/checklists/customer_checklist_20251120.md
git commit -m "feat(customer): Complete customer management feature"
```

---

ادامه در فایل بعدی با خلاصه و دستورات نهایی...
