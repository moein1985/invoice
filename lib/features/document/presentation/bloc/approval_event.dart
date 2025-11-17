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