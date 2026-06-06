import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session_entity.dart';
import '../repositories/auth_repository.dart';

/// Authenticates an existing user with email + password.
class Login implements UseCase<AuthSessionEntity, LoginParams> {
  const Login(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, AuthSessionEntity>> call(LoginParams params) {
    return _repository.login(
      email: params.email,
      password: params.password,
    );
  }
}

class LoginParams extends Equatable {
  const LoginParams({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}
