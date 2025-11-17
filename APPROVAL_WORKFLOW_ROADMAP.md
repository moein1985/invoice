# 📋 نقشه راه پیاده‌سازی سیستم تأیید پیش‌فاکتور

## 🎯 هدف کلی
پیاده‌سازی سیستم Approval Workflow که سرپرست بتواند پیش‌فاکتورهای موقت را روی موبایل تأیید کند.

---

## 📦 فاز 1: زیرساخت و مدل‌های پایه (روز 1)

### 1.1 ایجاد Enum برای وضعیت تأیید
**مسیر**: `lib/core/enums/approval_status.dart`

```dart
enum ApprovalStatus {
  notRequired,  // نیاز به تأیید ندارد
  pending,      // منتظر تأیید
  approved,     // تأیید شده
  rejected;     // رد شده

  String get persianName {
    switch (this) {
      case ApprovalStatus.notRequired:
        return 'نیاز به تأیید ندارد';
      case ApprovalStatus.pending:
        return 'منتظر تأیید';
      case ApprovalStatus.approved:
        return 'تأیید شده';
      case ApprovalStatus.rejected:
        return 'رد شده';
    }
  }

  String get icon {
    switch (this) {
      case ApprovalStatus.notRequired:
        return '✓';
      case ApprovalStatus.pending:
        return '⏳';
      case ApprovalStatus.approved:
        return '✅';
      case ApprovalStatus.rejected:
        return '❌';
    }
  }
}
```

### 1.2 ایجاد Enum برای نقش کاربر
**مسیر**: `lib/core/enums/user_role.dart`

```dart
enum UserRole {
  employee,     // کارمند عادی
  supervisor,   // سرپرست
  manager,      // مدیر
  admin;        // ادمین

  String get persianName {
    switch (this) {
      case UserRole.employee:
        return 'کارمند';
      case UserRole.supervisor:
        return 'سرپرست';
      case UserRole.manager:
        return 'مدیر';
      case UserRole.admin:
        return 'ادمین';
    }
  }

  // حداکثر مبلغی که می‌تواند بدون تأیید تبدیل کند
  double get maxApprovalAmount {
    switch (this) {
      case UserRole.employee:
        return 10000000; // 10 میلیون
      case UserRole.supervisor:
        return 100000000; // 100 میلیون
      case UserRole.manager:
        return 500000000; // 500 میلیون
      case UserRole.admin:
        return double.infinity; // نامحدود
    }
  }

  bool canApprove(double amount) {
    return amount <= maxApprovalAmount;
  }
}
```

### 1.3 اضافه کردن فیلدهای جدید به UserEntity
**مسیر**: `lib/features/user_management/domain/entities/user_entity.dart`

```dart
// اضافه کردن به constructor:
final UserRole role;

// اضافه کردن به props:
@override
List<Object?> get props => [id, username, fullName, role, createdAt];

// اضافه کردن به copyWith:
UserEntity copyWith({
  String? id,
  String? username,
  String? fullName,
  UserRole? role,
  DateTime? createdAt,
}) {
  return UserEntity(
    id: id ?? this.id,
    username: username ?? this.username,
    fullName: fullName ?? this.fullName,
    role: role ?? this.role,
    createdAt: createdAt ?? this.createdAt,
  );
}

// اضافه کردن به toJson:
Map<String, dynamic> toJson() {
  return {
    'id': id,
    'username': username,
    'fullName': fullName,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
  };
}

// اضافه کردن به fromJson:
factory UserEntity.fromJson(Map<String, dynamic> json) {
  return UserEntity(
    id: json['id'] as String,
    username: json['username'] as String,
    fullName: json['fullName'] as String,
    role: UserRole.values.byName(json['role'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
```

### 1.4 به‌روزرسانی UserModel برای TypeAdapter
**مسیر**: `lib/features/user_management/data/models/user_model.dart`

```dart
// اضافه کردن HiveField جدید:
@HiveField(4)
final String role; // ذخیره به صورت String

// تبدیل در fromEntity:
static UserModel fromEntity(UserEntity entity) {
  return UserModel(
    id: entity.id,
    username: entity.username,
    fullName: entity.fullName,
    role: entity.role.name, // تبدیل enum به string
    createdAt: entity.createdAt,
  );
}

// تبدیل در toEntity:
UserEntity toEntity() {
  return UserEntity(
    id: id,
    username: username,
    fullName: fullName,
    role: UserRole.values.byName(role), // تبدیل string به enum
    createdAt: createdAt,
  );
}
```

**⚠️ بعد از این تغییر حتماً اجرا کنید:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

### 1.5 اضافه کردن فیلدهای Approval به DocumentEntity
**مسیر**: `lib/features/document/domain/entities/document_entity.dart`

```dart
// اضافه کردن به constructor:
final ApprovalStatus approvalStatus;
final String? approvedBy;           // ID کاربری که تأیید کرده
final DateTime? approvedAt;
final String? rejectionReason;
final bool requiresApproval;        // آیا نیاز به تأیید دارد؟

// اضافه کردن به props:
@override
List<Object?> get props => [
  id,
  userId,
  documentNumber,
  documentType,
  customerId,
  items,
  notes,
  discount,
  totalAmount,
  createdAt,
  updatedAt,
  convertedFromId,
  approvalStatus,
  approvedBy,
  approvedAt,
  rejectionReason,
  requiresApproval,
];

// اضافه کردن به copyWith:
DocumentEntity copyWith({
  // ... فیلدهای موجود
  ApprovalStatus? approvalStatus,
  String? approvedBy,
  DateTime? approvedAt,
  String? rejectionReason,
  bool? requiresApproval,
}) {
  return DocumentEntity(
    // ... فیلدهای موجود
    approvalStatus: approvalStatus ?? this.approvalStatus,
    approvedBy: approvedBy ?? this.approvedBy,
    approvedAt: approvedAt ?? this.approvedAt,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    requiresApproval: requiresApproval ?? this.requiresApproval,
  );
}

// اضافه کردن به toJson:
Map<String, dynamic> toJson() {
  return {
    // ... فیلدهای موجود
    'approvalStatus': approvalStatus.name,
    'approvedBy': approvedBy,
    'approvedAt': approvedAt?.toIso8601String(),
    'rejectionReason': rejectionReason,
    'requiresApproval': requiresApproval,
  };
}

// اضافه کردن به fromJson:
factory DocumentEntity.fromJson(Map<String, dynamic> json) {
  return DocumentEntity(
    // ... فیلدهای موجود
    approvalStatus: ApprovalStatus.values.byName(
      json['approvalStatus'] as String? ?? 'notRequired'
    ),
    approvedBy: json['approvedBy'] as String?,
    approvedAt: json['approvedAt'] != null 
      ? DateTime.parse(json['approvedAt'] as String) 
      : null,
    rejectionReason: json['rejectionReason'] as String?,
    requiresApproval: json['requiresApproval'] as bool? ?? false,
  );
}

// متد کمکی برای چک کردن قابلیت تبدیل:
bool canConvert(UserEntity user) {
  if (!requiresApproval) return true;
  if (approvalStatus == ApprovalStatus.approved) return true;
  
  // اگر کاربر سطح دسترسی بالایی دارد، نیاز به تأیید ندارد
  if (user.role.canApprove(totalAmount)) return true;
  
  return false;
}
```

### 1.6 به‌روزرسانی DocumentModel
**مسیر**: `lib/features/document/data/models/document_model.dart`

```dart
// اضافه کردن HiveField های جدید:
@HiveField(17)
final String approvalStatus;

@HiveField(18)
final String? approvedBy;

@HiveField(19)
final DateTime? approvedAt;

@HiveField(20)
final String? rejectionReason;

@HiveField(21)
final bool requiresApproval;

// به‌روزرسانی fromEntity:
static DocumentModel fromEntity(DocumentEntity entity) {
  return DocumentModel(
    // ... فیلدهای موجود
    approvalStatus: entity.approvalStatus.name,
    approvedBy: entity.approvedBy,
    approvedAt: entity.approvedAt,
    rejectionReason: entity.rejectionReason,
    requiresApproval: entity.requiresApproval,
  );
}

// به‌روزرسانی toEntity:
DocumentEntity toEntity() {
  return DocumentEntity(
    // ... فیلدهای موجود
    approvalStatus: ApprovalStatus.values.byName(approvalStatus),
    approvedBy: approvedBy,
    approvedAt: approvedAt,
    rejectionReason: rejectionReason,
    requiresApproval: requiresApproval,
  );
}
```

**⚠️ بعد از این تغییر حتماً اجرا کنید:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**⚠️ دیتابیس را پاک کنید:**
```powershell
Remove-Item -Path "C:\Users\Moein\Documents\*.hive" -Force
Remove-Item -Path "C:\Users\Moein\Documents\*.lock" -Force
```

---

## 📝 فاز 2: UseCase های جدید (روز 2)

### 2.1 UseCase برای درخواست تأیید
**مسیر**: `lib/features/document/domain/usecases/request_approval_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/approval_status.dart';

class RequestApprovalUseCase {
  final DocumentRepository repository;

  RequestApprovalUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call({
    required String documentId,
  }) async {
    try {
      // بارگذاری سند
      final documentResult = await repository.getDocumentById(documentId);
      
      return documentResult.fold(
        (failure) => Left(failure),
        (document) async {
          // تغییر وضعیت به pending
          final updatedDocument = document.copyWith(
            approvalStatus: ApprovalStatus.pending,
            requiresApproval: true,
          );
          
          // ذخیره
          return await repository.updateDocument(updatedDocument);
        },
      );
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
```

### 2.2 UseCase برای تأیید سند
**مسیر**: `lib/features/document/domain/usecases/approve_document_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/approval_status.dart';

class ApproveDocumentUseCase {
  final DocumentRepository repository;

  ApproveDocumentUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call({
    required String documentId,
    required String approvedBy, // ID سرپرست
  }) async {
    try {
      final documentResult = await repository.getDocumentById(documentId);
      
      return documentResult.fold(
        (failure) => Left(failure),
        (document) async {
          // تأیید سند
          final updatedDocument = document.copyWith(
            approvalStatus: ApprovalStatus.approved,
            approvedBy: approvedBy,
            approvedAt: DateTime.now(),
            rejectionReason: null,
          );
          
          return await repository.updateDocument(updatedDocument);
        },
      );
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
```

### 2.3 UseCase برای رد سند
**مسیر**: `lib/features/document/domain/usecases/reject_document_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/approval_status.dart';

class RejectDocumentUseCase {
  final DocumentRepository repository;

  RejectDocumentUseCase(this.repository);

  Future<Either<Failure, DocumentEntity>> call({
    required String documentId,
    required String rejectedBy,
    required String reason,
  }) async {
    try {
      final documentResult = await repository.getDocumentById(documentId);
      
      return documentResult.fold(
        (failure) => Left(failure),
        (document) async {
          // رد سند
          final updatedDocument = document.copyWith(
            approvalStatus: ApprovalStatus.rejected,
            approvedBy: rejectedBy,
            approvedAt: DateTime.now(),
            rejectionReason: reason,
          );
          
          return await repository.updateDocument(updatedDocument);
        },
      );
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
```

### 2.4 UseCase برای دریافت اسناد منتظر تأیید
**مسیر**: `lib/features/document/domain/usecases/get_pending_approvals_usecase.dart`

```dart
import 'package:dartz/dartz.dart';
import '../entities/document_entity.dart';
import '../repositories/document_repository.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/enums/approval_status.dart';
import '../../../../core/enums/document_type.dart';

class GetPendingApprovalsUseCase {
  final DocumentRepository repository;

  GetPendingApprovalsUseCase(this.repository);

  Future<Either<Failure, List<DocumentEntity>>> call() async {
    try {
      final allDocsResult = await repository.getAllDocuments();
      
      return allDocsResult.fold(
        (failure) => Left(failure),
        (documents) {
          // فیلتر اسناد منتظر تأیید
          final pendingDocs = documents.where((doc) {
            return doc.documentType == DocumentType.tempProforma &&
                   doc.approvalStatus == ApprovalStatus.pending;
          }).toList();
          
          // مرتب‌سازی بر اساس تاریخ (جدیدترین اول)
          pendingDocs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return Right(pendingDocs);
        },
      );
    } catch (e) {
      return Left(CacheFailure());
    }
  }
}
```

---

## 🎨 فاز 3: رابط کاربری - صفحه کارتابل (روز 3)

### 3.1 صفحه کارتابل سرپرست
**مسیر**: `lib/features/document/presentation/pages/approval_queue_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/approval_bloc.dart';
import '../widgets/approval_card.dart';
import '../../../../injection_container.dart';

class ApprovalQueuePage extends StatelessWidget {
  const ApprovalQueuePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ApprovalBloc>()..add(LoadPendingApprovals()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('کارتابل تأیید'),
          centerTitle: true,
        ),
        body: BlocBuilder<ApprovalBloc, ApprovalState>(
          builder: (context, state) {
            if (state is ApprovalLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (state is ApprovalError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            
            if (state is PendingApprovalsLoaded) {
              if (state.documents.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('همه اسناد تأیید شده‌اند'),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<ApprovalBloc>().add(LoadPendingApprovals());
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.documents.length,
                  itemBuilder: (context, index) {
                    return ApprovalCard(
                      document: state.documents[index],
                      onApprove: () {
                        _showApproveDialog(
                          context,
                          state.documents[index].id,
                        );
                      },
                      onReject: () {
                        _showRejectDialog(
                          context,
                          state.documents[index].id,
                        );
                      },
                    );
                  },
                ),
              );
            }
            
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأیید پیش‌فاکتور'),
        content: const Text('آیا از تأیید این پیش‌فاکتور اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ApprovalBloc>().add(
                ApproveDocument(documentId: documentId),
              );
              Navigator.pop(dialogContext);
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String documentId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('رد پیش‌فاکتور'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'دلیل رد',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لطفاً دلیل رد را وارد کنید')),
                );
                return;
              }
              
              context.read<ApprovalBloc>().add(
                RejectDocument(
                  documentId: documentId,
                  reason: reasonController.text.trim(),
                ),
              );
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('رد'),
          ),
        ],
      ),
    );
  }
}
```

### 3.2 کارت نمایش سند در کارتابل
**مسیر**: `lib/features/document/presentation/widgets/approval_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/document_entity.dart';
import '../../../../core/utils/formatters.dart';

class ApprovalCard extends StatelessWidget {
  final DocumentEntity document;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const ApprovalCard({
    Key? key,
    required this.document,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // هدر
            Row(
              children: [
                Expanded(
                  child: Text(
                    document.documentNumber,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⏳ منتظر تأیید',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // مبلغ
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('مبلغ کل:'),
                  Text(
                    Formatters.formatCurrency(document.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // اطلاعات اقلام
            Text(
              '📦 ${document.items.length} قلم کالا',
              style: theme.textTheme.bodyMedium,
            ),
            
            const SizedBox(height: 8),
            
            // زمان ایجاد
            Text(
              '🕐 ${_formatDateTime(document.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // دکمه‌های تأیید/رد
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('تأیید'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('رد'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'هم‌اکنون';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} دقیقه پیش';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ساعت پیش';
    } else {
      final formatter = DateFormat('yyyy/MM/dd HH:mm');
      return formatter.format(dateTime);
    }
  }
}
```

---

## 🧩 فاز 4: BLoC برای مدیریت Approval (روز 4)

### 4.1 Event ها
**مسیر**: `lib/features/document/presentation/bloc/approval_event.dart`

```dart
import 'package:equatable/equatable.dart';

abstract class ApprovalEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPendingApprovals extends ApprovalEvent {}

class ApproveDocument extends ApprovalEvent {
  final String documentId;

  ApproveDocument({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}

class RejectDocument extends ApprovalEvent {
  final String documentId;
  final String reason;

  RejectDocument({
    required this.documentId,
    required this.reason,
  });

  @override
  List<Object?> get props => [documentId, reason];
}

class RequestApproval extends ApprovalEvent {
  final String documentId;

  RequestApproval({required this.documentId});

  @override
  List<Object?> get props => [documentId];
}
```

### 4.2 State ها
**مسیر**: `lib/features/document/presentation/bloc/approval_state.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/document_entity.dart';

abstract class ApprovalState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ApprovalInitial extends ApprovalState {}

class ApprovalLoading extends ApprovalState {}

class PendingApprovalsLoaded extends ApprovalState {
  final List<DocumentEntity> documents;

  PendingApprovalsLoaded(this.documents);

  @override
  List<Object?> get props => [documents];
}

class ApprovalSuccess extends ApprovalState {
  final String message;

  ApprovalSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ApprovalError extends ApprovalState {
  final String message;

  ApprovalError(this.message);

  @override
  List<Object?> get props => [message];
}
```

### 4.3 BLoC
**مسیر**: `lib/features/document/presentation/bloc/approval_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_pending_approvals_usecase.dart';
import '../../domain/usecases/approve_document_usecase.dart';
import '../../domain/usecases/reject_document_usecase.dart';
import '../../domain/usecases/request_approval_usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../../core/utils/logger.dart';
import 'approval_event.dart';
import 'approval_state.dart';

class ApprovalBloc extends Bloc<ApprovalEvent, ApprovalState> {
  final GetPendingApprovalsUseCase getPendingApprovals;
  final ApproveDocumentUseCase approveDocument;
  final RejectDocumentUseCase rejectDocument;
  final RequestApprovalUseCase requestApproval;
  final AuthRepository authRepository;

  ApprovalBloc({
    required this.getPendingApprovals,
    required this.approveDocument,
    required this.rejectDocument,
    required this.requestApproval,
    required this.authRepository,
  }) : super(ApprovalInitial()) {
    on<LoadPendingApprovals>(_onLoadPendingApprovals);
    on<ApproveDocument>(_onApproveDocument);
    on<RejectDocument>(_onRejectDocument);
    on<RequestApproval>(_onRequestApproval);
  }

  Future<void> _onLoadPendingApprovals(
    LoadPendingApprovals event,
    Emitter<ApprovalState> emit,
  ) async {
    Logger.info('[ApprovalBloc] Loading pending approvals');
    emit(ApprovalLoading());

    final result = await getPendingApprovals();

    result.fold(
      (failure) {
        Logger.error('[ApprovalBloc] Failed to load: ${failure.toString()}');
        emit(ApprovalError('خطا در بارگذاری اسناد منتظر تأیید'));
      },
      (documents) {
        Logger.info('[ApprovalBloc] Loaded ${documents.length} pending documents');
        emit(PendingApprovalsLoaded(documents));
      },
    );
  }

  Future<void> _onApproveDocument(
    ApproveDocument event,
    Emitter<ApprovalState> emit,
  ) async {
    Logger.info('[ApprovalBloc] Approving document ${event.documentId}');
    emit(ApprovalLoading());

    // دریافت کاربر جاری
    final userResult = await authRepository.getCurrentUser();
    final currentUser = userResult.fold(
      (failure) => null,
      (user) => user,
    );

    if (currentUser == null) {
      emit(ApprovalError('خطا در شناسایی کاربر'));
      return;
    }

    final result = await approveDocument(
      documentId: event.documentId,
      approvedBy: currentUser.id,
    );

    result.fold(
      (failure) {
        Logger.error('[ApprovalBloc] Approve failed: ${failure.toString()}');
        emit(ApprovalError('خطا در تأیید سند'));
      },
      (document) {
        Logger.info('[ApprovalBloc] Document ${document.documentNumber} approved');
        emit(ApprovalSuccess('سند با موفقیت تأیید شد'));
        
        // بارگذاری مجدد لیست
        add(LoadPendingApprovals());
      },
    );
  }

  Future<void> _onRejectDocument(
    RejectDocument event,
    Emitter<ApprovalState> emit,
  ) async {
    Logger.info('[ApprovalBloc] Rejecting document ${event.documentId}');
    emit(ApprovalLoading());

    final userResult = await authRepository.getCurrentUser();
    final currentUser = userResult.fold(
      (failure) => null,
      (user) => user,
    );

    if (currentUser == null) {
      emit(ApprovalError('خطا در شناسایی کاربر'));
      return;
    }

    final result = await rejectDocument(
      documentId: event.documentId,
      rejectedBy: currentUser.id,
      reason: event.reason,
    );

    result.fold(
      (failure) {
        Logger.error('[ApprovalBloc] Reject failed: ${failure.toString()}');
        emit(ApprovalError('خطا در رد سند'));
      },
      (document) {
        Logger.info('[ApprovalBloc] Document ${document.documentNumber} rejected');
        emit(ApprovalSuccess('سند رد شد'));
        
        // بارگذاری مجدد لیست
        add(LoadPendingApprovals());
      },
    );
  }

  Future<void> _onRequestApproval(
    RequestApproval event,
    Emitter<ApprovalState> emit,
  ) async {
    Logger.info('[ApprovalBloc] Requesting approval for ${event.documentId}');

    final result = await requestApproval(documentId: event.documentId);

    result.fold(
      (failure) {
        Logger.error('[ApprovalBloc] Request failed: ${failure.toString()}');
        emit(ApprovalError('خطا در ارسال درخواست تأیید'));
      },
      (document) {
        Logger.info('[ApprovalBloc] Approval requested for ${document.documentNumber}');
        emit(ApprovalSuccess('درخواست تأیید ارسال شد'));
      },
    );
  }
}
```

---

## 🔧 فاز 5: تغییرات در صفحه لیست اسناد (روز 5)

### 5.1 اضافه کردن دکمه درخواست تأیید
**مسیر**: تغییر در `lib/features/document/presentation/pages/document_list_page.dart`

در متد `_buildActionButtons` که دکمه‌های عملیات را می‌سازد:

```dart
// اضافه کردن این کد قبل از دکمه تبدیل:
if (document.documentType == DocumentType.tempProforma) {
  if (document.approvalStatus == ApprovalStatus.pending) {
    // نمایش وضعیت منتظر
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Chip(
        avatar: const Icon(Icons.schedule, size: 18),
        label: const Text('منتظر تأیید'),
        backgroundColor: Colors.orange.shade100,
      ),
    );
  } else if (document.approvalStatus == ApprovalStatus.rejected) {
    // نمایش وضعیت رد شده
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Chip(
            avatar: const Icon(Icons.close, size: 18),
            label: const Text('رد شده'),
            backgroundColor: Colors.red.shade100,
          ),
          if (document.rejectionReason != null)
            Text(
              document.rejectionReason!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
        ],
      ),
    );
  } else if (!document.canConvert(currentUser)) {
    // نیاز به درخواست تأیید
    return IconButton(
      icon: const Icon(Icons.send),
      tooltip: 'درخواست تأیید',
      onPressed: () => _requestApproval(document),
    );
  }
}
```

افزودن متد `_requestApproval`:

```dart
void _requestApproval(DocumentEntity document) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('درخواست تأیید'),
      content: Text(
        'آیا می‌خواهید این سند را برای تأیید سرپرست ارسال کنید؟\n\n'
        'شماره سند: ${document.documentNumber}\n'
        'مبلغ: ${Formatters.formatCurrency(document.totalAmount)}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('انصراف'),
        ),
        ElevatedButton(
          onPressed: () {
            context.read<ApprovalBloc>().add(
              RequestApproval(documentId: document.id),
            );
            Navigator.pop(ctx);
          },
          child: const Text('ارسال درخواست'),
        ),
      ],
    ),
  );
}
```

### 5.2 اضافه کردن Badge به منوی کارتابل

در `Drawer` یا منوی اصلی:

```dart
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
          MaterialPageRoute(
            builder: (_) => const ApprovalQueuePage(),
          ),
        );
      },
    );
  },
)
```

---

## 🔄 فاز 6: Polling برای به‌روزرسانی خودکار (روز 6)

### 6.1 سرویس Polling
**مسیر**: `lib/core/services/approval_polling_service.dart`

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/document/domain/usecases/get_pending_approvals_usecase.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../enums/user_role.dart';
import '../utils/logger.dart';

class ApprovalPollingService {
  final GetPendingApprovalsUseCase getPendingApprovals;
  final AuthRepository authRepository;
  
  Timer? _timer;
  int _previousCount = 0;
  final _pendingCountController = StreamController<int>.broadcast();

  Stream<int> get pendingCountStream => _pendingCountController.stream;

  ApprovalPollingService({
    required this.getPendingApprovals,
    required this.authRepository,
  });

  void start() {
    Logger.info('[PollingService] Starting approval polling');
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkPendingApprovals();
    });
    
    // اولین چک فوری
    _checkPendingApprovals();
  }

  void stop() {
    Logger.info('[PollingService] Stopping approval polling');
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkPendingApprovals() async {
    // فقط برای سرپرست و بالاتر
    final userResult = await authRepository.getCurrentUser();
    final user = userResult.fold((_) => null, (u) => u);
    
    if (user == null || user.role == UserRole.employee) {
      return;
    }

    final result = await getPendingApprovals();
    
    result.fold(
      (failure) {
        Logger.error('[PollingService] Failed to check: ${failure.toString()}');
      },
      (documents) {
        final count = documents.length;
        
        // اگر تعداد تغییر کرد، notification نشان بده
        if (count != _previousCount && count > 0) {
          Logger.info('[PollingService] Pending count changed: $_previousCount → $count');
          _showNotification(count);
        }
        
        _previousCount = count;
        _pendingCountController.add(count);
      },
    );
  }

  void _showNotification(int count) {
    // TODO: نمایش notification داخل اپ
    // می‌توان از package flutter_local_notifications استفاده کرد
    Logger.info('[PollingService] Showing notification for $count pending documents');
  }

  void dispose() {
    stop();
    _pendingCountController.close();
  }
}
```

### 6.2 راه‌اندازی در main.dart

```dart
// در تابع main یا initState:
final pollingService = sl<ApprovalPollingService>();

// شروع polling
pollingService.start();

// گوش دادن به تغییرات
pollingService.pendingCountStream.listen((count) {
  Logger.info('Pending approvals: $count');
  // می‌توان Badge ها را به‌روز کرد
});

// در dispose:
pollingService.stop();
```

---

## 🎁 فاز 7: Dependency Injection (روز 7)

### 7.1 ثبت در injection_container.dart

```dart
// UseCase ها
sl.registerLazySingleton(() => RequestApprovalUseCase(sl()));
sl.registerLazySingleton(() => ApproveDocumentUseCase(sl()));
sl.registerLazySingleton(() => RejectDocumentUseCase(sl()));
sl.registerLazySingleton(() => GetPendingApprovalsUseCase(sl()));

// BLoC
sl.registerFactory(
  () => ApprovalBloc(
    getPendingApprovals: sl(),
    approveDocument: sl(),
    rejectDocument: sl(),
    requestApproval: sl(),
    authRepository: sl(),
  ),
);

// Service
sl.registerLazySingleton(
  () => ApprovalPollingService(
    getPendingApprovals: sl(),
    authRepository: sl(),
  ),
);
```

---

## ✅ چک‌لیست نهایی

### روز 1: زیرساخت
- [ ] ایجاد `ApprovalStatus` enum
- [ ] ایجاد `UserRole` enum  
- [ ] افزودن فیلد `role` به `UserEntity`
- [ ] افزودن فیلدهای approval به `DocumentEntity`
- [ ] به‌روزرسانی `UserModel` + TypeAdapter
- [ ] به‌روزرسانی `DocumentModel` + TypeAdapter
- [ ] اجرای `build_runner`
- [ ] پاک کردن دیتابیس Hive

### روز 2: UseCase ها
- [ ] `RequestApprovalUseCase`
- [ ] `ApproveDocumentUseCase`
- [ ] `RejectDocumentUseCase`
- [ ] `GetPendingApprovalsUseCase`

### روز 3: UI
- [ ] صفحه `ApprovalQueuePage`
- [ ] ویجت `ApprovalCard`

### روز 4: BLoC
- [ ] `ApprovalEvent`
- [ ] `ApprovalState`
- [ ] `ApprovalBloc`

### روز 5: ادغام
- [ ] دکمه درخواست تأیید در لیست
- [ ] Badge در منو
- [ ] تست جریان کامل

### روز 6: Polling
- [ ] `ApprovalPollingService`
- [ ] راه‌اندازی در `main.dart`

### روز 7: تست و Debug
- [ ] تست با کاربر عادی
- [ ] تست با سرپرست
- [ ] تست Polling
- [ ] بهینه‌سازی UI/UX

---

## 🚀 دستورات اجرا

```bash
# 1. Generate TypeAdapters
dart run build_runner build --delete-conflicting-outputs

# 2. پاک کردن دیتابیس
Remove-Item -Path "C:\Users\Moein\Documents\*.hive" -Force
Remove-Item -Path "C:\Users\Moein\Documents\*.lock" -Force

# 3. اجرای برنامه
flutter run -d windows
```

---

## 📝 نکات مهم

1. **همیشه قبل از تست، دیتابیس را پاک کنید** (به خاطر تغییرات schema)
2. **Polling هر 30 ثانیه** فعال است (قابل تنظیم)
3. **Role-based access** در `UserRole.maxApprovalAmount`
4. **لاگ‌ها کامل** برای debug
5. **Badge قرمز** برای نمایش تعداد منتظر

---

## 🎯 نتیجه نهایی

بعد از پیاده‌سازی این نقشه:

✅ کاربر عادی سند با مبلغ بالا می‌سازد → درخواست تأیید می‌فرستد  
✅ سرپرست در کارتابل می‌بیند → تأیید یا رد می‌کند  
✅ Polling هر 30 ثانیه چک می‌کند  
✅ Badge تعداد منتظر را نشان می‌دهد  
✅ کاربر notification دریافت می‌کند  

**زمان کل: 7 روز** 🚀
