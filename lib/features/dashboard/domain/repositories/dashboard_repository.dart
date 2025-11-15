import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/dashboard_entity.dart';

abstract class DashboardRepository {
  /// دریافت داده‌های داشبورد
  Future<Either<Failure, DashboardEntity>> getDashboardData(String userId);
}
