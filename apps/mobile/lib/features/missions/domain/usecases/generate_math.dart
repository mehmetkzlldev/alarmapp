import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/math_problem.dart';
import '../entities/mission_type.dart';
import '../repositories/missions_repository.dart';

/// Generates a math problem for the math mission via
/// `POST /missions/math/generate`.
class GenerateMath implements UseCase<MathProblem, GenerateMathParams> {
  const GenerateMath(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, MathProblem>> call(GenerateMathParams params) {
    return _repository.generateMathProblem(params.difficulty);
  }
}

class GenerateMathParams extends Equatable {
  const GenerateMathParams({required this.difficulty});

  final MissionDifficulty difficulty;

  @override
  List<Object?> get props => [difficulty];
}
