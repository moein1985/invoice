import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_pending_approvals_usecase.dart';
import '../../domain/usecases/approve_document_usecase.dart';
import '../../domain/usecases/reject_document_usecase.dart';
import '../../domain/usecases/request_approval_usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
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
    emit(ApprovalLoading());

    final result = await getPendingApprovals();

    result.fold(
      (failure) => emit(ApprovalError(failure.message)),
      (documents) => emit(PendingApprovalsLoaded(documents)),
    );
  }

  Future<void> _onApproveDocument(
    ApproveDocument event,
    Emitter<ApprovalState> emit,
  ) async {
    // TODO: Get current user ID from auth
    const currentUserId = 'supervisor_id'; // Placeholder

    final result = await approveDocument(
      documentId: event.documentId,
      approvedBy: currentUserId,
    );

    result.fold(
      (failure) => emit(ApprovalError(failure.message)),
      (document) {
        emit(DocumentApproved(document));
        // Reload the list
        add(LoadPendingApprovals());
      },
    );
  }

  Future<void> _onRejectDocument(
    RejectDocument event,
    Emitter<ApprovalState> emit,
  ) async {
    // TODO: Get current user ID from auth
    const currentUserId = 'supervisor_id'; // Placeholder

    final result = await rejectDocument(
      documentId: event.documentId,
      rejectedBy: currentUserId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(ApprovalError(failure.message)),
      (document) {
        emit(DocumentRejected(document));
        // Reload the list
        add(LoadPendingApprovals());
      },
    );
  }

  Future<void> _onRequestApproval(
    RequestApproval event,
    Emitter<ApprovalState> emit,
  ) async {
    final result = await requestApproval(documentId: event.documentId);

    result.fold(
      (failure) => emit(ApprovalError(failure.message)),
      (document) => emit(ApprovalSuccess('درخواست تأیید ارسال شد')),
    );
  }
}