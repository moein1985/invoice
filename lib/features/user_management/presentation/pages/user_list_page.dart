import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/core/widgets/loading_widget.dart';
import 'package:invoice/core/widgets/error_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../widgets/user_list_item.dart';
import '../widgets/user_search_bar.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // بررسی دسترسی
    _checkAccess();
    // بارگذاری لیست کاربران
    context.read<UserBloc>().add(const LoadUsers());
  }

  void _checkAccess() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated || authState.user.role.name != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فقط ادمین به این بخش دسترسی دارد'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<UserBloc>().add(const LoadUsers());
    } else {
      context.read<UserBloc>().add(SearchUsers(query));
    }
  }

  void _onRefresh() {
    _searchController.clear();
    context.read<UserBloc>().add(const LoadUsers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت کاربران'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushNamed('/users/create');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // نوار جستجو
          UserSearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
          ),

          // لیست کاربران
          Expanded(
            child: BlocConsumer<UserBloc, UserState>(
              listener: (context, state) {
                if (state is UserOperationSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // بروزرسانی لیست پس از عملیات موفق
                  context.read<UserBloc>().add(const LoadUsers());
                } else if (state is UserError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is UserInitial || state is UserLoading) {
                  return const LoadingWidget();
                } else if (state is UserError) {
                  return ErrorDisplayWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<UserBloc>().add(const LoadUsers());
                    },
                  );
                } else if (state is UsersLoaded) {
                  if (state.users.isEmpty) {
                    return const Center(
                      child: Text('هیچ کاربری یافت نشد'),
                    );
                  }

                  return ListView.builder(
                    itemCount: state.users.length,
                    itemBuilder: (context, index) {
                      final user = state.users[index];
                      return UserListItem(
                        user: user,
                        onEdit: () {
                          Navigator.of(context).pushNamed('/users/edit', arguments: user);
                        },
                        onDelete: () {
                          _showDeleteConfirmationDialog(user);
                        },
                        onToggleStatus: () {
                          context.read<UserBloc>().add(ToggleUserStatus(user.id));
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(dynamic user) {
    final userBloc = context.read<UserBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text('آیا از حذف کاربر "${user.fullName}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              userBloc.add(DeleteUser(user.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
