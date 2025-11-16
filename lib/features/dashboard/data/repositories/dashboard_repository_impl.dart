
import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_local_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDataSource localDataSource;

  DashboardRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, DashboardEntity>> getDashboardData(String userId) async {
    try {

      final dashboardData = await localDataSource.getDashboardData(userId);

      return Right(dashboardData);
    } on CacheException catch (e) {

      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('خطای نامشخص: ${e.toString()}'));
    }
  }
}

