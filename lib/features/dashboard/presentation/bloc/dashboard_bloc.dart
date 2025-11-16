
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardDataUseCase getDashboardDataUseCase;

  DashboardBloc({
    required this.getDashboardDataUseCase,
  }) : super(const DashboardInitial()) {
    on<LoadDashboardData>(_onLoadDashboardData);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<DashboardState> emit,
  ) async {

    emit(const DashboardLoading());

    final result = await getDashboardDataUseCase(event.userId);

    result.fold(
      (failure) {

        emit(DashboardError(failure.message));
      },
      (dashboardData) {

        emit(DashboardLoaded(dashboardData));
      },
    );
  }
}
