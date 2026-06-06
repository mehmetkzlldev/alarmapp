import '../../domain/entities/sleep_statistics.dart';

/// Hand-written mapping from the `GET /sleep/statistics` JSON to the domain
/// [SleepStatistics] entity. No codegen so the feature compiles standalone.
class SleepStatisticsModel {
  const SleepStatisticsModel._();

  static SleepStatistics fromJson(
    Map<String, dynamic> json,
    StatisticsRange range,
  ) {
    final rawPoints = (json['points'] as List<dynamic>?) ?? const [];
    return SleepStatistics(
      range: range,
      points: rawPoints
          .map((e) => _pointFromJson(e as Map<String, dynamic>))
          .toList(),
      avgDurationMin: (json['avgDurationMin'] as num?)?.toInt() ?? 0,
      consistencyScore: (json['consistencyScore'] as num?)?.toDouble() ?? 0.0,
      missionSuccessRate:
          (json['missionSuccessRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static SleepStatPoint _pointFromJson(Map<String, dynamic> json) {
    return SleepStatPoint(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
      missionSuccessRate:
          (json['missionSuccessRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
