import 'package:alarmy/core/error/exceptions.dart';
import 'package:alarmy/core/network/dio_client.dart';
import 'package:alarmy/features/subscription/data/models/plan_model.dart';
import 'package:alarmy/features/subscription/data/models/subscription_model.dart';
import 'package:alarmy/features/subscription/data/models/validate_purchase_request.dart';

/// Subscription endpoint paths. Kept local to the feature so it stays
/// self-contained and does not depend on volatile shared constants.
class _SubscriptionRoutes {
  _SubscriptionRoutes._();
  static const String me = '/subscriptions/me';
  static const String plans = '/subscriptions/plans';
  static const String validate = '/subscriptions/validate';
}

/// Talks to our backend for subscription data over Dio (via [DioClient], which
/// already normalizes transport errors into domain exceptions).
abstract interface class SubscriptionRemoteDataSource {
  /// `GET /subscriptions/me` -> current subscription.
  Future<SubscriptionModel> getMySubscription();

  /// `GET /subscriptions/plans` -> marketing plan catalog.
  Future<List<PlanModel>> getPlans();

  /// `POST /subscriptions/validate` -> server-validated subscription.
  ///
  /// This is the authoritative entitlement check: the backend verifies the
  /// store receipt with Apple/Google and returns the resulting subscription.
  Future<SubscriptionModel> validatePurchase(ValidatePurchaseRequest request);
}

class SubscriptionRemoteDataSourceImpl implements SubscriptionRemoteDataSource {
  SubscriptionRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<SubscriptionModel> getMySubscription() async {
    final res = await _client.get<Map<String, dynamic>>(_SubscriptionRoutes.me);
    final data = res.data;
    if (data == null) {
      throw ServerException(message: 'Empty subscription response');
    }
    return SubscriptionModel.fromJson(data);
  }

  @override
  Future<List<PlanModel>> getPlans() async {
    final res =
        await _client.get<List<dynamic>>(_SubscriptionRoutes.plans);
    final data = res.data ?? const <dynamic>[];
    return data
        .whereType<Map<String, dynamic>>()
        .map(PlanModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<SubscriptionModel> validatePurchase(
    ValidatePurchaseRequest request,
  ) async {
    final res = await _client.post<Map<String, dynamic>>(
      _SubscriptionRoutes.validate,
      data: request.toJson(),
    );
    final data = res.data;
    if (data == null) {
      throw ServerException(message: 'Empty validation response');
    }
    return SubscriptionModel.fromJson(data);
  }
}
