import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/core/widgets/custom_button.dart';
import 'package:invoice/core/widgets/custom_text_field.dart';
import 'package:invoice/core/widgets/loading_widget.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_event.dart';
import '../bloc/user_state.dart';
import '../../domain/entities/user_entity.dart';

class UserFormPage extends StatefulWidget {
  final UserEntity? user; // null برای ایجاد کاربر جدید

  const UserFormPage({super.key, this.user});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  String _selectedRole = 'employee';
  bool _isActive = true;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _usernameController.text = widget.user!.username;
      _fullNameController.text = widget.user!.fullName;
      _selectedRole = widget.user!.role.name;
      _isActive = widget.user!.isActive;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      context.read<UserBloc>().add(UpdateUser(
        id: widget.user!.id,
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        role: _selectedRole,
        isActive: _isActive,
      ));
    } else {
      context.read<UserBloc>().add(CreateUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        role: _selectedRole,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش کاربر' : 'کاربر جدید'),
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserOperationSuccess) {
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
          if (state is UserLoading) {
            return const LoadingWidget(message: 'در حال ذخیره...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // نام کامل
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'نام کامل',
                    hint: 'نام و نام خانوادگی',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'نام کامل را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // نام کاربری
                  CustomTextField(
                    controller: _usernameController,
                    label: 'نام کاربری',
                    hint: 'نام کاربری منحصر به فرد',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'نام کاربری را وارد کنید';
                      }
                      if (value.trim().length < 3) {
                        return 'نام کاربری باید حداقل ۳ کاراکتر باشد';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // رمز عبور (فقط برای کاربر جدید)
                  if (!_isEditing) ...[
                    CustomTextField(
                      controller: _passwordController,
                      label: 'رمز عبور',
                      hint: 'رمز عبور',
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'رمز عبور را وارد کنید';
                        }
                        if (value.length < 6) {
                          return 'رمز عبور باید حداقل ۶ کاراکتر باشد';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // نقش کاربر
                  DropdownButtonFormField<String>(
                    key: ValueKey('role_$_selectedRole'),
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'نقش',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'employee',
                        child: Text('کارمند'),
                      ),
                      DropdownMenuItem(
                        value: 'supervisor',
                        child: Text('سرپرست'),
                      ),
                      DropdownMenuItem(
                        value: 'manager',
                        child: Text('مدیر'),
                      ),
                      DropdownMenuItem(
                        value: 'admin',
                        child: Text('ادمین'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // وضعیت فعال بودن
                  SwitchListTile(
                    title: const Text('کاربر فعال'),
                    subtitle: const Text('اگر غیرفعال باشد، نمی‌تواند وارد سیستم شود'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                  ),
                  const SizedBox(height: 32),

                  // دکمه ذخیره
                  CustomButton(
                    text: _isEditing ? 'بروزرسانی' : 'ایجاد کاربر',
                    onPressed: _submitForm,
                    isLoading: state is UserLoading,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}