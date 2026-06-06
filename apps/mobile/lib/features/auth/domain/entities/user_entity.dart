import 'package:equatable/equatable.dart';

/// Pure domain representation of an authenticated user.
///
/// This is intentionally framework-agnostic (no JSON, no Freezed) so the domain
/// layer never depends on serialization. The data layer maps `UserModel` ->
/// `UserEntity` at the repository boundary.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.displayName,
    this.timezone,
    this.locale,
    this.isPremium = false,
    this.createdAt,
  });

  /// Server-assigned unique identifier (UUID).
  final String id;

  final String email;
  final String displayName;

  /// IANA timezone, e.g. `Europe/London`. May be null until the user sets it.
  final String? timezone;

  /// BCP-47 locale, e.g. `en-US`.
  final String? locale;

  /// Whether the user currently has an active subscription. Derived from the
  /// `/users/me` payload; treated as a convenience flag for gating UI. The
  /// backend remains the source of truth via PremiumGuard.
  final bool isPremium;

  final DateTime? createdAt;

  /// Returns a copy with selected fields replaced. Used after `PATCH /users/me`
  /// to update local state without a full refetch.
  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    String? timezone,
    String? locale,
    bool? isPremium,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      timezone: timezone ?? this.timezone,
      locale: locale ?? this.locale,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        timezone,
        locale,
        isPremium,
        createdAt,
      ];
}
