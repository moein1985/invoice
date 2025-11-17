import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/approval_bloc.dart';
import '../bloc/approval_event.dart';
import '../bloc/approval_state.dart';
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