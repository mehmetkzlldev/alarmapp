import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/auth_repository.dart';

/// Revokes the refresh token server-side and clears local credentials.
class Logout implements UseCase<Unit, NoParams> {
  const Logout(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) {
    return _repository.logout();
  }
}
