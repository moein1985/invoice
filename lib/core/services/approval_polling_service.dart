import 'dart:async';
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
    AppLogger.info('[PollingService] Starting approval polling');
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkPendingApprovals();
    });
    
    // اولین چک فوری
    _checkPendingApprovals();
  }

  void stop() {
    AppLogger.info('[PollingService] Stopping approval polling');
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
        AppLogger.error('[PollingService] Failed to check: ${failure.toString()}');
      },
      (documents) {
        final count = documents.length;
        
        // اگر تعداد تغییر کرد، notification نشان بده
        if (count != _previousCount && count > 0) {
          AppLogger.info('[PollingService] Pending count changed: $_previousCount → $count');
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
    AppLogger.info('[PollingService] Showing notification for $count pending documents');
  }

  void dispose() {
    stop();
    _pendingCountController.close();
  }
}
