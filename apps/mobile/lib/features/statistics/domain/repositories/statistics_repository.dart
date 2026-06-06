import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/sleep_statistics.dart';

/// Contract for sleep-statistics data access.
abstract class StatisticsRepository {
  /// `GET /sleep/statistics?range=week|month`.
  ///
  /// PREMIUM-GATED: returns a [PremiumRequiredFailure] for free users so the
  /// screen can render an upsell instead of charts.
  Future<Either<Failure, SleepStatistics>> getSleepStatistics(
    StatisticsRange range,
  );
}
