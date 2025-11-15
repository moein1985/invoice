import 'package:equatable/equatable.dart';
import '../../domain/entities/dashboard_entity.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

/// وضعیت اولیه
class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

/// در حال بارگذاری
class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

/// داده‌های داشبورد بارگذاری شده
class DashboardLoaded extends DashboardState {
  final DashboardEntity dashboardData;

  const DashboardLoaded(this.dashboardData);

  @override
  List<Object?> get props => [dashboardData];
}

/// خطا
class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
