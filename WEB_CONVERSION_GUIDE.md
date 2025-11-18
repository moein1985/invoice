# 🌐 راهنمای تبدیل به برنامه تحت وب

## 📋 وضعیت فعلی

**برنامه الان:**
- ✅ Flutter Desktop (Windows/Mac/Linux)
- ✅ Hive Database (Local)
- ✅ BLoC State Management
- ✅ Offline کار می‌کند

---

## 🎯 برای تبدیل به وب نیاز است:

### 1️⃣ **Backend API (سرور)**

#### گزینه A: Python FastAPI ⭐ (پیشنهاد من)
```python
# مثال ساده:
from fastapi import FastAPI, Depends
from sqlalchemy import create_engine
from pydantic import BaseModel

app = FastAPI()

# API Endpoints:
@app.post("/api/auth/login")
@app.get("/api/documents")
@app.post("/api/documents")
@app.put("/api/documents/{id}")
@app.delete("/api/documents/{id}")
@app.post("/api/documents/{id}/approve")
```

**مزایا:**
- سریع و ساده
- خودکار documentation (Swagger)
- پشتیبانی عالی از database
- کم حجم

**زمان توسعه:** 3-4 روز

#### گزینه B: Node.js + Express
```javascript
// مثال:
const express = require('express');
const app = express();

app.post('/api/auth/login', ...);
app.get('/api/documents', ...);
```

**زمان توسعه:** 3-4 روز

---

### 2️⃣ **Database (دیتابیس سرور)**

#### گزینه A: PostgreSQL ⭐ (پیشنهاد)
```sql
-- Tables:
CREATE TABLE users (
    id UUID PRIMARY KEY,
    username VARCHAR UNIQUE,
    password_hash VARCHAR,
    role VARCHAR,
    ...
);

CREATE TABLE documents (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(id),
    approval_status VARCHAR,
    ...
);
```

**مزایا:**
- رایگان و قدرتمند
- پشتیبانی عالی
- مناسب production

#### گزینه B: MySQL
مشابه PostgreSQL ولی کمی ضعیف‌تر

#### گزینه C: MongoDB
برای NoSQL (نه چندان مناسب این پروژه)

---

### 3️⃣ **Flutter Web Build**

```bash
# ساخت نسخه وب:
flutter build web

# فایل‌های output:
build/web/
  ├── index.html
  ├── main.dart.js
  ├── flutter.js
  └── ...
```

**تغییرات لازم در کد:**
```dart
// تغییر از Hive به HTTP calls:

// قبل:
final usersBox = Hive.box<UserModel>('users');
final users = usersBox.values.toList();

// بعد:
final response = await http.get('https://api.yoursite.com/api/users');
final users = (jsonDecode(response.body) as List)
    .map((e) => UserEntity.fromJson(e))
    .toList();
```

---

### 4️⃣ **Authentication (احراز هویت)**

```python
# Backend:
from jose import jwt
from passlib.context import CryptContext

def create_token(user_id: str):
    return jwt.encode({"user_id": user_id}, SECRET_KEY)

# Flutter:
class AuthRepository {
  Future<String> login(String username, String password) async {
    final response = await http.post(
      '$baseUrl/api/auth/login',
      body: {'username': username, 'password': password},
    );
    final token = jsonDecode(response.body)['token'];
    await secureStorage.write(key: 'token', value: token);
    return token;
  }
}
```

---

### 5️⃣ **Hosting (میزبانی)**

#### Backend:
- **DigitalOcean Droplet**: $6/ماه
- **Heroku**: رایگان/محدود
- **AWS EC2**: $5-10/ماه
- **Railway.app**: $5/ماه

#### Frontend (Flutter Web):
- **Vercel**: رایگان ⭐
- **Netlify**: رایگان ⭐
- **Firebase Hosting**: رایگان
- **GitHub Pages**: رایگان

---

## 📅 تایم لاین پیشنهادی

### **هفته 1: Backend Setup**
- روز 1-2: نصب و راه‌اندازی FastAPI + PostgreSQL
- روز 3-4: ایجاد API endpoints برای auth
- روز 5-7: ایجاد API endpoints برای documents

### **هفته 2: Flutter Integration**
- روز 1-2: تبدیل repositories به HTTP-based
- روز 3-4: پیاده‌سازی token authentication
- روز 5-7: تست و debug

### **هفته 3: Deployment**
- روز 1-2: Deploy backend روی server
- روز 3-4: Build و deploy Flutter Web
- روز 5-7: تست production و fix باگ‌ها

---

## 💰 هزینه‌ها

### حداقل (رایگان):
- Backend: Heroku free tier
- Database: PostgreSQL free (Heroku)
- Frontend: Vercel free
- **جمع: 0 تومان/ماه** (محدودیت دارد)

### پیشنهادی:
- Backend: DigitalOcean Droplet ($6)
- Database: PostgreSQL on DigitalOcean
- Frontend: Vercel free
- Domain: Namecheap ($10/سال)
- **جمع: ~$7/ماه + $10/سال**

### حرفه‌ای:
- Backend: AWS EC2 ($20)
- Database: AWS RDS ($15)
- CDN: Cloudflare (رایگان)
- **جمع: ~$35/ماه**

---

## 🛠️ ابزارهای مورد نیاز

```bash
# Backend Development:
pip install fastapi uvicorn sqlalchemy psycopg2 python-jose passlib

# Flutter Web:
flutter channel stable
flutter upgrade
flutter config --enable-web

# Database:
# نصب PostgreSQL از postgresql.org
```

---

## 📝 معماری پیشنهادی

```
┌─────────────────┐
│  Flutter Web    │ (Frontend)
│  (Vercel)       │
└────────┬────────┘
         │ HTTPS/REST API
         ▼
┌─────────────────┐
│  FastAPI        │ (Backend)
│  (DigitalOcean) │
└────────┬────────┘
         │ SQL
         ▼
┌─────────────────┐
│  PostgreSQL     │ (Database)
│  (DigitalOcean) │
└─────────────────┘
```

---

## ✅ مزایای وب

1. **دسترسی همه‌جا**: فقط با مرورگر
2. **بدون نصب**: کاربران نیازی به دانلود ندارند
3. **آپدیت آسان**: یکبار deploy = همه آپدیت می‌شوند
4. **چند کاربره**: همه به یک دیتابیس متصل
5. **موبایل‌محور**: روی گوشی هم کار می‌کند

## ❌ معایب وب

1. **نیاز به اینترنت**: بدون اینترنت کار نمی‌کند (حل: PWA)
2. **سرعت کمتر**: نسبت به native
3. **هزینه سرور**: نیاز به میزبانی
4. **پیچیدگی بیشتر**: backend جداگانه

---

## 🎯 توصیه نهایی

### اگر می‌خواهید:
- ✅ **چند نفر همزمان** کار کنند → وب
- ✅ **از راه دور دسترسی** → وب
- ✅ **روی موبایل هم** باشد → وب
- ✅ **داده‌ها sync** شوند → وب

### اگر:
- ❌ **فقط یک کامپیوتر** استفاده می‌شود → دسکتاپ بمانید
- ❌ **نیازی به اینترنت** نیست → دسکتاپ بهتر است
- ❌ **حریم خصوصی مهم** است → دسکتاپ امن‌تر است

---

## 📞 مراحل بعدی

اگر تصمیم گرفتید وب شود:

1. **ابتدا Backend بسازید** (Python FastAPI)
2. **دیتابیس راه‌اندازی کنید** (PostgreSQL)
3. **API تست کنید** (Postman/Thunder Client)
4. **Flutter را به API وصل کنید**
5. **Deploy کنید**

**آیا می‌خواهید شروع کنیم؟** 🚀
