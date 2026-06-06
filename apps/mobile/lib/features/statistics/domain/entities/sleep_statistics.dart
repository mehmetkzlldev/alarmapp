import 'package:equatable/equatable.dart';

/// The time window for a statistics query. Matches the `range` query param of
/// `GET /sleep/statistics?range=week|month`.
enum StatisticsRange {
  week('week'),
  month('month');

  const StatisticsRange(this.wireValue);

  final String wireValue;

  String get label => switch (this) {
        StatisticsRange.week => 'Week',
        StatisticsRange.month => 'Month',
      };
}

/// A single point on the sleep-statistics timeline. The backend returns a
/// `points` array; each point captures one night/day's aggregates.
class SleepStatPoint extends Equatable {
  const SleepStatPoint({
    required this.date,
    required this.durationMin,
    required this.missionSuccessRate,
  });

  /// The calendar date the point represents.
  final DateTime date;

  /// Total sleep duration for that date, in minutes.
  final int durationMin;

  /// Mission success rate (0..1) for alarms on that date.
  final double missionSuccessRate;

  /// Convenience: duration expressed in fractional hours for charting.
  double get durationHours => durationMin / 60.0;

  @override
  List<Object?> get props => [date, durationMin, missionSuccessRate];
}

/// Aggregated sleep statistics for a range.
///
/// Mirrors `GET /sleep/statistics` ->
/// `{ points, avgDurationMin, consistencyScore, missionSuccessRate }`.
class SleepStatistics extends Equatable {
  const SleepStatistics({
    required this.range,
    required this.points,
    required this.avgDurationMin,
    required this.consistencyScore,
    required this.missionSuccessRate,
  });

  /// Empty result (e.g. brand-new user with no data yet).
  factory SleepStatistics.empty(StatisticsRange range) => SleepStatistics(
        range: range,
        points: const [],
        avgDurationMin: 0,
        consistencyScore: 0,
        missionSuccessRate: 0,
      );

  final StatisticsRange range;
  final List<SleepStatPoint> points;

  /// Average sleep duration across the range, in minutes.
  final int avgDurationMin;

  /// How consistent the user's sleep schedule is, 0..1 (1 = perfectly regular).
  final double consistencyScore;

  /// Overall mission success rate across the range, 0..1.
  final double missionSuccessRate;

  bool get hasData => points.isNotEmpty;

  /// Average duration formatted as "7h 30m".
  String get avgDurationLabel {
    final h = avgDurationMin ~/ 60;
    final m = avgDurationMin % 60;
    return '${h}h ${m}m';
  }

  int get consistencyPercent => (consistencyScore * 100).round().clamp(0, 100);
  int get missionSuccessPercent =>
      (missionSuccessRate * 100).round().clamp(0, 100);

  @override
  List<Object?> get props =>
      [range, points, avgDurationMin, consistencyScore, missionSuccessRate];
}
