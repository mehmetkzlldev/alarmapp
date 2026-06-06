import 'package:freezed_annotation/freezed_annotation.dart';

part 'validate_purchase_request.freezed.dart';
part 'validate_purchase_request.g.dart';

/// Request body for `POST /subscriptions/validate`.
///
/// `store` is `app_store` (Apple) or `play_store` (Google). `receipt` carries
/// the verification payload the backend needs:
///   - iOS: the base64 App Store receipt (or StoreKit2 JWS).
///   - Android: the Play purchase token.
///
/// The backend performs the actual server-side validation against Apple/Google;
/// the client never decides entitlement.
@freezed
class ValidatePurchaseRequest with _$ValidatePurchaseRequest {
  const factory ValidatePurchaseRequest({
    required String store,
    required String productId,
    required String receipt,
  }) = _ValidatePurchaseRequest;

  factory ValidatePurchaseRequest.fromJson(Map<String, dynamic> json) =>
      _$ValidatePurchaseRequestFromJson(json);
}
