import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ai_mission.dart';
import '../repositories/missions_repository.dart';

/// Fetches today's AI-generated mission via `GET /ai-missions/today`.
///
/// PREMIUM-GATED: the repository surfaces a [PremiumRequiredFailure] for free
/// users, which the presentation layer turns into a paywall upsell.
class GetTodayAiMission implements UseCase<AiMission, NoParams> {
  const GetTodayAiMission(this._repository);

  final MissionsRepository _repository;

  @override
  Future<Either<Failure, AiMission>> call(NoParams params) {
    return _repository.getTodayAiMission();
  }
}
