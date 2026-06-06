import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/settings_local_datasource.dart';
import '../../data/datasources/settings_remote_datasource.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/update_profile.dart';

// ---- DI graph --------------------------------------------------------------

final settingsRemoteDataSourceProvider =
    Provider<SettingsRemoteDataSource>((ref) {
  return SettingsRemoteDataSourceImpl(ref.watch(dioClientProvider));
});

final settingsLocalDataSourceProvider =
    Provider<SettingsLocalDataSource>((ref) {
  return SettingsLocalDataSourceImpl(ref.watch(secureStorageProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(
    remote: ref.watch(settingsRemoteDataSourceProvider),
    local: ref.watch(settingsLocalDataSourceProvider),
  );
});

final updateProfileUseCaseProvider = Provider<UpdateProfile>((ref) {
  return UpdateProfile(ref.watch(settingsRepositoryProvider));
});

// ---- Settings UI state -----------------------------------------------------

/// Transient UI state for the settings screen: in-flight saves and the most
/// recent error/success message. The durable user comes from
/// [currentUserProvider]; prefs come from [notificationPreferencesProvider].
class SettingsState {
  const SettingsState({
    this.isSavingProfile = false,
    this.errorMessage,
    this.savedMessage,
  });

  final bool isSavingProfile;
  final String? errorMessage;
  final String? savedMessage;

  SettingsState copyWith({
    bool? isSavingProfile,
    String? errorMessage,
    String? savedMessage,
    bool clearMessages = false,
  }) {
    return SettingsState(
      isSavingProfile: isSavingProfile ?? this.isSavingProfile,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      savedMessage: clearMessages ? null : (savedMessage ?? this.savedMessage),
    );
  }
}

/// Controller that orchestrates settings actions: profile updates (and keeping
/// the global auth user in sync), notification toggles, and logout.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController(this._ref) : super(const SettingsState());

  final Ref _ref;

  /// Updates the editable profile fields, then refreshes the global auth user
  /// so the rest of the app sees the change immediately.
  Future<void> updateProfile({
    String? displayName,
    String? timezone,
    String? locale,
  }) async {
    state = state.copyWith(isSavingProfile: true, clearMessages: true);

    final usecase = _ref.read(updateProfileUseCaseProvider);
    final result = await usecase(
      UpdateProfileParams(
        displayName: displayName,
        timezone: timezone,
        locale: locale,
      ),
    );

    await result.fold(
      (failure) async {
        state = state.copyWith(
          isSavingProfile: false,
          errorMessage: failure.message,
        );
      },
      (_) async {
        // Re-fetch /users/me into the canonical auth state.
        await _ref.read(authNotifierProvider.notifier).refreshUser();
        state = state.copyWith(
          isSavingProfile: false,
          savedMessage: 'Profile updated',
        );
      },
    );
  }

  /// Toggles a notification preference and persists it locally.
  Future<void> setNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    // Optimistically update the prefs provider, then persist.
    _ref.read(notificationPreferencesProvider.notifier).set(prefs);
    await _ref
        .read(settingsRepositoryProvider)
        .saveNotificationPreferences(prefs);
  }

  /// Logs the user out via the auth notifier. The router redirect (listening to
  /// auth state) handles navigation back to /login.
  Future<void> logout() async {
    await _ref.read(authNotifierProvider.notifier).logout();
  }

  /// Clears any transient success/error message after it has been shown.
  void clearMessages() => state = state.copyWith(clearMessages: true);
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(ref);
});

// ---- Notification preferences state ---------------------------------------

/// Holds the current notification preferences, loaded from local storage on
/// first read and updated optimistically by the controller.
class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier(this._ref)
      : super(const NotificationPreferences()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final prefs = await _ref
        .read(settingsRepositoryProvider)
        .getNotificationPreferences();
    if (mounted) state = prefs;
  }

  /// Replace the whole preferences object (used by the controller after a
  /// toggle). Persistence is handled by the controller.
  void set(NotificationPreferences prefs) => state = prefs;
}

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, NotificationPreferences>((ref) {
  return NotificationPreferencesNotifier(ref);
});

/// True when the last settings error was a premium gate (e.g. trying to enable
/// a premium-only reminder server-side). Helper mirrored from statistics.
bool isPremiumGate(Object? error) => error is PremiumRequiredFailure;
