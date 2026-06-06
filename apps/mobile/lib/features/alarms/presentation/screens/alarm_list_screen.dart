import 'package:dartz/dartz.dart' show Left;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/alarm_entity.dart';
import '../providers/alarms_provider.dart';
import '../widgets/alarm_tile.dart';
import 'alarm_create_screen.dart';

/// The alarms tab: lists alarms, supports toggle + swipe-to-delete, and routes
/// to the create/edit screen.
class AlarmListScreen extends ConsumerWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final alarmsAsync = ref.watch(alarmsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.alarmListTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreate(context),
        icon: const Icon(Icons.add_alarm),
        label: Text(l10n.alarmNewTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alarmsNotifierProvider.notifier).refresh(),
        child: alarmsAsync.when(
          data: (alarms) => _AlarmList(alarms: alarms),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => _ErrorView(
            message: _messageFor(context, err),
            onRetry: () => ref.read(alarmsNotifierProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AlarmCreateScreen()),
    );
  }

  String _messageFor(BuildContext context, Object err) {
    if (err is Failure) return err.message;
    return AppLocalizations.of(context).alarmListLoadError;
  }
}

class _AlarmList extends ConsumerWidget {
  const _AlarmList({required this.alarms});

  final List<AlarmEntity> alarms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alarms.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return ListView(
        // ListView (not Center) so RefreshIndicator still works when empty.
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.alarm_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Center(child: Text(l10n.alarmListEmpty(l10n.alarmNewTitle))),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 96, top: 8),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return Dismissible(
          key: ValueKey('alarm_${alarm.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            color: Theme.of(context).colorScheme.error,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, alarm),
          onDismissed: (_) => _delete(context, ref, alarm.id),
          child: AlarmTile(
            alarm: alarm,
            onToggle: (_) => _toggle(context, ref, alarm.id),
            onTap: () => _openEdit(context, alarm),
            onDelete: () => _confirmAndDelete(context, ref, alarm),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AlarmEntity alarm) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.alarmDeleteTitle),
        content: Text(l10n.alarmDeleteConfirm(alarm.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    AlarmEntity alarm,
  ) async {
    final ok = await _confirmDelete(context, alarm);
    if (ok && context.mounted) await _delete(context, ref, alarm.id);
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref, String id) async {
    final result = await ref.read(alarmsNotifierProvider.notifier).toggle(id);
    result.fold(
      (failure) {
        if (context.mounted) _showError(context, failure);
      },
      (_) {},
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    final result = await ref.read(alarmsNotifierProvider.notifier).delete(id);
    result.fold(
      (failure) {
        if (context.mounted) _showError(context, failure);
      },
      (_) {},
    );
  }

  Future<void> _openEdit(BuildContext context, AlarmEntity alarm) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AlarmCreateScreen(existing: alarm)),
    );
  }

  void _showError(BuildContext context, Object failure) {
    final message = failure is Failure
        ? failure.message
        : AppLocalizations.of(context).alarmActionFailed;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
        const SizedBox(height: 16),
        Center(child: Text(message, textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.commonRetry),
          ),
        ),
      ],
    );
  }
}
