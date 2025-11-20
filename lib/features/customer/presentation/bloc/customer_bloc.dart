import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/delete_customer_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/search_customers_usecase.dart';
import '../../domain/usecases/toggle_customer_status_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';

part 'customer_event.dart';
part 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final GetCustomersUseCase getCustomersUseCase;
  final CreateCustomerUseCase createCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;
  final SearchCustomersUseCase searchCustomersUseCase;
  final ToggleCustomerStatusUseCase toggleCustomerStatusUseCase;

  CustomerBloc({
    required this.getCustomersUseCase,
    required this.createCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
    required this.searchCustomersUseCase,
    required this.toggleCustomerStatusUseCase,
  }) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers);
    on<SearchCustomers>(_onSearchCustomers);
    on<CreateCustomer>(_onCreateCustomer);
    on<UpdateCustomer>(_onUpdateCustomer);
    on<DeleteCustomer>(_onDeleteCustomer);
    on<ToggleCustomerStatus>(_onToggleCustomerStatus);
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await getCustomersUseCase.call();
    result.fold(
      (failure) {
        debugPrint('🔴 [CustomerBloc] Failed to load customers: ${failure.message}');
        emit(CustomerError(failure.message));
      },
      (customers) => emit(CustomersLoaded(customers)),
    );
  }

  Future<void> _onSearchCustomers(
    SearchCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await searchCustomersUseCase.call(event.query);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customers) => emit(CustomersLoaded(customers)),
    );
  }

  Future<void> _onCreateCustomer(
    CreateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await createCustomerUseCase.call(
      name: event.name,
      phone: event.phone,
      email: event.email,
      address: event.address,
      company: event.company,
      nationalId: event.nationalId,
      creditLimit: event.creditLimit,
      currentDebt: event.currentDebt,
    );
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) => emit(CustomerOperationSuccess('مشتری با موفقیت ایجاد شد', customer)),
    );
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await updateCustomerUseCase.call(
      id: event.id,
      name: event.name,
      phone: event.phone,
      email: event.email,
      address: event.address,
      company: event.company,
      nationalId: event.nationalId,
      creditLimit: event.creditLimit,
      currentDebt: event.currentDebt,
      isActive: event.isActive,
    );
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) => emit(CustomerOperationSuccess('مشتری با موفقیت بروزرسانی شد', customer)),
    );
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomer event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await deleteCustomerUseCase.call(event.customerId);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (_) => emit(const CustomerOperationSuccess('مشتری با موفقیت حذف شد')),
    );
  }

  Future<void> _onToggleCustomerStatus(
    ToggleCustomerStatus event,
    Emitter<CustomerState> emit,
  ) async {
    emit(CustomerLoading());
    final result = await toggleCustomerStatusUseCase.call(event.customerId);
    result.fold(
      (failure) => emit(CustomerError(failure.message)),
      (customer) => emit(CustomerOperationSuccess(
        customer.isActive ? 'مشتری فعال شد' : 'مشتری غیرفعال شد',
        customer,
      )),
    );
  }
}
