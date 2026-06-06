import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/l10n/app_localizations.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../domain/entities/notification_preferences.dart';
import '../providers/settings_provider.dart';

/// Account & app settings screen.
///
/// Sections:
///  * Profile — display name (editable), email (read-only), timezone.
///  * Notifications — local toggles for alarm/mission/announcement pushes.
///  * Subscription — status + "Manage" link routed to the paywall.
///  * Account — logout.
///
/// Navigation is injected via callbacks so the screen stays router-agnostic:
///  * [onManageSubscription] -> `context.go('/paywall')`.
///  * [onLoggedOut] is optional; the auth state change usually drives the
///    router redirect on its own.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({
    super.key,
    this.onManageSubscription,
    this.onLoggedOut,
  });

  final VoidCallback? onManageSubscription;
  final VoidCallback? onLoggedOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsControllerProvider);
    final prefs = ref.watch(notificationPreferencesProvider);

    // Surface transient success/error messages as snackbars.
    ref.listen<SettingsState>(settingsControllerProvider, (prev, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next.savedMessage != null && next.savedMessage != prev?.savedMessage) {
        messenger.showSnackBar(SnackBar(content: Text(next.savedMessage!)));
        ref.read(settingsControllerProvider.notifier).clearMessages();
      } else if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        messenger.showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
        ref.read(settingsControllerProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _ProfileSection(
                  user: user,
                  isSaving: settings.isSavingProfile,
                ),
                const Divider(height: 1),
                _NotificationsSection(prefs: prefs),
                const Divider(height: 1),
                _SubscriptionSection(
                  onManage: onManageSubscription,
                ),
                const Divider(height: 1),
                _AccountSection(onLoggedOut: onLoggedOut),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}

// ---- Profile ---------------------------------------------------------------

class _ProfileSection extends ConsumerWidget {
  const _ProfileSection({required this.user, required this.isSaving});

  final UserEntity user;
  final bool isSaving;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _SectionHeader(l10n.settingsProfile),
        ListTile(
          leading: const Icon(Icons.person),
          title: Text(l10n.settingsDisplayName),
          subtitle: Text(user.displayName),
          trailing: isSaving
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.edit),
          onTap: isSaving
              ? null
              : () => _editDisplayName(context, ref, user.displayName),
        ),
        ListTile(
          leading: const Icon(Icons.email),
          title: Text(l10n.settingsEmail),
          subtitle: Text(user.email),
          // Email is not editable via the settings contract.
          enabled: false,
        ),
        ListTile(
          leading: const Icon(Icons.public),
          title: Text(l10n.settingsTimezone),
          subtitle: Text(user.timezone ?? l10n.settingsTimezoneNotSet),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _editTimezone(context, ref, user.timezone),
        ),
      ],
    );
  }

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsDisplayName),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: InputDecoration(hintText: l10n.settingsDisplayNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.settingsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.settingsSave),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && result != current) {
      await ref
          .read(settingsControllerProvider.notifier)
          .updateProfile(displayName: result);
    }
  }

  Future<void> _editTimezone(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => _TimezonePicker(current: current),
    );
    if (selected != null && selected != current) {
      await ref
          .read(settingsControllerProvider.notifier)
          .updateProfile(timezone: selected);
    }
  }
}

/// A pragmatic, curated timezone list. (A full tz database picker can replace
/// this; the contract only needs the IANA id string for `PATCH /users/me`.)
class _TimezonePicker extends StatelessWidget {
  const _TimezonePicker({this.current});

  final String? current;

  static const List<String> _commonZones = [
    'UTC',
    'America/Los_Angeles',
    'America/Denver',
    'America/Chicago',
    'America/New_York',
    'America/Sao_Paulo',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Moscow',
    'Asia/Dubai',
    'Asia/Kolkata',
    'Asia/Singapore',
    'Asia/Shanghai',
    'Asia/Tokyo',
    'Australia/Sydney',
    'Pacific/Auckland',
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.settingsSelectTimezone,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final zone in _commonZones)
            RadioListTile<String>(
              title: Text(zone),
              value: zone,
              groupValue: current,
              onChanged: (v) => Navigator.pop(context, v),
            ),
        ],
      ),
    );
  }
}

// ---- Notifications ---------------------------------------------------------

class _NotificationsSection extends ConsumerWidget {
  const _NotificationsSection({required this.prefs});

  final NotificationPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(settingsControllerProvider.notifier);
    return Column(
      children: [
        _SectionHeader(l10n.settingsNotifications),
        SwitchListTile(
          secondary: const Icon(Icons.alarm),
          title: Text(l10n.settingsAlarmNotifications),
          subtitle: Text(l10n.settingsAlarmNotificationsSubtitle),
          value: prefs.alarmNotifications,
          onChanged: (v) => controller.setNotificationPreferences(
            prefs.copyWith(alarmNotifications: v),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome),
          title: Text(l10n.settingsDailyMissionReminders),
          subtitle: Text(l10n.settingsDailyMissionRemindersSubtitle),
          value: prefs.dailyMissionReminders,
          onChanged: (v) => controller.setNotificationPreferences(
            prefs.copyWith(dailyMissionReminders: v),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.campaign),
          title: Text(l10n.settingsProductAnnouncements),
          subtitle: Text(l10n.settingsProductAnnouncementsSubtitle),
          value: prefs.productAnnouncements,
          onChanged: (v) => controller.setNotificationPreferences(
            prefs.copyWith(productAnnouncements: v),
          ),
        ),
      ],
    );
  }
}

// ---- Subscription ----------------------------------------------------------

class _SubscriptionSection extends ConsumerWidget {
  const _SubscriptionSection({this.onManage});

  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Use the canonical, server-backed premium flag from the subscription
    // feature rather than the convenience flag embedded on the user.
    final isPremium = ref.watch(isPremiumProvider);
    return Column(
      children: [
        _SectionHeader(l10n.settingsSubscription),
        ListTile(
          leading: Icon(
            isPremium ? Icons.workspace_premium : Icons.star_border,
            color: isPremium ? theme.colorScheme.primary : null,
          ),
          title: Text(isPremium ? l10n.settingsPremium : l10n.settingsFreePlan),
          subtitle: Text(
            isPremium
                ? l10n.settingsPremiumSubtitle
                : l10n.settingsFreePlanSubtitle,
          ),
          trailing: FilledButton.tonal(
            onPressed: onManage,
            child: Text(isPremium ? l10n.settingsManage : l10n.settingsUpgrade),
          ),
          onTap: onManage,
        ),
      ],
    );
  }
}

// ---- Account ---------------------------------------------------------------

class _AccountSection extends ConsumerWidget {
  const _AccountSection({this.onLoggedOut});

  final VoidCallback? onLoggedOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _SectionHeader(l10n.settingsAccount),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text(l10n.settingsLogOut,
              style: const TextStyle(color: Colors.red)),
          onTap: () => _confirmLogout(context, ref),
        ),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsLogOutConfirmTitle),
        content: Text(l10n.settingsLogOutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.settingsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsLogOut),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(settingsControllerProvider.notifier).logout();
      onLoggedOut?.call();
    }
  }
}

// ---- Shared ----------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 1.1,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
