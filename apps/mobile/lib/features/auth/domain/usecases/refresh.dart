import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_tokens_entity.dart';
import '../repositories/auth_repository.dart';

/// Exchanges the stored refresh token for a fresh, rotated token pair.
///
/// Primarily invoked by the auth interceptor on a 401, and at app bootstrap to
/// restore a session. Returns the new tokens on success.
class Refresh implements UseCase<AuthTokensEntity, NoParams> {
  const Refresh(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthTokensEntity>> call(NoParams params) {
    return _repository.refreshSession();
  }
}
