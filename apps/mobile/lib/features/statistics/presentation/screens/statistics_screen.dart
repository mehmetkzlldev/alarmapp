import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../../core/error/failures.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../domain/entities/sleep_statistics.dart';
import '../providers/statistics_provider.dart';

/// Sleep & mission statistics dashboard (premium feature).
///
/// Renders three fl_chart visualizations:
///   1. Sleep duration trend (line chart)
///   2. Mission success rate per day (bar chart)
///   3. Consistency score (summary gauge-style card)
///
/// For non-premium users the backend returns a [PremiumRequiredFailure]; we
/// detect it and show a paywall upsell instead of charts.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key, this.onUpgrade});

  /// Navigation callback to the paywall (e.g. `context.go('/paywall')`).
  /// Provided by the router so this screen stays navigation-agnostic.
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final range = ref.watch(selectedRangeProvider);
    // Client-side premium signal (server remains authoritative via PremiumGuard).
    // When we already know the user is free, show the upsell immediately rather
    // than waiting for the API to return a 402.
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _RangeSelector(
            selected: range,
            onChanged: (r) =>
                ref.read(selectedRangeProvider.notifier).state = r,
          ),
        ),
      ),
      body: !isPremium
          ? _PremiumUpsell(
              message: l10n.statsUpsellMessage,
              onUpgrade: onUpgrade,
            )
          : _buildPremiumBody(context, ref),
    );
  }

  Widget _buildPremiumBody(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statsAsync = ref.watch(sleepStatisticsProvider);
    return statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          // Premium gate -> upsell; anything else -> retry.
          if (error is PremiumRequiredFailure) {
            return _PremiumUpsell(
              message: error.message,
              onUpgrade: onUpgrade,
            );
          }
          final message =
              error is Failure ? error.message : l10n.statsLoadError;
          return _ErrorRetry(
            message: message,
            onRetry: () => ref.invalidate(sleepStatisticsProvider),
          );
        },
        data: (stats) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(sleepStatisticsProvider),
          child: stats.hasData
              ? _StatsContent(stats: stats)
              : const _EmptyState(),
        ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onChanged});

  final StatisticsRange selected;
  final ValueChanged<StatisticsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
      child: SegmentedButton<StatisticsRange>(
        segments: StatisticsRange.values
            .map((r) => ButtonSegment(value: r, label: Text(r.label)))
            .toList(),
        selected: {selected},
        onSelectionChanged: (set) => onChanged(set.first),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final SleepStatistics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryRow(stats: stats),
        const SizedBox(height: 24),
        _ChartCard(
          title: l10n.statsSleepDuration,
          subtitle: l10n.statsSleepDurationSubtitle,
          child: SizedBox(
            height: 220,
            child: _SleepDurationChart(points: stats.points),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: l10n.statsMissionSuccessRate,
          subtitle: l10n.statsMissionSuccessRateSubtitle,
          child: SizedBox(
            height: 220,
            child: _MissionSuccessChart(points: stats.points),
          ),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: l10n.statsConsistency,
          subtitle: l10n.statsConsistencySubtitle,
          child: _ConsistencyGauge(score: stats.consistencyScore),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.stats});

  final SleepStatistics stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: l10n.statsAvgSleep,
            value: stats.avgDurationLabel,
            icon: Icons.bedtime,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: l10n.statsMissions,
            value: l10n.statsPercentValue(stats.missionSuccessPercent),
            icon: Icons.task_alt,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: l10n.statsConsistency,
            value: l10n.statsPercentValue(stats.consistencyPercent),
            icon: Icons.timeline,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// Line chart of sleep duration (hours) over time.
class _SleepDurationChart extends StatelessWidget {
  const _SleepDurationChart({required this.points});

  final List<SleepStatPoint> points;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].durationHours),
    ];

    return LineChart(
      LineChartData(
        minY: 0,
        // A little headroom above the max so the line never touches the top.
        maxY: _niceMax(points.map((p) => p.durationHours)),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 2,
              getTitlesWidget: (value, meta) => Text(
                l10n.statsHoursAxis(value.toInt()),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _bottomInterval(points.length),
              getTitlesWidget: (value, meta) =>
                  _bottomLabel(value, points, theme),
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: theme.colorScheme.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bar chart of per-day mission success rate (0..100%).
class _MissionSuccessChart extends StatelessWidget {
  const _MissionSuccessChart({required this.points});

  final List<SleepStatPoint> points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BarChart(
      BarChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}%',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (value, meta) =>
                  _bottomLabel(value, points, theme),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (points[i].missionSuccessRate * 100).clamp(0, 100),
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A simple linear gauge for the consistency score.
class _ConsistencyGauge extends StatelessWidget {
  const _ConsistencyGauge({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pct = (score * 100).round().clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.statsPercentValue(pct),
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _consistencyBlurb(l10n, pct),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  String _consistencyBlurb(AppLocalizations l10n, int pct) {
    if (pct >= 80) return l10n.statsConsistencyBlurbExcellent;
    if (pct >= 50) return l10n.statsConsistencyBlurbDecent;
    return l10n.statsConsistencyBlurbIrregular;
  }
}

// ---- Shared bottom-axis helpers -------------------------------------------

double _bottomInterval(int count) {
  if (count <= 7) return 1;
  // For a month, label roughly weekly to avoid crowding.
  return (count / 6).ceilToDouble();
}

Widget _bottomLabel(double value, List<SleepStatPoint> points, ThemeData theme) {
  final i = value.toInt();
  if (i < 0 || i >= points.length) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      DateFormat('E').format(points[i].date), // Mon, Tue, ...
      style: theme.textTheme.bodySmall,
    ),
  );
}

double _niceMax(Iterable<double> values) {
  final maxVal = values.isEmpty ? 0.0 : values.reduce((a, b) => a > b ? a : b);
  // Round up to the next even number of hours, minimum of 8 for sane axes.
  final rounded = (maxVal / 2).ceil() * 2;
  return rounded < 8 ? 8 : rounded.toDouble();
}

// ---- Non-data states -------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Must be scrollable for RefreshIndicator to work when empty.
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.insights, size: 72, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Center(
          child: Text(l10n.statsNoDataTitle, style: theme.textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.statsNoDataBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumUpsell extends StatelessWidget {
  const _PremiumUpsell({required this.message, this.onUpgrade});

  final String message;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium,
                size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.statsUpsellTitle,
                style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.lock_open),
              label: Text(l10n.statsGoPremium),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: Text(l10n.statsRetry)),
          ],
        ),
      ),
    );
  }
}
