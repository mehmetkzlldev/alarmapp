/// Canonical route paths and names. Using constants avoids stringly-typed
/// navigation typos and keeps `go`/`goNamed` call sites refactor-safe.
class Routes {
  Routes._();

  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String alarms = '/alarms';
  static const String alarmNew = '/alarms/new';

  /// Full-screen, un-dismissable alarm-ring route shown when an alarm fires.
  /// `:alarmId` is the server alarm id forwarded by the native ring trigger.
  /// This is the route the native AlarmActivity / iOS notification routes to.
  static const String alarmRing = '/alarm-ring/:alarmId';
  static String alarmRingFor(String alarmId) => '/alarm-ring/$alarmId';

  /// Mission run screen for a fired alarm event. `:eventId` is the local alarm
  /// event id passed by the native ring trigger.
  static const String mission = '/mission/:eventId';
  static String missionFor(String eventId) => '/mission/$eventId';

  static const String settings = '/settings';
  static const String statistics = '/statistics';
  static const String paywall = '/paywall';

  // Named routes (mirror the paths).
  static const String nOnboarding = 'onboarding';
  static const String nLogin = 'login';
  static const String nRegister = 'register';
  static const String nDashboard = 'dashboard';
  static const String nAlarms = 'alarms';
  static const String nAlarmNew = 'alarmNew';
  static const String nAlarmRing = 'alarmRing';
  static const String nMission = 'mission';
  static const String nSettings = 'settings';
  static const String nStatistics = 'statistics';
  static const String nPaywall = 'paywall';
}
