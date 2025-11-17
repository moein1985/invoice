# ✅ چک‌لیست تکمیل پیاده‌سازی Approval Workflow

تاریخ تکمیل: 18 نوامبر 2025
پیاده‌ساز: Grok AI + GitHub Copilot

---

## 📦 فاز 1: زیرساخت و Enum ها (✅ تکمیل شده)

- [x] `lib/core/enums/approval_status.dart` - ایجاد شد
- [x] `lib/core/enums/user_role.dart` - ایجاد شد
- [x] فیلدهای approval به `DocumentEntity` اضافه شد
- [x] فیلدهای approval به `DocumentModel` اضافه شد (@HiveField 17-21)
- [x] فیلد `role` به `UserEntity` اضافه شد
- [x] فیلد `role` به `UserModel` اضافه شد (@HiveField 4)
- [x] TypeAdapter ها generate شدند (`build_runner`)
- [x] دیتابیس Hive پاک شد

---

## 📝 فاز 2: UseCase ها (✅ تکمیل شده)

- [x] `lib/features/document/domain/usecases/request_approval_usecase.dart`
- [x] `lib/features/document/domain/usecases/approve_document_usecase.dart`
- [x] `lib/features/document/domain/usecases/reject_document_usecase.dart`
- [x] `lib/features/document/domain/usecases/get_pending_approvals_usecase.dart`

---

## 🎨 فاز 3: رابط کاربری (✅ تکمیل شده)

- [x] `lib/features/document/presentation/pages/approval_queue_page.dart`
- [x] `lib/features/document/presentation/widgets/approval_card.dart`

---

## 🧩 فاز 4: BLoC (✅ تکمیل شده)

- [x] `lib/features/document/presentation/bloc/approval_event.dart`
- [x] `lib/features/document/presentation/bloc/approval_state.dart`
- [x] `lib/features/document/presentation/bloc/approval_bloc.dart`

---

## 🔄 فاز 5: Polling Service (✅ تکمیل شده)

- [x] `lib/core/services/approval_polling_service.dart`
- [x] ثبت در `injection_container.dart`

---

## 🔧 فاز 6: Dependency Injection (✅ تکمیل شده)

- [x] ثبت UseCase ها در `injection_container.dart`
- [x] ثبت ApprovalBloc در `injection_container.dart`
- [x] ثبت ApprovalPollingService در `injection_container.dart`

---

## ✅ فاز 7: تست‌ها (✅ فیکس شده)

- [x] تست‌های document فیکس شدند (approvalStatus اضافه شد)
- [x] تست‌های user management فیکس شدند (UserRole.employee)
- [x] همه خطاهای کامپایل برطرف شدند
- [ ] ⚠️ 5 فایل تست unused import دارند (قابل نادیده گرفتن)

---

## 🚀 فاز 8: پیاده‌سازی در UI اصلی (⏳ در انتظار)

### کارهای باقی‌مانده:

#### 8.1 اضافه کردن دکمه "درخواست تأیید" در DocumentListPage
**فایل**: `lib/features/document/presentation/pages/document_list_page.dart`

```dart
// در متد _buildActionButtons:
if (document.documentType == DocumentType.tempProforma) {
  if (document.approvalStatus == ApprovalStatus.pending) {
    return Chip(
      avatar: const Icon(Icons.schedule, size: 18),
      label: const Text('منتظر تأیید'),
      backgroundColor: Colors.orange.shade100,
    );
  } else if (document.approvalStatus == ApprovalStatus.rejected) {
    return Column(
      children: [
        Chip(
          avatar: const Icon(Icons.close, size: 18),
          label: const Text('رد شده'),
          backgroundColor: Colors.red.shade100,
        ),
        if (document.rejectionReason != null)
          Text(document.rejectionReason!, style: TextStyle(fontSize: 12, color: Colors.red)),
      ],
    );
  } else if (!document.canConvert(currentUser)) {
    return IconButton(
      icon: const Icon(Icons.send),
      tooltip: 'درخواست تأیید',
      onPressed: () => _requestApproval(document),
    );
  }
}
```

#### 8.2 اضافه کردن منوی "کارتابل تأیید" در Drawer
**فایل**: `lib/features/dashboard/presentation/pages/dashboard_page.dart`

```dart
// در Drawer:
BlocBuilder<ApprovalBloc, ApprovalState>(
  builder: (context, state) {
    int pendingCount = 0;
    if (state is PendingApprovalsLoaded) {
      pendingCount = state.documents.length;
    }
    
    return ListTile(
      leading: Badge(
        label: Text('$pendingCount'),
        isLabelVisible: pendingCount > 0,
        child: const Icon(Icons.approval),
      ),
      title: const Text('کارتابل تأیید'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApprovalQueuePage()),
        );
      },
    );
  },
)
```

#### 8.3 راه‌اندازی Polling در main.dart
**فایل**: `lib/main.dart`

```dart
// در initState یا main:
final pollingService = sl<ApprovalPollingService>();
pollingService.start();

// در dispose:
pollingService.stop();
```

#### 8.4 به‌روزرسانی ConvertDocumentUseCase
**فایل**: `lib/features/document/domain/usecases/convert_document_usecase.dart`

```dart
// اضافه کردن چک approval قبل از تبدیل:
if (document.requiresApproval && document.approvalStatus != ApprovalStatus.approved) {
  return Left(ValidationFailure('این سند نیاز به تأیید سرپرست دارد'));
}
```

---

## 🎯 آزمایش نهایی (⏳ در انتظار)

### سناریوهای تست:

1. **ایجاد پیش‌فاکتور موقت با مبلغ بالا**
   - [ ] کاربر عادی نمی‌تواند مستقیماً تبدیل کند
   - [ ] دکمه "درخواست تأیید" نمایش داده می‌شود

2. **ارسال درخواست تأیید**
   - [ ] وضعیت به `pending` تغییر می‌کند
   - [ ] در کارتابل سرپرست نمایش داده می‌شود

3. **کارتابل سرپرست**
   - [ ] لیست پیش‌فاکتورهای منتظر نمایش داده می‌شود
   - [ ] دکمه‌های تأیید/رد کار می‌کنند

4. **تأیید سند**
   - [ ] وضعیت به `approved` تغییر می‌کند
   - [ ] کاربر می‌تواند تبدیل کند

5. **رد سند**
   - [ ] وضعیت به `rejected` تغییر می‌کند
   - [ ] دلیل رد نمایش داده می‌شود

6. **Polling**
   - [ ] هر 30 ثانیه چک می‌کند
   - [ ] Badge تعداد منتظر را نشان می‌دهد

---

## 📊 خلاصه وضعیت

| بخش | وضعیت | درصد تکمیل |
|-----|-------|------------|
| Enum ها و زیرساخت | ✅ تکمیل | 100% |
| Entity/Model ها | ✅ تکمیل | 100% |
| UseCase ها | ✅ تکمیل | 100% |
| BLoC | ✅ تکمیل | 100% |
| صفحات UI | ✅ تکمیل | 100% |
| Polling Service | ✅ تکمیل | 100% |
| Dependency Injection | ✅ تکمیل | 100% |
| تست‌ها | ✅ فیکس شده | 95% (فقط unused import) |
| ادغام با UI اصلی | ⏳ در انتظار | 0% |
| آزمایش نهایی | ⏳ در انتظار | 0% |

**کل پیشرفت: 80%** 🎉

---

## 🚀 مراحل بعدی

1. پیاده‌سازی بخش 8 (ادغام با UI اصلی)
2. اجرای تست‌های سناریویی
3. اضافه کردن notification های بصری
4. (اختیاری) اضافه کردن Firebase Cloud Messaging

---

## 🐛 مشکلات شناخته شده

1. ✅ **Logger → AppLogger**: فیکس شد
2. ✅ **تست‌ها نیاز به آپدیت داشتند**: با اسکریپت Python فیکس شد
3. ⚠️ **Unused imports در تست‌ها**: قابل نادیده گرفتن (فقط lint warning)

---

## 📝 نکات مهم برای توسعه‌دهنده بعدی

1. دیتابیس پاک شده، داده‌های قدیمی وجود ندارد
2. TypeAdapter ها با `@HiveField` جدید generate شده‌اند
3. همه UseCase ها و BLoC ها در `injection_container.dart` ثبت شده‌اند
4. Polling service هر 30 ثانیه چک می‌کند (قابل تنظیم در کد)
5. برای دیدن Badge تعداد منتظر، باید ApprovalBloc را در Drawer استفاده کنید

**موفق باشید!** 🚀
