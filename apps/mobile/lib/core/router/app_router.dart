import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:alarmy/core/router/placeholder_pages.dart';
import 'package:alarmy/core/router/route_names.dart';
import 'package:alarmy/features/alarm_ring/presentation/screens/alarm_ring_screen.dart';
import 'package:alarmy/features/alarms/presentation/screens/alarm_create_screen.dart';
import 'package:alarmy/features/alarms/presentation/screens/alarm_list_screen.dart';
import 'package:alarmy/features/auth/presentation/providers/auth_provider.dart';
import 'package:alarmy/features/auth/presentation/screens/login_screen.dart';
import 'package:alarmy/features/auth/presentation/screens/register_screen.dart';
import 'package:alarmy/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:alarmy/features/settings/presentation/screens/settings_screen.dart';
import 'package:alarmy/features/statistics/presentation/screens/statistics_screen.dart';
import 'package:alarmy/features/subscription/presentation/screens/paywall_screen.dart';

/// Bridges the auth feature's Riverpod state into a [Listenable] so GoRouter
/// re-evaluates `redirect` whenever the auth status changes (login / register /
/// logout / startup bootstrap).
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
}

/// The app's [GoRouter]. It reads the auth feature's [authNotifierProvider]
/// directly so a successful login/register (or logout) immediately drives
/// navigation — there is no separate, hand-synced auth-status mirror.
///
/// Redirect policy:
///   - While the persisted session is still being restored (AsyncLoading with
///     no value yet) we don't redirect, so returning users don't flash /login.
///   - Unauthenticated users are forced to /login (except on /login, /register).
///   - Authenticated users on an auth screen are bounced to /dashboard.
///   - The /alarm-ring/* route is always reachable (an alarm can fire while the
///     session is being restored or has expired).
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: refresh,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authAsync = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;
      final isAuthRoute = loc == Routes.login || loc == Routes.register;

      if (loc.startsWith('/alarm-ring/')) return null;

      // Still restoring the persisted session — let the current route render.
      if (authAsync.isLoading && !authAsync.hasValue) return null;

      final isAuthed = ref.read(isAuthenticatedProvider);
      if (!isAuthed && !isAuthRoute) return Routes.login;
      if (isAuthed && isAuthRoute) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        name: Routes.nLogin,
        builder: (context, __) => LoginScreen(
          onNavigateToRegister: () => context.go(Routes.register),
        ),
      ),
      GoRoute(
        path: Routes.register,
        name: Routes.nRegister,
        builder: (context, __) => RegisterScreen(
          onNavigateToLogin: () => context.go(Routes.login),
        ),
      ),
      GoRoute(
        path: Routes.dashboard,
        name: Routes.nDashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: Routes.alarms,
        name: Routes.nAlarms,
        builder: (_, __) => const AlarmListScreen(),
        routes: [
          // /alarms/new — nested so deep links work.
          GoRoute(
            path: 'new',
            name: Routes.nAlarmNew,
            builder: (_, __) => const AlarmCreateScreen(),
          ),
        ],
      ),
      GoRoute(
        // Full-screen alarm ring. Reached when an alarm fires (native ->
        // AlarmRingController). Un-dismissable until missions pass.
        path: Routes.alarmRing,
        name: Routes.nAlarmRing,
        builder: (_, state) {
          final alarmId = state.pathParameters['alarmId'] ?? '';
          return AlarmRingScreen(alarmId: alarmId);
        },
      ),
      GoRoute(
        path: Routes.mission,
        name: Routes.nMission,
        builder: (_, state) {
          final eventId = state.pathParameters['eventId'] ?? '';
          return PlaceholderPage(
            title: 'Mission',
            subtitle: 'Run mission for event $eventId to dismiss the alarm.',
          );
        },
      ),
      GoRoute(
        path: Routes.settings,
        name: Routes.nSettings,
        // Navigation is injected so the screen stays router-agnostic.
        builder: (context, __) => SettingsScreen(
          onManageSubscription: () => context.push(Routes.paywall),
        ),
      ),
      GoRoute(
        path: Routes.statistics,
        name: Routes.nStatistics,
        builder: (context, __) => StatisticsScreen(
          onUpgrade: () => context.push(Routes.paywall),
        ),
      ),
      GoRoute(
        path: Routes.paywall,
        name: Routes.nPaywall,
        builder: (_, __) => const PaywallScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(child: Text('No route for ${state.uri}')),
    ),
  );
});
