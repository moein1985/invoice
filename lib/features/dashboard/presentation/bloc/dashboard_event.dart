import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// درخواست بارگذاری داده‌های داشبورد
class LoadDashboardData extends DashboardEvent {
  final String userId;
  
  const LoadDashboardData(this.userId);
  
  @override
  List<Object?> get props => [userId];
}
