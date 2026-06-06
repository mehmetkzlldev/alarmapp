import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/sleep_statistics.dart';
import '../repositories/statistics_repository.dart';

/// Fetches aggregated sleep statistics for a range via
/// `GET /sleep/statistics?range=week|month`.
class GetSleepStatistics
    implements UseCase<SleepStatistics, GetSleepStatisticsParams> {
  const GetSleepStatistics(this._repository);

  final StatisticsRepository _repository;

  @override
  Future<Either<Failure, SleepStatistics>> call(
    GetSleepStatisticsParams params,
  ) {
    return _repository.getSleepStatistics(params.range);
  }
}

class GetSleepStatisticsParams extends Equatable {
  const GetSleepStatisticsParams({required this.range});

  final StatisticsRange range;

  @override
  List<Object?> get props => [range];
}
