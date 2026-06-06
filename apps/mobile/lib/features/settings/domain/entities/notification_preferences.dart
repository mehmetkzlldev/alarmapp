import 'package:equatable/equatable.dart';

/// Local-only notification preferences.
///
/// These are device-side UX toggles (not server state): whether to show alarm
/// notifications, daily mission reminders, and marketing/announcement pushes.
/// Persisted locally; the FCM token registration itself is handled by the
/// devices/notifications layer.
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    this.alarmNotifications = true,
    this.dailyMissionReminders = true,
    this.productAnnouncements = false,
  });

  /// Master toggle for alarm-related notifications.
  final bool alarmNotifications;

  /// Daily "your AI mission is ready" reminder (premium feature).
  final bool dailyMissionReminders;

  /// Non-essential product/marketing announcements. Off by default (opt-in).
  final bool productAnnouncements;

  NotificationPreferences copyWith({
    bool? alarmNotifications,
    bool? dailyMissionReminders,
    bool? productAnnouncements,
  }) {
    return NotificationPreferences(
      alarmNotifications: alarmNotifications ?? this.alarmNotifications,
      dailyMissionReminders:
          dailyMissionReminders ?? this.dailyMissionReminders,
      productAnnouncements: productAnnouncements ?? this.productAnnouncements,
    );
  }

  Map<String, dynamic> toJson() => {
        'alarmNotifications': alarmNotifications,
        'dailyMissionReminders': dailyMissionReminders,
        'productAnnouncements': productAnnouncements,
      };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      alarmNotifications: json['alarmNotifications'] as bool? ?? true,
      dailyMissionReminders: json['dailyMissionReminders'] as bool? ?? true,
      productAnnouncements: json['productAnnouncements'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [alarmNotifications, dailyMissionReminders, productAnnouncements];
}
