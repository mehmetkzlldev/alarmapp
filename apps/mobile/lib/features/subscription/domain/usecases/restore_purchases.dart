import 'package:dartz/dartz.dart';

import 'package:alarmy/core/error/failures.dart';
import 'package:alarmy/core/usecase/usecase.dart';
import 'package:alarmy/features/subscription/domain/entities/subscription_entity.dart';
import 'package:alarmy/features/subscription/domain/repositories/subscription_repository.dart';

/// Restores previously-purchased entitlements (App Store / Play). Re-validates
/// restored receipts server-side and returns the resulting subscription.
class RestorePurchases implements UseCase<SubscriptionEntity, NoParams> {
  const RestorePurchases(this._repository);

  final SubscriptionRepository _repository;

  @override
  Future<Either<Failure, SubscriptionEntity>> call(NoParams params) {
    return _repository.restorePurchases();
  }
}
