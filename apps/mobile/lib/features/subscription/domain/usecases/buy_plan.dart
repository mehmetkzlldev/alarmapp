import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:alarmy/core/error/failures.dart';
import 'package:alarmy/core/usecase/usecase.dart';
import 'package:alarmy/features/subscription/domain/entities/plan_entity.dart';
import 'package:alarmy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:alarmy/features/subscription/domain/repositories/subscription_repository.dart';

/// Params for [BuyPlan]: the plan the user tapped to purchase.
class BuyPlanParams extends Equatable {
  const BuyPlanParams(this.plan);

  final PlanEntity plan;

  @override
  List<Object?> get props => [plan];
}

/// Drives the native purchase flow for a plan and returns the server-validated
/// subscription. The repository handles receipt forwarding and
/// `completePurchase`.
class BuyPlan implements UseCase<SubscriptionEntity, BuyPlanParams> {
  const BuyPlan(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, SubscriptionEntity>> call(BuyPlanParams params) {
    return _repository.buyPlan(params.plan);
  }
}
