import 'package:dartz/dartz.dart';

import 'package:alarmy/core/error/failures.dart';
import 'package:alarmy/core/usecase/usecase.dart';
import 'package:alarmy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:alarmy/features/subscription/domain/repositories/subscription_repository.dart';

/// Reads the current user's subscription entitlement from the backend.
class GetMySubscription implements UseCase<SubscriptionEntity, NoParams> {
  const GetMySubscription(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, SubscriptionEntity>> call(NoParams params) {
    return _repository.getMySubscription();
  }
}
