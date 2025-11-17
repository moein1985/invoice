import 'package:equatable/equatable.dart';
import '../../domain/entities/document_entity.dart';

abstract class ApprovalState extends Equatable {
  const ApprovalState();

  @override
  List<Object?> get props => [];
}

class ApprovalInitial extends ApprovalState {}

class ApprovalLoading extends ApprovalState {}

class PendingApprovalsLoaded extends ApprovalState {
  final List<DocumentEntity> documents;

  const PendingApprovalsLoaded(this.documents);

  @override
  List<Object?> get props => [documents];
}

class ApprovalSuccess extends ApprovalState {
  final String message;

  const ApprovalSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ApprovalError extends ApprovalState {
  final String message;

  const ApprovalError(this.message);

  @override
  List<Object?> get props => [message];
}

class DocumentApproved extends ApprovalState {
  final DocumentEntity document;

  const DocumentApproved(this.document);

  @override
  List<Object?> get props => [document];
}

class DocumentRejected extends ApprovalState {
  final DocumentEntity document;

  const DocumentRejected(this.document);

  @override
  List<Object?> get props => [document];
}