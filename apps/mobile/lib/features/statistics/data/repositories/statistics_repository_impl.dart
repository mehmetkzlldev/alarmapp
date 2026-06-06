import 'package:dartz/dartz.dart';

import '../../../../core/error/failure_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/sleep_statistics.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_remote_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  StatisticsRepositoryImpl(this._remote);

  final StatisticsRemoteDataSource _remote;

  @override
  Future<Either<Failure, SleepStatistics>> getSleepStatistics(
    StatisticsRange range,
  ) async {
    try {
      return Right(await _remote.getSleepStatistics(range));
    } catch (e) {
      // A 402/PremiumGuard rejection becomes a PremiumRequiredFailure here,
      // which the screen turns into an upsell.
      return Left(mapExceptionToFailure(e));
    }
  }
}
