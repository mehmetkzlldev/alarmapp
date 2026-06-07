import 'dart:math' as math;

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/refresh.dart';
import '../../domain/usecases/register.dart';
import 'auth_providers.dart';
import 'auth_state.dart';

/// The canonical auth state holder for the app.
///
/// Implemented as an [AsyncNotifier] so the UI can react to loading/error via
/// [AsyncValue] while [AuthState] carries the durable status + user. On
/// construction it performs *token bootstrap*: if a refresh token exists it
/// tries to restore the session, otherwise it resolves to `unauthenticated`.
class AuthNotifier extends AsyncNotifier<AuthState> {
  late final Login _login = ref.read(loginUseCaseProvider);
  late final Register _register = ref.read(registerUseCaseProvider);
  late final Logout _logout = ref.read(logoutUseCaseProvider);
  late final GetCurrentUser _getCurrentUser =
      ref.read(getCurrentUserUseCaseProvider);
  late final Refresh _refresh = ref.read(refreshUseCaseProvider);

  @override
  Future<AuthState> build() async {
    // Bootstrap: decide the initial auth status from persisted credentials.
    return _bootstrap();
  }

  /// Restores a session at startup. Strategy:
  ///  1. If no refresh token is stored -> unauthenticated.
  ///  2. Optimistically use the cached user (instant UI), then validate with
  ///     `GET /users/me`. The Dio interceptor auto-refreshes a stale access
  ///     token on the first 401.
  ///  3. If validation fails irrecoverably -> attempt an explicit refresh; if
  ///     that also fails, fall back to unauthenticated.
  Future<AuthState> _bootstrap() async {
    final repo = ref.read(authRepositoryProvider);

    final hasSession = await repo.hasValidSession();
    if (!hasSession) {
      return const AuthState.unauthenticated();
    }

    // Try to validate against the server (interceptor handles token refresh).
    final result = await _getCurrentUser(const NoParams());

    // Happy path: user loaded directly.
    final user = result.fold<UserEntity?>((_) => null, (u) => u);
    if (user != null) {
      return AuthState.authenticated(user);
    }

    // One explicit refresh attempt for the edge case where the interceptor
    // could not recover (e.g. it bypassed because no access token existed).
    final refreshed = await _refresh(const NoParams());
    final didRefresh = refreshed.isRight();
    if (!didRefresh) {
      return const AuthState.unauthenticated();
    }

    final retry = await _getCurrentUser(const NoParams());
    return retry.fold(
      (_) => const AuthState.unauthenticated(),
      (u) => AuthState.authenticated(u),
    );
  }

  /// Logs in and transitions to `authenticated` on success.
  Future<void> login({required String email, required String password}) async {
    await _run(() => _login(LoginParams(email: email, password: password)));
  }

  /// Registers and transitions to `authenticated` on success.
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _run(
      () => _register(
        RegisterParams(
          email: email,
          password: password,
          displayName: displayName,
        ),
      ),
    );
  }

  /// Dedup guard for the silent anonymous-session bootstrap.
  Future<void>? _anonInFlight;

  /// Provisions (or reuses) a silent anonymous session so the app works with no
  /// visible login. Idempotent + deduped across concurrent calls — safe to call
  /// early (kicked off during onboarding) and again on finish.
  Future<void> ensureAnonymousSession({String? displayName}) {
    if (state.valueOrNull?.isAuthenticated ?? false) {
      return Future<void>.value();
    }
    return _anonInFlight ??=
        _createAnonymous(displayName).whenComplete(() => _anonInFlight = null);
  }

  Future<void> _createAnonymous(String? displayName) async {
    final seed = DateTime.now().microsecondsSinceEpoch;
    final rnd = math.Random(seed);
    final tag = List<int>.generate(20, (_) => rnd.nextInt(16))
        .map((n) => n.toRadixString(16))
        .join();
    final email = 'anon-$seed-$tag@alarmapp.app';
    // Always satisfies common complexity rules (upper, lower, digit, symbol).
    final password = 'Aa1!$tag';
    final name = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : 'Misafir';
    await register(email: email, password: password, displayName: name);
  }

  /// Logs out, clears local state, and transitions to `unauthenticated`.
  Future<void> logout() async {
    state = const AsyncValue<AuthState>.loading();
    final result = await _logout(const NoParams());
    state = result.fold(
      (failure) =>
          AsyncValue<AuthState>.data(const AuthState.unauthenticated()),
      // Even on failure we end up unauthenticated locally (tokens cleared).
      (_) => const AsyncValue<AuthState>.data(AuthState.unauthenticated()),
    );
  }

  /// Re-fetches the current user (e.g. after a profile edit elsewhere).
  Future<void> refreshUser() async {
    final result = await _getCurrentUser(const NoParams());
    result.fold(
      (failure) {
        // Keep current state; surface error transiently without dropping data.
        final current = state.valueOrNull ?? const AuthState.unknown();
        state = AsyncValue<AuthState>.error(failure, StackTrace.current)
            .copyWithPrevious(AsyncValue.data(current));
      },
      (user) => state = AsyncValue.data(AuthState.authenticated(user)),
    );
  }

  /// Shared driver for login/register: sets loading, maps the `Either` result
  /// to either an authenticated data state or an error state.
  Future<void> _run(
    Future<Either<Failure, AuthSessionEntity>> Function() action,
  ) async {
    state = const AsyncValue<AuthState>.loading();
    final Either<Failure, AuthSessionEntity> result = await action();
    state = result.fold(
      (failure) => AsyncValue<AuthState>.error(failure, StackTrace.current),
      (session) =>
          AsyncValue<AuthState>.data(AuthState.authenticated(session.user)),
    );
  }
}

/// The single source of truth for auth, consumed by screens and the router.
final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience selector: the current user, or null. Rebuilds only when the
/// user changes.
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authNotifierProvider).valueOrNull?.user;
});

/// Convenience selector: whether the user is authenticated. Useful for routing
/// guards without unpacking the full [AsyncValue].
final isAuthenticatedProvider = Provider<bool>((ref) {
  final state = ref.watch(authNotifierProvider).valueOrNull;
  return state?.isAuthenticated ?? false;
});
