import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/permissions/alarm_permissions.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/entities/alarm_mission_entity.dart';
import '../../domain/usecases/create_alarm.dart';
import '../../domain/usecases/update_alarm.dart';
import '../providers/alarms_provider.dart';
import '../widgets/mission_selector.dart';

/// Create or edit an alarm.
///
/// When [existing] is null we create; otherwise we edit. On save the repository
/// persists to the API, updates the offline cache, AND registers the alarm with
/// the native scheduler — so no extra scheduler call is needed here.
class AlarmCreateScreen extends ConsumerStatefulWidget {
  const AlarmCreateScreen({super.key, this.existing});

  final AlarmEntity? existing;

  @override
  ConsumerState<AlarmCreateScreen> createState() => _AlarmCreateScreenState();
}

class _AlarmCreateScreenState extends ConsumerState<AlarmCreateScreen> {
  late TimeOfDay _time;
  late TextEditingController _labelController;
  late Set<int> _repeatDays; // 0=Sun..6=Sat
  late bool _isActive;
  late String _sound;
  late bool _vibration;
  late double _volume;
  late bool _snoozeEnabled;
  late int _snoozeIntervalMin;
  late int _snoozeLimit;
  late List<AlarmMissionEntity> _missions;

  bool _saving = false;

  /// Built-in sound options (must match assets/sounds/ filenames; "default" is
  /// the bundled fallback tone).
  static const _soundOptions = <String>[
    'default',
    'gentle_chimes',
    'morning_birds',
    'classic_bell',
    'rooster',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      final hm = e.hourMinute;
      _time = TimeOfDay(hour: hm.hour, minute: hm.minute);
      _labelController = TextEditingController(text: e.label);
      _repeatDays = e.repeatDays.toSet();
      _isActive = e.isActive;
      _sound = e.sound;
      _vibration = e.vibration;
      _volume = e.volume;
      _snoozeEnabled = e.snoozeEnabled;
      _snoozeIntervalMin = e.snoozeIntervalMin;
      _snoozeLimit = e.snoozeLimit;
      _missions = List.of(e.missions);
    } else {
      final now = TimeOfDay.now();
      _time = now;
      // Localized default ("Alarm") is applied in didChangeDependencies, where
      // the AppLocalizations inherited widget is available.
      _labelController = TextEditingController();
      _repeatDays = <int>{};
      _isActive = true;
      _sound = 'default';
      _vibration = true;
      _volume = 1.0;
      _snoozeEnabled = false; // No snooze by default — you must do the missions.
      _snoozeIntervalMin = 5;
      _snoozeLimit = 3;
      // New alarms default to the classic 3-step wake-up chain so every alarm is
      // a real challenge: shake 10s -> math -> snap any object. The user can
      // still edit/remove these in the mission selector below.
      _missions = <AlarmMissionEntity>[
        const AlarmMissionEntity(
          id: '',
          missionType: MissionKind.shake,
          difficulty: MissionDifficulty.medium,
          orderIndex: 0,
          config: {'shakeSeconds': 10},
        ),
        const AlarmMissionEntity(
          id: '',
          missionType: MissionKind.math,
          difficulty: MissionDifficulty.medium,
          orderIndex: 1,
        ),
        const AlarmMissionEntity(
          id: '',
          missionType: MissionKind.objectDetection,
          difficulty: MissionDifficulty.medium,
          orderIndex: 2,
          config: {'targetObject': 'any'},
        ),
      ];
    }
  }

  bool _defaultLabelApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed the localized default label for new alarms once dependencies (and
    // thus AppLocalizations) are available. Editing keeps the existing label.
    if (!_isEditing && !_defaultLabelApplied) {
      _defaultLabelApplied = true;
      if (_labelController.text.isEmpty) {
        _labelController.text = AppLocalizations.of(context).alarmDefaultLabel;
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.alarmEditTitle : l10n.alarmNewTitle),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.commonSave),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TimePickerCard(time: _time, onPick: _pickTime),
          const SizedBox(height: 16),
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: l10n.alarmLabelField,
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.alarmRepeatLabel),
          _RepeatDaysSelector(
            selected: _repeatDays,
            onChanged: (days) => setState(() => _repeatDays = days),
          ),
          const SizedBox(height: 24),
          _SectionLabel(l10n.alarmSoundHapticsLabel),
          _SoundDropdown(
            value: _sound,
            options: _soundOptions,
            onChanged: (v) => setState(() => _sound = v),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.volume_up),
              Expanded(
                child: Slider(
                  value: _volume,
                  onChanged: (v) => setState(() => _volume = v),
                  label: '${(_volume * 100).round()}%',
                  divisions: 20,
                ),
              ),
            ],
          ),
          SwitchListTile(
            title: Text(l10n.alarmVibration),
            value: _vibration,
            onChanged: (v) => setState(() => _vibration = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          _SectionLabel(l10n.alarmSnoozeLabel),
          SwitchListTile(
            title: Text(l10n.alarmAllowSnooze),
            value: _snoozeEnabled,
            onChanged: (v) => setState(() => _snoozeEnabled = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_snoozeEnabled) ...[
            _SnoozeStepper(
              label: l10n.alarmSnoozeInterval,
              value: _snoozeIntervalMin,
              suffix: l10n.alarmSnoozeIntervalSuffix,
              min: 1,
              max: 30,
              onChanged: (v) => setState(() => _snoozeIntervalMin = v),
            ),
            _SnoozeStepper(
              label: l10n.alarmMaxSnoozes,
              value: _snoozeLimit,
              suffix: l10n.alarmMaxSnoozesSuffix,
              min: 1,
              max: 10,
              onChanged: (v) => setState(() => _snoozeLimit = v),
            ),
          ],
          const SizedBox(height: 24),
          MissionSelector(
            missions: _missions,
            onChanged: (m) => setState(() => _missions = m),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(l10n.alarmActive),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  /// Builds the entity from the form. `time` is the 24h "HH:mm" string the
  /// backend and native scheduler expect.
  AlarmEntity _buildEntity() {
    final hh = _time.hour.toString().padLeft(2, '0');
    final mm = _time.minute.toString().padLeft(2, '0');
    final repeat = _repeatDays.toList()..sort();
    return AlarmEntity(
      id: widget.existing?.id ?? '',
      label: _labelController.text.trim().isEmpty
          ? AppLocalizations.of(context).alarmDefaultLabel
          : _labelController.text.trim(),
      time: '$hh:$mm',
      repeatDays: repeat,
      isActive: _isActive,
      sound: _sound,
      vibration: _vibration,
      volume: _volume,
      snoozeEnabled: _snoozeEnabled,
      snoozeIntervalMin: _snoozeIntervalMin,
      snoozeLimit: _snoozeLimit,
      missions: _missions,
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final entity = _buildEntity();

    // create/update use cases both persist to the repo, which in turn writes
    // the cache and calls the native AlarmScheduler bridge.
    final Either<Failure, AlarmEntity> result = _isEditing
        ? await ref
            .read(updateAlarmUseCaseProvider)
            .call(UpdateAlarmParams(alarm: entity))
        : await ref
            .read(createAlarmUseCaseProvider)
            .call(CreateAlarmParams(alarm: entity));

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) => _onSaveFailure(failure),
      (saved) {
        // Make sure the OS will actually let this alarm fire + ring.
        unawaited(ensureAlarmPermissions());
        // Keep the list in sync immediately.
        final notifier = ref.read(alarmsNotifierProvider.notifier);
        if (_isEditing) {
          notifier.refresh();
        } else {
          notifier.addCreated(saved);
        }
        Navigator.of(context).pop(saved);
      },
    );
  }

  void _onSaveFailure(Failure failure) {
    if (failure is PremiumRequiredFailure) {
      _showPaywall(failure.message);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failure.message)));
  }

  void _showPaywall(String message) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.alarmUpgradeTitle),
        content: Text(l10n.alarmUpgradeBody(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.alarmUpgradeNotNow),
          ),
          FilledButton(
            onPressed: () {
              // The subscriptions feature owns the actual purchase flow; here we
              // just close and let the user navigate there.
              Navigator.of(ctx).pop();
            },
            child: Text(l10n.alarmUpgradeSeePlans),
          ),
        ],
      ),
    );
  }
}

// --- Small presentational helpers ------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _TimePickerCard extends StatelessWidget {
  const _TimePickerCard({required this.time, required this.onPick});

  final TimeOfDay time;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              time.format(context),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RepeatDaysSelector extends StatelessWidget {
  const _RepeatDaysSelector({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  // 0=Sun .. 6=Sat, matching the API contract's repeatDays numbering.
  static List<String> _labels(AppLocalizations l10n) => [
        l10n.dayShortSun,
        l10n.dayShortMon,
        l10n.dayShortTue,
        l10n.dayShortWed,
        l10n.dayShortThu,
        l10n.dayShortFri,
        l10n.dayShortSat,
      ];

  @override
  Widget build(BuildContext context) {
    final labels = _labels(AppLocalizations.of(context));
    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final on = selected.contains(i);
        return FilterChip(
          label: Text(labels[i]),
          selected: on,
          onSelected: (sel) {
            final next = {...selected};
            if (sel) {
              next.add(i);
            } else {
              next.remove(i);
            }
            onChanged(next);
          },
        );
      }),
    );
  }
}

class _SoundDropdown extends StatelessWidget {
  const _SoundDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: l10n.alarmSoundField,
        prefixIcon: const Icon(Icons.music_note),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      items: [
        for (final s in options)
          DropdownMenuItem(value: s, child: Text(_soundName(l10n, s))),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  String _soundName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'default':
        return l10n.alarmSoundDefault;
      case 'gentle_chimes':
        return l10n.alarmSoundGentleChimes;
      case 'morning_birds':
        return l10n.alarmSoundMorningBirds;
      case 'classic_bell':
        return l10n.alarmSoundClassicBell;
      case 'rooster':
        return l10n.alarmSoundRooster;
      default:
        return key
            .split('_')
            .map((w) =>
                w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }
}

class _SnoozeStepper extends StatelessWidget {
  const _SnoozeStepper({
    required this.label,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String suffix;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 56,
            child: Text(
              '$value $suffix',
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}
