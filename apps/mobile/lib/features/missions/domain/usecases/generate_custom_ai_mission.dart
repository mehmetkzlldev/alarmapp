import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ai_mission.dart';
import '../repositories/missions_repository.dart';

/// Premium "AI mission designer": generate a custom wake-up mission from the
/// user's free-text description via the backend (Gemini).
class GenerateCustomAiMission
    implements UseCase<AiMission, GenerateCustomParams> {
  const GenerateCustomAiMission(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, AiMission>> call(GenerateCustomParams params) =>
      _repository.generateCustomAiMission(
        prompt: params.prompt,
        difficulty: params.difficulty,
      );
}

class GenerateCustomParams {
  const GenerateCustomParams({required this.prompt, this.difficulty});

  final String prompt;

  /// 'easy' | 'medium' | 'hard' wire value, or null to let the AI choose.
  final String? difficulty;
}
