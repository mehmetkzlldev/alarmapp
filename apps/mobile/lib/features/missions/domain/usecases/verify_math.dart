import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/missions_repository.dart';

/// Verifies a user's answer to a generated math problem via
/// `POST /missions/math/verify`. Returns whether the answer was correct.
class VerifyMath implements UseCase<bool, VerifyMathParams> {
  const VerifyMath(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, bool>> call(VerifyMathParams params) {
    return _repository.verifyMathAnswer(
      problemId: params.problemId,
      answer: params.answer,
    );
  }
}

class VerifyMathParams extends Equatable {
  const VerifyMathParams({required this.problemId, required this.answer});

  final String problemId;
  final int answer;

  @override
  List<Object?> get props => [problemId, answer];
}
