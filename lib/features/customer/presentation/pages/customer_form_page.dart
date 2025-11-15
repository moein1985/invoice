import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice/core/widgets/custom_button.dart';
import 'package:invoice/core/widgets/custom_text_field.dart';
import 'package:invoice/core/widgets/loading_widget.dart';
import 'package:invoice/core/utils/validators.dart';
import '../bloc/customer_bloc.dart';
import '../../domain/entities/customer_entity.dart';

class CustomerFormPage extends StatefulWidget {
  final CustomerEntity? customer; // null برای ایجاد مشتری جدید

  const CustomerFormPage({super.key, this.customer});

  @override
  State<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends State<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final _currentDebtController = TextEditingController();
  bool _isActive = true;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _companyController.text = widget.customer!.company ?? '';
      _nationalIdController.text = widget.customer!.nationalId ?? '';
      _creditLimitController.text = widget.customer!.creditLimit.toString();
      _currentDebtController.text = widget.customer!.currentDebt.toString();
      _isActive = widget.customer!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _nationalIdController.dispose();
    _creditLimitController.dispose();
    _currentDebtController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final creditLimit = double.tryParse(_creditLimitController.text) ?? 0.0;
    final currentDebt = double.tryParse(_currentDebtController.text) ?? 0.0;

    if (_isEditing) {
      context.read<CustomerBloc>().add(UpdateCustomer(
        id: widget.customer!.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        nationalId: _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
        creditLimit: creditLimit,
        currentDebt: currentDebt,
        isActive: _isActive,
      ));
    } else {
      context.read<CustomerBloc>().add(CreateCustomer(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        company: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
        nationalId: _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
        creditLimit: creditLimit,
        currentDebt: currentDebt,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ویرایش مشتری' : 'مشتری جدید'),
      ),
      body: BlocConsumer<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is CustomerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CustomerLoading) {
            return const LoadingWidget(message: 'در حال ذخیره...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // نام مشتری
                  CustomTextField(
                    controller: _nameController,
                    label: 'نام مشتری',
                    hint: 'نام و نام خانوادگی',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'نام مشتری را وارد کنید';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // شماره تلفن
                  CustomTextField(
                    controller: _phoneController,
                    label: 'شماره تلفن',
                    hint: '۰۹۱۲۳۴۵۶۷۸۹',
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'شماره تلفن را وارد کنید';
                      }
                      return Validators.validatePhone(value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // ایمیل
                  CustomTextField(
                    controller: _emailController,
                    label: 'ایمیل',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 16),

                  // شرکت
                  CustomTextField(
                    controller: _companyController,
                    label: 'شرکت',
                    hint: 'نام شرکت (اختیاری)',
                  ),
                  const SizedBox(height: 16),

                  // کد ملی/شماره ثبت
                  CustomTextField(
                    controller: _nationalIdController,
                    label: 'کد ملی/شماره ثبت',
                    hint: 'کد ملی یا شماره ثبت شرکت',
                  ),
                  const SizedBox(height: 16),

                  // آدرس
                  CustomTextField(
                    controller: _addressController,
                    label: 'آدرس',
                    hint: 'آدرس مشتری',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // سقف اعتبار
                  CustomTextField(
                    controller: _creditLimitController,
                    label: 'سقف اعتبار (تومان)',
                    hint: '۰',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final number = double.tryParse(value);
                        if (number == null || number < 0) {
                          return 'مقدار معتبر وارد کنید';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // بدهی فعلی
                  CustomTextField(
                    controller: _currentDebtController,
                    label: 'بدهی فعلی (تومان)',
                    hint: '۰',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final number = double.tryParse(value);
                        if (number == null || number < 0) {
                          return 'مقدار معتبر وارد کنید';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // وضعیت فعال بودن
                  SwitchListTile(
                    title: const Text('مشتری فعال'),
                    subtitle: const Text('اگر غیرفعال باشد، نمی‌توان فاکتور صادر کرد'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() => _isActive = value);
                    },
                  ),
                  const SizedBox(height: 32),

                  // دکمه ذخیره
                  CustomButton(
                    text: _isEditing ? 'بروزرسانی' : 'ایجاد مشتری',
                    onPressed: _submitForm,
                    isLoading: state is CustomerLoading,
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