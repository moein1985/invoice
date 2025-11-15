import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/core/widgets/loading_widget.dart';
import 'package:invoice/core/widgets/error_widget.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../../domain/entities/user_entity.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  UserEntity? _user;

  @override
  void initState() {
    super.initState();
    // بارگذاری جزئیات کاربر
    context.read<UserBloc>().add(LoadUsers());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات کاربر'),
        actions: [
          if (_user != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).pushNamed('/users/edit', arguments: _user);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _showDeleteConfirmationDialog(),
            ),
          ],
        ],
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UsersLoaded) {
            // پیدا کردن کاربر مورد نظر
            final user = state.users.firstWhere(
              (u) => u.id == widget.userId,
              orElse: () => throw Exception('User not found'),
            );
            setState(() => _user = user);
          } else if (state is UserOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
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
                context.read<UserBloc>().add(LoadUsers());
              },
            );
          } else if (_user != null) {
            return _buildUserDetails(_user!);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildUserDetails(UserEntity user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر با آواتار
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: user.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceVariant,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      color: user.isActive
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.isActive ? 'کاربر فعال' : 'کاربر غیرفعال',
                    style: TextStyle(
                      color: user.isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // اطلاعات کاربر
          Text(
            'اطلاعات کاربر',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'نام کامل',
            value: user.fullName,
            icon: Icons.person,
          ),
          _buildInfoCard(
            title: 'نام کاربری',
            value: user.username,
            icon: Icons.account_circle,
          ),
          _buildInfoCard(
            title: 'نقش',
            value: user.isAdmin ? 'مدیر سیستم' : 'کاربر عادی',
            icon: Icons.admin_panel_settings,
          ),
          _buildInfoCard(
            title: 'وضعیت',
            value: user.isActive ? 'فعال' : 'غیرفعال',
            icon: user.isActive ? Icons.check_circle : Icons.cancel,
          ),

          const SizedBox(height: 32),

          // تاریخ‌ها
          Text(
            'تاریخ‌ها',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: 'تاریخ ایجاد',
            value: _formatDate(user.createdAt),
            icon: Icons.calendar_today,
          ),
          if (user.lastLogin != null)
            _buildInfoCard(
              title: 'آخرین ورود',
              value: _formatDate(user.lastLogin!),
              icon: Icons.login,
            ),

          const SizedBox(height: 32),

          // دکمه‌ها
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to edit user page
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('ویرایش'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('حذف'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmationDialog() {
    if (_user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید حذف'),
        content: Text('آیا از حذف کاربر "${_user!.fullName}" اطمینان دارید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<UserBloc>().add(DeleteUser(_user!.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
