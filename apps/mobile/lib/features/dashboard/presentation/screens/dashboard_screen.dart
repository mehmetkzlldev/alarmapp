import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../alarm_ring/presentation/screens/wake_challenge_screen.dart';
import '../../../alarms/domain/entities/alarm_entity.dart';
import '../../../alarms/presentation/providers/alarms_provider.dart';
import '../../../alarms/presentation/screens/alarm_create_screen.dart';
import '../../../alarms/presentation/screens/alarm_list_screen.dart';

/// Home dashboard.
///
/// Shows, top to bottom:
///   1. the next alarm that will fire (derived from the alarms feature),
///   2. today's AI mission (premium-gated; falls back to an upsell),
///   3. quick sleep stats, and
///   4. quick navigation to the alarms list.
///
/// The AI-mission and stats cards read [todaysAiMissionProvider] and
/// [quickStatsProvider]. Those default to "not loaded" sentinels and are meant
/// to be overridden by the ai-missions / sleep features once wired; the
/// dashboard renders gracefully in the meantime.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final nextAlarm = ref.watch(nextAlarmProvider);
    final alarmsAsync = ref.watch(alarmsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashGoodMorning),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l10n.dashAllAlarms,
            onPressed: () => _openAlarms(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AlarmCreateScreen()),
        ),
        child: const Icon(Icons.add_alarm),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alarmsNotifierProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _NextAlarmCard(
              alarm: nextAlarm,
              loading: alarmsAsync.isLoading && !alarmsAsync.hasValue,
              onTap: () => _openAlarms(context),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.alarm_on),
                title: Text(l10n.dashTryChallengeTitle),
                subtitle: Text(l10n.dashTryChallengeSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WakeChallengeScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _AiMissionCard(),
            const SizedBox(height: 16),
            const _QuickStatsCard(),
            const SizedBox(height: 16),
            _DashboardNav(onOpenAlarms: () => _openAlarms(context)),
          ],
        ),
      ),
    );
  }

  void _openAlarms(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlarmListScreen()),
    );
  }
}

// ---------------------------------------------------------------------------
// Next alarm card
// ---------------------------------------------------------------------------

class _NextAlarmCard extends StatelessWidget {
  const _NextAlarmCard({
    required this.alarm,
    required this.loading,
    required this.onTap,
  });

  final AlarmEntity? alarm;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.alarm, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: loading
                    ? const _CardSkeleton()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.dashNextAlarm,
                              style: theme.textTheme.labelLarge),
                          const SizedBox(height: 4),
                          if (alarm == null)
                            Text(l10n.dashNoActiveAlarms,
                                style: theme.textTheme.titleLarge)
                          else ...[
                            Text(
                              _formatTime(context, alarm!),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _subtitle(l10n, alarm!),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, AlarmEntity a) {
    final hm = a.hourMinute;
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final mm = hm.minute.toString().padLeft(2, '0');
    if (use24h) return '${hm.hour.toString().padLeft(2, '0')}:$mm';
    final l10n = AppLocalizations.of(context);
    final period = hm.hour < 12 ? l10n.timeAm : l10n.timePm;
    final h12 = hm.hour % 12 == 0 ? 12 : hm.hour % 12;
    return '$h12:$mm $period';
  }

  String _subtitle(AppLocalizations l10n, AlarmEntity a) {
    final label = a.label.isEmpty ? l10n.alarmDefaultLabel : a.label;
    if (a.missions.isEmpty) return label;
    return l10n.dashAlarmMissionCount(label, a.missions.length);
  }
}

// ---------------------------------------------------------------------------
// AI mission card (premium-gated)
// ---------------------------------------------------------------------------

/// Lightweight view model for `GET /ai-missions/today`. Kept here (not in a
/// feature folder) so the dashboard compiles independently; replace with the
/// ai-missions feature's provider via override when available.
class TodaysAiMission {
  const TodaysAiMission({
    required this.id,
    required this.instruction,
    required this.targetObject,
    required this.premiumLocked,
  });

  /// Sentinel for a not-yet-loaded / unavailable mission.
  const TodaysAiMission.none()
      : id = null,
        instruction = null,
        targetObject = null,
        premiumLocked = false;

  /// Sentinel shown to free users hitting the premium gate.
  const TodaysAiMission.locked()
      : id = null,
        instruction = null,
        targetObject = null,
        premiumLocked = true;

  final String? id;
  final String? instruction;
  final String? targetObject;
  final bool premiumLocked;

  bool get hasMission => id != null;
}

/// Override this in ProviderScope with the real ai-missions provider.
final todaysAiMissionProvider = Provider<AsyncValue<TodaysAiMission>>(
  (ref) => const AsyncData(TodaysAiMission.none()),
);

class _AiMissionCard extends ConsumerWidget {
  const _AiMissionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(todaysAiMissionProvider);

    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.auto_awesome, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: async.when(
                loading: () => const _CardSkeleton(),
                error: (_, __) => Text(
                  l10n.dashAiMissionUnavailable,
                  style: theme.textTheme.bodyMedium,
                ),
                data: (mission) => _content(context, mission),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, TodaysAiMission mission) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (mission.premiumLocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashAiMissionTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(l10n.dashAiMissionUnlock,
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {}, // subscriptions feature handles purchase flow
            child: Text(l10n.dashGoPremium),
          ),
        ],
      );
    }
    if (!mission.hasMission) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dashAiMissionTitle, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(l10n.dashAiMissionNone,
              style: theme.textTheme.bodyMedium),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashAiMissionTitle, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          mission.instruction ?? '',
          style: theme.textTheme.titleMedium,
        ),
        if (mission.targetObject != null) ...[
          const SizedBox(height: 4),
          Chip(
            avatar: const Icon(Icons.center_focus_strong, size: 16),
            label: Text(mission.targetObject!),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Quick stats card
// ---------------------------------------------------------------------------

/// Minimal view model for the dashboard's quick stats, sourced from
/// `GET /sleep/statistics?range=week`.
class QuickStats {
  const QuickStats({
    required this.avgDurationMin,
    required this.consistencyScore,
    required this.missionSuccessRate,
  });

  const QuickStats.empty()
      : avgDurationMin = 0,
        consistencyScore = 0,
        missionSuccessRate = 0;

  final int avgDurationMin;
  final double consistencyScore; // 0..1
  final double missionSuccessRate; // 0..1
}

/// Override in ProviderScope with the sleep feature's provider when wired.
final quickStatsProvider = Provider<AsyncValue<QuickStats>>(
  (ref) => const AsyncData(QuickStats.empty()),
);

class _QuickStatsCard extends ConsumerWidget {
  const _QuickStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(quickStatsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashThisWeek, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            async.when(
              loading: () => const _CardSkeleton(),
              error: (_, __) => Text(l10n.dashStatsUnavailable,
                  style: theme.textTheme.bodyMedium),
              data: (s) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(
                    label: l10n.dashStatAvgSleep,
                    value: _formatDuration(l10n, s.avgDurationMin),
                    icon: Icons.bedtime_outlined,
                  ),
                  _Stat(
                    label: l10n.dashStatConsistency,
                    value: '${(s.consistencyScore * 100).round()}%',
                    icon: Icons.trending_up,
                  ),
                  _Stat(
                    label: l10n.dashStatMissions,
                    value: '${(s.missionSuccessRate * 100).round()}%',
                    icon: Icons.task_alt,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(AppLocalizations l10n, int minutes) {
    if (minutes <= 0) return '--';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return l10n.dashDurationHm(h, m);
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom nav shortcuts
// ---------------------------------------------------------------------------

class _DashboardNav extends StatelessWidget {
  const _DashboardNav({required this.onOpenAlarms});

  final VoidCallback onOpenAlarms;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.alarm),
            title: Text(l10n.dashNavAlarmsTitle),
            subtitle: Text(l10n.dashNavAlarmsSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenAlarms,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared skeleton placeholder
// ---------------------------------------------------------------------------

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withOpacity(0.08);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [bar(120, 12), bar(180, 20)],
    );
  }
}
