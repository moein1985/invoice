import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/enums/document_type.dart';
import '../../../../core/enums/document_status.dart';
import '../../../../core/themes/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/date_utils.dart' as date_utils;
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../domain/entities/document_entity.dart';
import '../../domain/entities/document_item_entity.dart';
import '../../domain/usecases/get_next_document_number_usecase.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/document_bloc.dart';
import '../bloc/document_event.dart';
import '../bloc/document_state.dart';

class DocumentFormPage extends StatefulWidget {
  final String? documentId;
  final DocumentType initialType;

  const DocumentFormPage({
    Key? key,
    this.documentId,
    required this.initialType,
  }) : super(key: key);

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  
  late DocumentType _selectedType;
  String? _selectedCustomerId;
  DateTime _selectedDate = DateTime.now();
  DocumentStatus _selectedStatus = DocumentStatus.unpaid;
  final _notesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  
  List<DocumentItemEntity> _items = [];
  bool _isLoading = false;
  String? _documentNumber;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    // Load customers
    context.read<CustomerBloc>().add(const LoadCustomers());

    if (widget.documentId == null) {
      // Generate new document number
      final result = await di.sl<GetNextDocumentNumberUseCase>()(_selectedType);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (number) {
          setState(() => _documentNumber = number);
        },
      );
    } else {
      // Load existing document
      context.read<DocumentBloc>().add(LoadDocumentById(widget.documentId!));
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentId == null ? 'سند جدید' : 'ویرایش سند'),
      ),
      body: BlocListener<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentCreated || state is DocumentUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state is DocumentCreated ? 'سند با موفقیت ایجاد شد' : 'سند با موفقیت به‌روز شد',
                ),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pop(context);
          } else if (state is DocumentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
            );
          } else if (state is DocumentLoaded) {
            _populateForm(state.document);
          }
        },
        child: _isLoading
            ? const LoadingWidget()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDocumentTypeSelector(),
                      const SizedBox(height: 16),
                      _buildDocumentNumber(),
                      const SizedBox(height: 16),
                      _buildCustomerSelector(),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 16),
                      _buildStatusSelector(),
                      const SizedBox(height: 24),
                      _buildItemsSection(),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _discountController,
                        label: 'تخفیف (ریال)',
                        keyboardType: TextInputType.number,
                        validator: (val) => Validators.validateNumber(val, 'تخفیف'),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _notesController,
                        label: 'یادداشت',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      _buildSummary(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: widget.documentId == null ? 'ایجاد سند' : 'به‌روزرسانی سند',
                          onPressed: _saveDocument,
                          icon: Icons.save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDocumentTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text('نوع سند:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 16),
            Expanded(
              child: SegmentedButton<DocumentType>(
                segments: const [
                  ButtonSegment(value: DocumentType.invoice, label: Text('فاکتور')),
                  ButtonSegment(value: DocumentType.proforma, label: Text('پیش‌فاکتور')),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<DocumentType> newSelection) {
                  setState(() => _selectedType = newSelection.first);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentNumber() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.numbers),
        title: const Text('شماره سند'),
        subtitle: Text(_documentNumber ?? 'در حال تولید...'),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomersLoaded) {
          final customers = state.customers;
          return DropdownButtonFormField<String>(
            value: _selectedCustomerId,
            decoration: const InputDecoration(
              labelText: 'مشتری',
              prefixIcon: Icon(Icons.person),
            ),
            items: customers.map((customer) {
              return DropdownMenuItem(
                value: customer.id,
                child: Text(customer.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCustomerId = value);
            },
            validator: (value) => value == null ? 'انتخاب مشتری الزامی است' : null,
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  Widget _buildDatePicker() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today),
        title: const Text('تاریخ سند'),
        subtitle: Text(date_utils.PersianDateUtils.toJalali(_selectedDate)),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() => _selectedDate = date);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('وضعیت:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: DocumentStatus.values.map((status) {
                return ChoiceChip(
                  label: Text(status.toFarsi()),
                  selected: _selectedStatus == status,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatus = status);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ردیف‌ها:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('افزودن ردیف'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('هنوز ردیفی اضافه نشده است'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.grey[50],
                    child: ListTile(
                      title: Text(item.productName),
                      subtitle: Text(
                        'تعداد: ${item.quantity} × ${item.unitPrice.toStringAsFixed(0)} = ${item.totalPrice.toStringAsFixed(0)} ریال',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () {
                          setState(() => _items.removeAt(index));
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final totalAmount = _items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final discount = double.tryParse(_discountController.text) ?? 0;
    final finalAmount = totalAmount - discount;

    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('جمع کل', totalAmount),
            _buildSummaryRow('تخفیف', discount),
            const Divider(),
            _buildSummaryRow('مبلغ نهایی', finalAmount, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${amount.toStringAsFixed(0)} ریال',
            style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        onAdd: (item) {
          setState(() => _items.add(item));
        },
      ),
    );
  }

  void _populateForm(DocumentEntity document) {
    setState(() {
      _selectedType = document.documentType;
      _selectedCustomerId = document.customerId;
      _selectedDate = document.documentDate;
      _selectedStatus = document.status;
      _notesController.text = document.notes ?? '';
      _discountController.text = document.discount.toString();
      _items = List.from(document.items);
      _documentNumber = document.documentNumber;
    });
  }

  void _saveDocument() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک ردیف باید اضافه کنید')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final totalAmount = _items.fold<double>(0, (sum, item) => sum + item.totalPrice);
    final discount = double.tryParse(_discountController.text) ?? 0;
    final finalAmount = totalAmount - discount;

    final document = DocumentEntity(
      id: widget.documentId ?? _uuid.v4(),
      userId: authState.user.id,
      documentNumber: _documentNumber!,
      documentType: _selectedType,
      customerId: _selectedCustomerId!,
      documentDate: _selectedDate,
      items: _items,
      totalAmount: totalAmount,
      discount: discount,
      finalAmount: finalAmount,
      status: _selectedStatus,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.documentId == null) {
      context.read<DocumentBloc>().add(CreateDocument(document));
    } else {
      context.read<DocumentBloc>().add(UpdateDocument(document));
    }
  }
}

class _AddItemDialog extends StatefulWidget {
  final Function(DocumentItemEntity) onAdd;

  const _AddItemDialog({required this.onAdd});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _profitPercentageController = TextEditingController(text: '0');
  final _supplierController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _profitPercentageController.dispose();
    _supplierController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن ردیف'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: _productNameController,
                label: 'نام محصول',
                validator: (val) => Validators.validateRequired(val, 'نام محصول'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _quantityController,
                label: 'تعداد',
                keyboardType: TextInputType.number,
                validator: (val) => Validators.validatePositiveNumber(val, 'تعداد'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _unitPriceController,
                label: 'قیمت واحد',
                keyboardType: TextInputType.number,
                validator: (val) => Validators.validatePositiveNumber(val, 'قیمت واحد'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _profitPercentageController,
                label: 'درصد سود',
                keyboardType: TextInputType.number,
                validator: (val) => Validators.validateNumber(val, 'درصد سود'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _supplierController,
                label: 'تامین‌کننده',
                validator: (val) => Validators.validateRequired(val, 'تامین‌کننده'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descriptionController,
                label: 'توضیحات',
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('لغو'),
        ),
        ElevatedButton(
          onPressed: _addItem,
          child: const Text('افزودن'),
        ),
      ],
    );
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text);
    final unitPrice = double.parse(_unitPriceController.text);
    final totalPrice = quantity * unitPrice;

    final item = DocumentItemEntity(
      id: const Uuid().v4(),
      productName: _productNameController.text,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      profitPercentage: double.parse(_profitPercentageController.text),
      supplier: _supplierController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
    );

    widget.onAdd(item);
    Navigator.pop(context);
  }
}
