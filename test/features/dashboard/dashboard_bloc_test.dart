import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:invoice/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:invoice/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:invoice/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:invoice/features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:invoice/features/dashboard/domain/entities/dashboard_entity.dart';

class MockGetDashboard extends Mock implements GetDashboardDataUseCase {}

void main() {
  late MockGetDashboard mockGetDashboard;
  late DashboardBloc bloc;

  setUp(() {
    mockGetDashboard = MockGetDashboard();
    bloc = DashboardBloc(getDashboardDataUseCase: mockGetDashboard);
  });

  test('emits [DashboardLoading, DashboardLoaded] when load succeeds', () async {
    final data = DashboardEntity(
      totalInvoices: 5,
      totalRevenue: 1000,
      totalCustomers: 3,
      pendingInvoices: 1,
      monthlyRevenue: 200,
      monthlyData: const [],
      recentInvoices: const [],
    );

    when(() => mockGetDashboard('u1')).thenAnswer((_) async => Right(data));

    final expected = [const DashboardLoading(), DashboardLoaded(data)];
    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const LoadDashboardData('u1'));
  });
}
