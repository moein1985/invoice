import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginRequested(
              username: _usernameController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is Authenticated) {
            // اینجا بعداً به صفحه اصلی هدایت می‌شویم
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ورود موفقیت‌آمیز بود'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // لوگو یا عنوان
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'مدیریت فاکتور',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 48),

                    // فیلد نام کاربری
                    CustomTextField(
                      controller: _usernameController,
                      label: 'نام کاربری',
                      prefixIcon: const Icon(Icons.person),
                      validator: Validators.required,
                      readOnly: isLoading,
                    ),
                    const SizedBox(height: 16),

                    // فیلد رمز عبور
                    CustomTextField(
                      controller: _passwordController,
                      label: 'رمز عبور',
                      prefixIcon: const Icon(Icons.lock),
                      obscureText: _obscurePassword,
                      validator: Validators.required,
                      readOnly: isLoading,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleLogin(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // دکمه ورود
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'ورود',
                        onPressed: _handleLogin,
                        isLoading: isLoading,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // راهنما
                    Text(
                      'نام کاربری و رمز پیش‌فرض: admin / admin123',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
