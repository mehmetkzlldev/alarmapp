import 'package:dartz/dartz.dart';

import 'package:alarmy/core/error/failures.dart';
import 'package:alarmy/core/usecase/usecase.dart';
import 'package:alarmy/features/subscription/domain/entities/plan_entity.dart';
import 'package:alarmy/features/subscription/domain/repositories/subscription_repository.dart';

/// Lists the plans shown on the paywall (free + premium tiers) with live,
/// localized store pricing merged in.
class GetPlans implements UseCase<List<PlanEntity>, NoParams> {
  const GetPlans(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, List<PlanEntity>>> call(NoParams params) {
    return _repository.getPlans();
  }
}
