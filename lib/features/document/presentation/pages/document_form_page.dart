import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/utils/logger.dart';
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
    super.key,
    this.documentId,
    required this.initialType,
  });

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
  final _attachmentController = TextEditingController(); // یادداشت/پیوست
  final _defaultProfitController = TextEditingController(text: '22'); // درصد سود پیش‌فرض
  
  List<DocumentItemEntity> _items = [];
  bool _isLoading = false;
  String? _documentNumber;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    // اجرای بارگذاری اولیه بعد از اولین فریم برای اطمینان از دسترسی به Provider ها
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    AppLogger.debug('Initial form load started existingId=${widget.documentId} initialType=${_selectedType}', 'DocumentForm');
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
          AppLogger.debug('Generated document number=$_documentNumber type=$_selectedType', 'DocumentForm');
        },
      );
    } else {
      // Load existing document
      AppLogger.debug('Loading existing document id=${widget.documentId}', 'DocumentForm');
      context.read<DocumentBloc>().add(LoadDocumentById(widget.documentId!));
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _discountController.dispose();
    _attachmentController.dispose();
    _defaultProfitController.dispose();
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
                      _buildDocumentInfo(),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      _buildCustomerSelector(),
                      const SizedBox(height: 16),
                      _buildDatePicker(),
                      const SizedBox(height: 16),
                      _buildStatusSelector(),
                      const SizedBox(height: 16),
                      // درصد سود پیش‌فرض
                      CustomTextField(
                        controller: _defaultProfitController,
                        label: 'درصد سود پیش‌فرض (%)',
                        keyboardType: TextInputType.number,
                        validator: (val) => Validators.validateNumber(val, 'درصد سود'),
                      ),
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
                      const SizedBox(height: 16),
                      // یادداشت/پیوست
                      CustomTextField(
                        controller: _attachmentController,
                        label: 'پیوست (مثلاً: این پیش‌فاکتور برای قرارداد 22/44)',
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      _buildSummary(),
                      const SizedBox(height: 24),
                      // دکمه‌های اصلی
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: widget.documentId == null ? 'ایجاد سند' : 'به‌روزرسانی سند',
                              onPressed: _saveDocument,
                              icon: Icons.save,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              text: 'خالی کردن فرم',
                              onPressed: _clearForm,
                              icon: Icons.clear_all,
                              backgroundColor: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      // دکمه تبدیل (فقط برای پیش‌فاکتور موقت و پیش‌فاکتور)
                      if (_selectedType.nextType != null && widget.documentId != null) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: _selectedType.convertButtonText ?? 'تبدیل',
                            onPressed: _convertDocument,
                            icon: Icons.arrow_forward,
                            backgroundColor: AppColors.warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDocumentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(_getDocumentTypeIcon(_selectedType), color: _getDocumentTypeColor(_selectedType)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedType.toFarsi(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getDocumentTypeColor(_selectedType),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'شماره: ${_documentNumber ?? 'در حال تولید...'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.tempProforma:
        return Icons.edit_note;
      case DocumentType.proforma:
        return Icons.description;
      case DocumentType.invoice:
        return Icons.receipt;
      case DocumentType.returnInvoice:
        return Icons.assignment_return;
    }
  }

  Color _getDocumentTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.tempProforma:
        return Colors.orange;
      case DocumentType.proforma:
        return Colors.blue;
      case DocumentType.invoice:
        return Colors.green;
      case DocumentType.returnInvoice:
        return Colors.red;
    }
  }

  Widget _buildCustomerSelector() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        if (state is CustomersLoaded) {
          final customers = state.customers;
          return DropdownButtonFormField<String>(
            key: ValueKey('customer_${_selectedCustomerId ?? 'none'}'),
            initialValue: _selectedCustomerId,
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('تعداد: ${item.quantity} ${item.unit}'),
                          Text('قیمت خرید: ${item.purchasePrice.toStringAsFixed(0)} | قیمت فروش: ${item.sellPrice.toStringAsFixed(0)} ریال'),
                          Text('سود: ${item.profitAmount.toStringAsFixed(0)} ریال | جمع: ${item.totalPrice.toStringAsFixed(0)} ریال'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.primary),
                            onPressed: () => _editItem(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.error),
                            onPressed: () {
                              setState(() => _items.removeAt(index));
                            },
                          ),
                        ],
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
      color: AppColors.primary.withValues(alpha: 0.1),
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
    final defaultProfit = double.tryParse(_defaultProfitController.text) ?? 22.0;
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        defaultProfitPercentage: defaultProfit,
        onAdd: (item) {
          setState(() => _items.add(item));
          AppLogger.debug('Item added id=${item.id} name=${item.productName} qty=${item.quantity} purchase=${item.purchasePrice} sell=${item.sellPrice} profit=${item.profitAmount}', 'DocumentForm');
        },
      ),
    );
  }

  void _editItem(int index) {
    final item = _items[index];
    final defaultProfit = double.tryParse(_defaultProfitController.text) ?? 22.0;
    showDialog(
      context: context,
      builder: (context) => _AddItemDialog(
        defaultProfitPercentage: defaultProfit,
        existingItem: item,
        onAdd: (updatedItem) {
          setState(() => _items[index] = updatedItem);
          AppLogger.debug('Item edited id=${updatedItem.id} name=${updatedItem.productName} qty=${updatedItem.quantity} purchase=${updatedItem.purchasePrice} sell=${updatedItem.sellPrice} profit=${updatedItem.profitAmount}', 'DocumentForm');
        },
      ),
    );
  }

  void _populateForm(DocumentEntity document) {
    AppLogger.debug('Populating form id=${document.id} number=${document.documentNumber} type=${document.documentType} items=${document.items.length}', 'DocumentForm');
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

  void _clearForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأیید'),
        content: const Text('آیا مطمئن هستید که می‌خواهید فرم را خالی کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.clear();
                _notesController.clear();
                _discountController.text = '0';
                _attachmentController.clear();
                _defaultProfitController.text = '22';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('فرم با موفقیت خالی شد')),
              );
            },
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
  }

  void _convertDocument() {
    final nextType = _selectedType.nextType;
    if (nextType == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_selectedType.convertButtonText ?? 'تبدیل'),
        content: Text('آیا مطمئن هستید که می‌خواهید این سند را به ${nextType.toFarsi()} تبدیل کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: پیاده‌سازی منطق تبدیل
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('عملیات تبدیل در حال پیاده‌سازی است')),
              );
            },
            child: const Text('تبدیل'),
          ),
        ],
      ),
    );
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
    final defaultProfit = double.tryParse(_defaultProfitController.text) ?? 22.0;

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
      attachment: _attachmentController.text.isEmpty ? null : _attachmentController.text,
      defaultProfitPercentage: defaultProfit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (widget.documentId == null) {
      AppLogger.info('Dispatch CreateDocument number=${document.documentNumber} type=${document.documentType} items=${document.items.length}', 'DocumentForm');
      context.read<DocumentBloc>().add(CreateDocument(document));
    } else {
      AppLogger.info('Dispatch UpdateDocument id=${document.id} number=${document.documentNumber} type=${document.documentType} items=${document.items.length}', 'DocumentForm');
      context.read<DocumentBloc>().add(UpdateDocument(document));
    }
  }
}

class _AddItemDialog extends StatefulWidget {
  final Function(DocumentItemEntity) onAdd;
  final double defaultProfitPercentage;
  final DocumentItemEntity? existingItem;

  const _AddItemDialog({
    required this.onAdd,
    required this.defaultProfitPercentage,
    this.existingItem,
  });

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'عدد');
  final _purchasePriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _profitPercentageController = TextEditingController();
  final _supplierController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isManualPrice = false; // آیا قیمت دستی است؟

  @override
  void initState() {
    super.initState();
    
    // اگر آیتم موجود است، فیلدها را پر کن
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _productNameController.text = item.productName;
      _quantityController.text = item.quantity.toString();
      _unitController.text = item.unit;
      _purchasePriceController.text = item.purchasePrice.toStringAsFixed(0);
      _sellPriceController.text = item.sellPrice.toStringAsFixed(0);
      _profitPercentageController.text = item.profitPercentage.toStringAsFixed(1);
      _supplierController.text = item.supplier;
      _descriptionController.text = item.description ?? '';
      _isManualPrice = item.isManualPrice;
    } else {
      // پر کردن درصد سود با مقدار پیش‌فرض
      _profitPercentageController.text = widget.defaultProfitPercentage.toStringAsFixed(1);
    }
    
    // محاسبه خودکار قیمت فروش وقتی قیمت خرید تغییر می‌کند
    _purchasePriceController.addListener(_calculateSellPrice);
    _profitPercentageController.addListener(_calculateSellPrice);
  }

  void _calculateSellPrice() {
    if (_isManualPrice) return; // اگر قیمت دستی است، محاسبه نکن
    
    final purchasePrice = double.tryParse(_purchasePriceController.text);
    final profitPercentage = double.tryParse(_profitPercentageController.text);
    
    if (purchasePrice != null && profitPercentage != null) {
      final sellPrice = purchasePrice * (1 + profitPercentage / 100);
      _sellPriceController.text = sellPrice.toStringAsFixed(0);
      AppLogger.debug('Auto sell price calculated purchase=$purchasePrice profit%=$profitPercentage sell=$sellPrice', 'ItemDialog');
    }
  }

  @override
  void dispose() {
    _productNameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _purchasePriceController.dispose();
    _sellPriceController.dispose();
    _profitPercentageController.dispose();
    _supplierController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem != null ? 'ویرایش ردیف' : 'افزودن ردیف'),
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
                controller: _unitController,
                label: 'واحد',
                validator: (val) => Validators.validateRequired(val, 'واحد'),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _purchasePriceController,
                label: 'قیمت خرید',
                keyboardType: TextInputType.number,
                validator: (val) => Validators.validatePositiveNumber(val, 'قیمت خرید'),
              ),
              const SizedBox(height: 12),
              // چک‌باکس قیمت دستی
              CheckboxListTile(
                title: const Text('قیمت فروش دستی'),
                value: _isManualPrice,
                onChanged: (value) {
                  setState(() {
                    _isManualPrice = value ?? false;
                    if (!_isManualPrice) {
                      // اگر حالت خودکار شد، دوباره محاسبه کن
                      _calculateSellPrice();
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              // اگر قیمت دستی نیست، فیلد درصد سود نشان بده
              if (!_isManualPrice) ...[
                CustomTextField(
                  controller: _profitPercentageController,
                  label: 'درصد سود (%)',
                  keyboardType: TextInputType.number,
                  validator: (val) => Validators.validateNumber(val, 'درصد سود'),
                ),
                const SizedBox(height: 12),
              ],
              CustomTextField(
                controller: _sellPriceController,
                label: 'قیمت فروش',
                keyboardType: TextInputType.number,
                validator: (val) => Validators.validatePositiveNumber(val, 'قیمت فروش'),
                readOnly: !_isManualPrice, // فقط در حالت دستی قابل ویرایش
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
          child: Text(widget.existingItem != null ? 'ذخیره' : 'افزودن'),
        ),
      ],
    );
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = int.parse(_quantityController.text);
    final purchasePrice = double.parse(_purchasePriceController.text);
    final profitPercentage = _isManualPrice 
        ? null 
        : double.tryParse(_profitPercentageController.text);
    final sellPrice = _isManualPrice 
        ? double.parse(_sellPriceController.text) 
        : null;

    final item = DocumentItemEntity.create(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      productName: _productNameController.text,
      quantity: quantity,
      unit: _unitController.text,
      purchasePrice: purchasePrice,
      sellPrice: sellPrice,
      profitPercentage: profitPercentage,
      supplier: _supplierController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      isManualPrice: _isManualPrice,
    );

    widget.onAdd(item);
    AppLogger.debug('Dialog submit item id=${item.id} name=${item.productName} qty=${item.quantity} purchase=${item.purchasePrice} sell=${item.sellPrice} profit=${item.profitAmount}', 'ItemDialog');
    Navigator.pop(context);
  }
}
