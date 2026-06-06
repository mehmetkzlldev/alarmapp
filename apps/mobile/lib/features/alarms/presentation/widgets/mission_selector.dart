import 'package:flutter/material.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/alarm_mission_entity.dart';

/// Lets the user assemble the ordered list of missions that guard an alarm.
///
/// Supports the three client-renderable mission kinds (math, shake,
/// object_detection) each with a difficulty, plus a target-object picker for
/// object-detection (restricted to the backend-supported targets). The parent
/// owns the list; this widget reports changes via [onChanged].
class MissionSelector extends StatelessWidget {
  const MissionSelector({
    super.key,
    required this.missions,
    required this.onChanged,
  });

  final List<AlarmMissionEntity> missions;
  final ValueChanged<List<AlarmMissionEntity>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.alarmMissionsTitle, style: theme.textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addMission(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.alarmMissionAdd),
            ),
          ],
        ),
        if (missions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.alarmMissionsEmpty,
              style: theme.textTheme.bodySmall,
            ),
          )
        else
          // ReorderableListView so the user can set mission order (orderIndex).
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: missions.length,
            onReorder: _onReorder,
            itemBuilder: (context, index) {
              final m = missions[index];
              return _MissionRow(
                key: ValueKey('mission_$index'),
                index: index,
                mission: m,
                onDifficultyChanged: (d) => _update(index, m.copyWith(difficulty: d)),
                onTargetChanged: (t) => _update(
                  index,
                  m.copyWith(config: {...m.config, 'targetObject': t}),
                ),
                onRemove: () => _remove(index),
              );
            },
          ),
      ],
    );
  }

  Future<void> _addMission(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final kind = await showModalBottomSheet<MissionKind>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.alarmMissionAddSheetTitle)),
            for (final k in MissionKind.values)
              ListTile(
                leading: Icon(_iconFor(k)),
                title: Text(_titleFor(l10n, k)),
                subtitle: Text(_descFor(l10n, k)),
                onTap: () => Navigator.of(ctx).pop(k),
              ),
          ],
        ),
      ),
    );
    if (kind == null) return;

    final next = [...missions];
    next.add(AlarmMissionEntity(
      id: '',
      missionType: kind,
      difficulty: MissionDifficulty.medium,
      orderIndex: next.length,
      // Seed a default target for object-detection so the mission is valid.
      config: kind == MissionKind.objectDetection
          ? {'targetObject': AppConstants.objectDetectionTargets.first}
          : const {},
    ));
    onChanged(_reindexed(next));
  }

  void _update(int index, AlarmMissionEntity mission) {
    final next = [...missions];
    next[index] = mission;
    onChanged(next);
  }

  void _remove(int index) {
    final next = [...missions]..removeAt(index);
    onChanged(_reindexed(next));
  }

  void _onReorder(int oldIndex, int newIndex) {
    final next = [...missions];
    // ReorderableListView's newIndex is post-removal; adjust.
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex, moved);
    onChanged(_reindexed(next));
  }

  /// Rewrites orderIndex to match list position after any structural change.
  List<AlarmMissionEntity> _reindexed(List<AlarmMissionEntity> list) => [
        for (var i = 0; i < list.length; i++) list[i].copyWith(orderIndex: i),
      ];

  static IconData _iconFor(MissionKind k) {
    switch (k) {
      case MissionKind.math:
        return Icons.calculate_outlined;
      case MissionKind.shake:
        return Icons.vibration;
      case MissionKind.objectDetection:
        return Icons.camera_alt_outlined;
    }
  }

  static String _titleFor(AppLocalizations l10n, MissionKind k) {
    switch (k) {
      case MissionKind.math:
        return l10n.alarmMissionMathTitle;
      case MissionKind.shake:
        return l10n.alarmMissionShakeTitle;
      case MissionKind.objectDetection:
        return l10n.alarmMissionPhotoTitle;
    }
  }

  static String _descFor(AppLocalizations l10n, MissionKind k) {
    switch (k) {
      case MissionKind.math:
        return l10n.alarmMissionMathDesc;
      case MissionKind.shake:
        return l10n.alarmMissionShakeDesc;
      case MissionKind.objectDetection:
        return l10n.alarmMissionPhotoDesc;
    }
  }
}

/// One mission row with difficulty selector, optional target picker, drag
/// handle and remove button.
class _MissionRow extends StatelessWidget {
  const _MissionRow({
    super.key,
    required this.index,
    required this.mission,
    required this.onDifficultyChanged,
    required this.onTargetChanged,
    required this.onRemove,
  });

  final int index;
  final AlarmMissionEntity mission;
  final ValueChanged<MissionDifficulty> onDifficultyChanged;
  final ValueChanged<String> onTargetChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isObjectDetection =
        mission.missionType == MissionKind.objectDetection;

    return Card(
      key: ValueKey('mission_card_$index'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
                Icon(MissionSelector._iconFor(
                    mission.missionType ?? MissionKind.math)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    MissionSelector._titleFor(
                        l10n, mission.missionType ?? MissionKind.math),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l10n.alarmMissionRemove,
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Difficulty segmented control.
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<MissionDifficulty>(
                segments: [
                  ButtonSegment(
                    value: MissionDifficulty.easy,
                    label: Text(l10n.missionDifficultyEasy),
                  ),
                  ButtonSegment(
                    value: MissionDifficulty.medium,
                    label: Text(l10n.missionDifficultyMedium),
                  ),
                  ButtonSegment(
                    value: MissionDifficulty.hard,
                    label: Text(l10n.missionDifficultyHard),
                  ),
                ],
                selected: {mission.difficulty},
                onSelectionChanged: (s) => onDifficultyChanged(s.first),
              ),
            ),
            if (isObjectDetection) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: mission.targetObject ??
                    AppConstants.objectDetectionTargets.first,
                decoration: InputDecoration(
                  labelText: l10n.alarmMissionTargetObject,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final t in AppConstants.objectDetectionTargets)
                    DropdownMenuItem(value: t, child: Text(t)),
                ],
                onChanged: (t) {
                  if (t != null) onTargetChanged(t);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
