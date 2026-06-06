import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alarmy/core/di/injection.dart';
import 'package:alarmy/core/storage/token_store.dart';

/// Coarse authentication status the router redirect depends on.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Holds the app's auth status and exposes mutations the auth feature calls on
/// login/logout. Kept in `core` (not the auth feature) so the router can listen
/// without importing feature code, avoiding a layering cycle.
///
/// On construction it eagerly checks secure storage for an existing session so
/// returning users skip the login screen.
class AuthStateNotifier extends StateNotifier<AuthStatus> {
  AuthStateNotifier(this._tokenStore) : super(AuthStatus.unknown) {
    _bootstrap();
  }

  final TokenStore _tokenStore;

  Future<void> _bootstrap() async {
    final hasSession = await _tokenStore.hasSession();
    state = hasSession ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  /// Called by the auth feature after a successful login/register (tokens are
  /// already persisted by the repository).
  void markAuthenticated() => state = AuthStatus.authenticated;

  /// Called after logout (or when refresh fails irrecoverably).
  Future<void> markUnauthenticated() async {
    await _tokenStore.clear();
    state = AuthStatus.unauthenticated;
  }
}

/// Global provider the router watches. The concrete [TokenStore] comes from the
/// injectable get_it container (see core/di).
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthStatus>((ref) {
  return AuthStateNotifier(getIt<TokenStore>());
});
