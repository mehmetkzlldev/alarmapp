import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

/// Creates a new account and starts an authenticated session.
class Register implements UseCase<AuthSessionEntity, RegisterParams> {
  const Register(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSessionEntity>> call(RegisterParams params) {
    return _repository.register(
      email: params.email,
      password: params.password,
      displayName: params.displayName,
    );
  }
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}
