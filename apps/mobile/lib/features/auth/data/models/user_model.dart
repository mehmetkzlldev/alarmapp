import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/user_entity.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Data-layer model for a `User`, matching the JSON returned by `GET /users/me`
/// and embedded in auth responses.
///
/// JSON is camelCase per the API contract. Generated with Freezed + json
/// serialization. Run `flutter pub run build_runner build` to (re)generate
/// `user_model.freezed.dart` and `user_model.g.dart`.
@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String email,
    required String displayName,
    String? timezone,
    String? locale,
    // Some endpoints embed subscription state directly on the user; default to
    // false when absent so the client never over-grants premium.
    @Default(false) bool isPremium,
    DateTime? createdAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  /// Maps this data model to its pure-domain counterpart.
  UserEntity toEntity() => UserEntity(
        id: id,
        email: email,
        displayName: displayName,
        timezone: timezone,
        locale: locale,
        isPremium: isPremium,
        createdAt: createdAt,
      );

  /// Builds a model from a domain entity (e.g. for caching).
  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        email: entity.email,
        displayName: entity.displayName,
        timezone: entity.timezone,
        locale: entity.locale,
        isPremium: entity.isPremium,
        createdAt: entity.createdAt,
      );
}
