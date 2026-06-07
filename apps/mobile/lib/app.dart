import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/core/platform/alarm_ring_controller.dart';
import 'package:alarmy/core/router/app_router.dart';
import 'package:alarmy/core/theme/app_theme.dart';
import 'package:alarmy/l10n/app_localizations.dart';

/// Root widget. Uses [MaterialApp.router] driven by the GoRouter from
/// [routerProvider], with Material 3 light/dark themes that follow the system.
class AlarmyApp extends ConsumerWidget {
  const AlarmyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Start listening for native 'alarm_fired' events as soon as the app
    // mounts. This also replays any pending fire that cold-launched the app, so
    // the full-screen ring route appears immediately.
    ref.watch(alarmRingBootstrapProvider);

    return MaterialApp.router(
      title: 'WakeUp AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Force the bright "Mango Sunrise" light theme regardless of the device's
      // dark-mode setting (the app should feel colorful, not dim).
      themeMode: ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
