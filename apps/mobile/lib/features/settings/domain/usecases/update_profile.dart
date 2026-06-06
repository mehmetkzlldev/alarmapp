import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/settings_repository.dart';

/// Updates the user's editable profile fields via `PATCH /users/me`.
class UpdateProfile implements UseCase<UserEntity, UpdateProfileParams> {
  const UpdateProfile(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(UpdateProfileParams params) {
    return _repository.updateProfile(
      displayName: params.displayName,
      timezone: params.timezone,
      locale: params.locale,
    );
  }
}

class UpdateProfileParams extends Equatable {
  const UpdateProfileParams({this.displayName, this.timezone, this.locale});

  final String? displayName;
  final String? timezone;
  final String? locale;

  @override
  List<Object?> get props => [displayName, timezone, locale];
}
