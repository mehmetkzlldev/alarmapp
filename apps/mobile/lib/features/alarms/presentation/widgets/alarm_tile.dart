import 'package:flutter/material.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/alarm_mission_entity.dart';

/// A single row in the alarm list: time, label, repeat days, mission badges and
/// an active toggle. Swiping (handled by the parent `Dismissible`) deletes.
class AlarmTile extends StatelessWidget {
  const AlarmTile({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  final AlarmEntity alarm;

  /// Called with the desired new active value when the switch is flipped.
  final ValueChanged<bool> onToggle;

  /// Opens the edit screen.
  final VoidCallback onTap;

  /// Deletes this alarm (the parent shows a confirmation dialog first).
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hm = alarm.hourMinute;
    final inactiveColor = theme.disabledColor;

    return Opacity(
      // Dim inactive alarms so the active set is visually obvious.
      opacity: alarm.isActive ? 1.0 : 0.55,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(hm.hour, hm.minute, context),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: alarm.isActive ? null : inactiveColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        alarm.label.isEmpty ? l10n.alarmDefaultLabel : alarm.label,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      _RepeatRow(repeatDays: alarm.repeatDays),
                      if (alarm.missions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _MissionBadges(missions: alarm.missions),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Switch.adaptive(
                      value: alarm.isActive,
                      onChanged: onToggle,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: theme.colorScheme.error),
                      tooltip: l10n.commonDelete,
                      visualDensity: VisualDensity.compact,
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute, BuildContext context) {
    final use24h = MediaQuery.of(context).alwaysUse24HourFormat;
    final mm = minute.toString().padLeft(2, '0');
    if (use24h) return '${hour.toString().padLeft(2, '0')}:$mm';
    final l10n = AppLocalizations.of(context);
    final period = hour < 12 ? l10n.timeAm : l10n.timePm;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$mm $period';
  }
}

/// Renders the weekday repeat indicator (or "Once" / "Every day").
class _RepeatRow extends StatelessWidget {
  const _RepeatRow({required this.repeatDays});

  final List<int> repeatDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    if (repeatDays.isEmpty) {
      return Text(l10n.alarmRepeatOnce, style: theme.textTheme.labelMedium);
    }
    if (repeatDays.length == 7) {
      return Text(l10n.alarmRepeatEveryDay, style: theme.textTheme.labelMedium);
    }

    final dayLabels = _dayLetters(l10n);
    final set = repeatDays.toSet();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(7, (i) {
        final on = set.contains(i);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            dayLabels[i],
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: on ? FontWeight.bold : FontWeight.normal,
              color: on ? theme.colorScheme.primary : theme.disabledColor,
            ),
          ),
        );
      }),
    );
  }

  // 0=Sun..6=Sat single-letter weekday labels, localized.
  List<String> _dayLetters(AppLocalizations l10n) => [
        l10n.dayLetterSun,
        l10n.dayLetterMon,
        l10n.dayLetterTue,
        l10n.dayLetterWed,
        l10n.dayLetterThu,
        l10n.dayLetterFri,
        l10n.dayLetterSat,
      ];
}

/// Small chips summarizing the missions guarding this alarm.
class _MissionBadges extends StatelessWidget {
  const _MissionBadges({required this.missions});

  final List<AlarmMissionEntity> missions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final m in missions)
          Chip(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            avatar: Icon(_iconFor(m.missionType), size: 16),
            label: Text(
              _labelFor(l10n, m),
              style: theme.textTheme.labelSmall,
            ),
          ),
      ],
    );
  }

  IconData _iconFor(MissionKind? kind) {
    switch (kind) {
      case MissionKind.math:
        return Icons.calculate_outlined;
      case MissionKind.shake:
        return Icons.vibration;
      case MissionKind.objectDetection:
        return Icons.camera_alt_outlined;
      case null:
        return Icons.help_outline;
    }
  }

  String _labelFor(AppLocalizations l10n, AlarmMissionEntity m) {
    final diff = _difficultyLabel(l10n, m.difficulty);
    switch (m.missionType) {
      case MissionKind.math:
        return l10n.alarmBadgeMath(diff);
      case MissionKind.shake:
        return l10n.alarmBadgeShake(diff);
      case MissionKind.objectDetection:
        final target = m.targetObject;
        return target == null
            ? l10n.alarmBadgePhoto(diff)
            : l10n.alarmBadgePhotoTarget(target);
      case null:
        return l10n.alarmBadgeUnknown;
    }
  }

  String _difficultyLabel(AppLocalizations l10n, MissionDifficulty difficulty) {
    switch (difficulty) {
      case MissionDifficulty.easy:
        return l10n.missionDifficultyEasy;
      case MissionDifficulty.medium:
        return l10n.missionDifficultyMedium;
      case MissionDifficulty.hard:
        return l10n.missionDifficultyHard;
    }
  }
}
