import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_providers.dart';
import '../../data/datasources/statistics_remote_datasource.dart';
import '../../data/repositories/statistics_repository_impl.dart';
import '../../domain/entities/sleep_statistics.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../../domain/usecases/get_sleep_statistics.dart';

// ---- DI graph --------------------------------------------------------------

final statisticsRemoteDataSourceProvider =
    Provider<StatisticsRemoteDataSource>((ref) {
  return StatisticsRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepositoryImpl(
    ref.watch(statisticsRemoteDataSourceProvider),
  );
});

final getSleepStatisticsProvider = Provider<GetSleepStatistics>((ref) {
  return GetSleepStatistics(ref.watch(statisticsRepositoryProvider));
});

// ---- UI state --------------------------------------------------------------

/// The currently selected range (week/month). The screen flips this and the
/// data provider re-fetches.
final selectedRangeProvider =
    StateProvider<StatisticsRange>((ref) => StatisticsRange.week);

/// Loads statistics for the selected range.
///
/// Errors surface as [AsyncError]; the screen inspects the failure type to
/// distinguish a [PremiumRequiredFailure] (-> upsell) from a generic error
/// (-> retry). We watch [selectedRangeProvider] so changing the range refetches.
final sleepStatisticsProvider =
    FutureProvider.autoDispose<SleepStatistics>((ref) async {
  final range = ref.watch(selectedRangeProvider);
  final usecase = ref.watch(getSleepStatisticsProvider);

  final result = await usecase(GetSleepStatisticsParams(range: range));
  return result.fold(
    // Re-throw the typed Failure so the UI can branch on it via AsyncError.
    (failure) => throw failure,
    (stats) => stats,
  );
});

/// Convenience: true when the current statistics error is a premium gate.
bool isPremiumGate(Object? error) => error is PremiumRequiredFailure;
