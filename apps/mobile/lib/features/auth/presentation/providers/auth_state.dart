import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

/// High-level authentication status, derived at bootstrap and after each
/// auth action. The router listens to this to gate protected routes.
enum AuthStatus {
  /// We have not yet determined whether a session exists (initial bootstrap).
  unknown,

  /// A valid session is present and the user is loaded.
  authenticated,

  /// No session (logged out, or bootstrap found no/invalid tokens).
  unauthenticated,
}

/// Immutable auth state held by the [AuthNotifier].
///
/// Wrapped in an [AsyncValue] by the notifier so transient loading/error states
/// (e.g. an in-flight login) are represented without losing the last known
/// [status]/[user].
class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
  });

  final AuthStatus status;

  /// The authenticated user, or null when unauthenticated/unknown.
  final UserEntity? user;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  const AuthState.unknown() : this(status: AuthStatus.unknown, user: null);

  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated, user: null);

  AuthState.authenticated(UserEntity user)
      : this(status: AuthStatus.authenticated, user: user);

  AuthState copyWith({AuthStatus? status, UserEntity? user}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, user];
}
