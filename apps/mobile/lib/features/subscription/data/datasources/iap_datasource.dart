import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
// Platform-specific addition imports give us access to the verification
// payloads required by our backend validator.
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'package:alarmy/core/error/exceptions.dart';
import 'package:alarmy/features/subscription/data/datasources/subscription_remote_datasource.dart';
import 'package:alarmy/features/subscription/data/models/subscription_model.dart';
import 'package:alarmy/features/subscription/data/models/validate_purchase_request.dart';
import 'package:alarmy/features/subscription/domain/entities/plan_entity.dart';

/// Outcome of a single purchase/restore event after server-side validation.
///
/// Emitted on [IapDataSource.validatedPurchaseStream]. The repository surfaces
/// these to the provider so the UI can react (success, cancellation, error).
sealed class IapPurchaseResult {
  const IapPurchaseResult();
}

/// The purchase was completed natively, validated by our backend, and the
/// platform purchase was acknowledged/finished.
class IapPurchaseSuccess extends IapPurchaseResult {
  const IapPurchaseSuccess(this.subscription, this.productId);
  final SubscriptionModel subscription;
  final String productId;
}

/// The user cancelled the native purchase dialog.
class IapPurchaseCanceled extends IapPurchaseResult {
  const IapPurchaseCanceled();
}

/// The purchase or its validation failed.
class IapPurchaseError extends IapPurchaseResult {
  const IapPurchaseError(this.message, {this.code});
  final String message;
  final String? code;
}

/// Thin wrapper over `in_app_purchase` for our two non-consumable subscription
/// products. Responsibilities:
///   1. Query localized [ProductDetails] for [StoreProductIds.all].
///   2. Launch the native buy flow (`buyNonConsumable`).
///   3. Listen to [InAppPurchase.purchaseStream], and for each purchased/restored
///      item: forward the store receipt/token to `POST /subscriptions/validate`,
///      then call `completePurchase` so the platform stops re-delivering it.
///   4. Restore past purchases.
///
/// IMPORTANT: We always `completePurchase` for delivered purchases (even on
/// validation failure with a finished transaction) to avoid the OS re-prompting
/// indefinitely, but only emit success when the backend confirms entitlement.
abstract interface class IapDataSource {
  /// Whether the underlying store is available on this device.
  Future<bool> isStoreAvailable();

  /// Begins listening to the platform purchase stream. Safe to call once at
  /// startup; subsequent calls are no-ops.
  void initialize();

  /// Localized product details keyed by productId, queried from the store.
  Future<Map<String, ProductDetails>> queryProducts();

  /// Launches the native purchase flow for the given [productId].
  /// Resolution arrives asynchronously via [validatedPurchaseStream].
  Future<void> buy(String productId);

  /// Asks the platform to re-deliver past purchases. Results arrive on
  /// [validatedPurchaseStream] as restored items are validated.
  Future<void> restore();

  /// Stream of validated purchase/restore outcomes (post backend validation).
  Stream<IapPurchaseResult> get validatedPurchaseStream;

  /// Releases the underlying subscription. Call on dispose.
  Future<void> dispose();
}

class IapDataSourceImpl implements IapDataSource {
  IapDataSourceImpl({
    required InAppPurchase inAppPurchase,
    required SubscriptionRemoteDataSource remote,
  })  : _iap = inAppPurchase,
        _remote = remote;

  final InAppPurchase _iap;
  final SubscriptionRemoteDataSource _remote;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final StreamController<IapPurchaseResult> _resultController =
      StreamController<IapPurchaseResult>.broadcast();

  bool _initialized = false;

  @override
  Stream<IapPurchaseResult> get validatedPurchaseStream =>
      _resultController.stream;

  @override
  Future<bool> isStoreAvailable() => _iap.isAvailable();

  @override
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    // The platform may deliver pending purchases immediately on subscribe
    // (e.g. an interrupted purchase from a previous session), so we attach the
    // listener before any buy() call.
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (Object error) {
        _resultController.add(IapPurchaseError(error.toString()));
      },
    );
  }

  @override
  Future<Map<String, ProductDetails>> queryProducts() async {
    final response = await _iap.queryProductDetails(StoreProductIds.all);
    if (response.error != null) {
      throw ServerException(
        message: 'Failed to load store products: ${response.error!.message}',
      );
    }
    return {
      for (final p in response.productDetails) p.id: p,
    };
  }

  @override
  Future<void> buy(String productId) async {
    final products = await queryProducts();
    final product = products[productId];
    if (product == null) {
      throw ServerException(
        message: 'Product "$productId" is not available on this store.',
      );
    }
    final param = PurchaseParam(productDetails: product);
    // Subscriptions are modeled as non-consumables in in_app_purchase.
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      throw ServerException(message: 'Unable to start the purchase.');
    }
    // The actual result (success/cancel/error) arrives via the purchaseStream.
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  /// Handles a batch of purchase updates from the platform.
  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      await _handleSinglePurchase(purchase);
    }
  }

  Future<void> _handleSinglePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.pending:
        // Awaiting user action (e.g. SCA, parental approval). Do nothing yet.
        return;

      case PurchaseStatus.canceled:
        // Ensure the transaction is finished so the OS doesn't re-deliver it.
        await _finishIfNeeded(purchase);
        _resultController.add(const IapPurchaseCanceled());
        return;

      case PurchaseStatus.error:
        await _finishIfNeeded(purchase);
        _resultController.add(
          IapPurchaseError(
            purchase.error?.message ?? 'Purchase failed.',
            code: purchase.error?.code,
          ),
        );
        return;

      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _validateAndFinish(purchase);
        return;
    }
  }

  /// Forwards the store receipt to the backend for validation, then finishes
  /// the platform transaction regardless of the outcome (a finished, delivered
  /// transaction must be acknowledged within the store's window).
  Future<void> _validateAndFinish(PurchaseDetails purchase) async {
    try {
      final request = _buildValidateRequest(purchase);
      final model = await _remote.validatePurchase(request);
      // Acknowledge to the store only AFTER successful server validation so a
      // network blip doesn't strand the user with an unverified-but-finished
      // purchase. The platform will re-deliver on next launch if not finished.
      await _finishIfNeeded(purchase);
      _resultController.add(IapPurchaseSuccess(model, purchase.productID));
    } on PremiumRequiredException catch (e) {
      // Backend explicitly rejected entitlement (e.g. fraudulent receipt).
      await _finishIfNeeded(purchase);
      _resultController.add(IapPurchaseError(e.message, code: 'validation'));
    } on ServerException catch (e) {
      // Do NOT finish on a server/transport failure — leaving the purchase
      // pending lets us retry validation on the next app launch.
      _resultController.add(IapPurchaseError(e.message, code: 'validation'));
    } on NetworkException catch (e) {
      _resultController.add(IapPurchaseError(e.message, code: 'network'));
    }
  }

  /// Builds the platform-correct validation request.
  ///
  /// - Android: backend needs the Play **purchase token**.
  /// - iOS: backend needs the App Store **receipt** (base64) / StoreKit JWS.
  ValidatePurchaseRequest _buildValidateRequest(PurchaseDetails purchase) {
    if (purchase is GooglePlayPurchaseDetails) {
      return ValidatePurchaseRequest(
        store: 'play_store',
        productId: purchase.productID,
        // The Play purchase token is what Google Play Developer API verifies.
        receipt: purchase.billingClientPurchase.purchaseToken,
      );
    }
    if (purchase is AppStorePurchaseDetails) {
      return ValidatePurchaseRequest(
        store: 'app_store',
        productId: purchase.productID,
        receipt: purchase.verificationData.serverVerificationData,
      );
    }
    // Fallback: use the generic verification data and infer the store. This
    // keeps us resilient if the plugin's concrete types change.
    final store =
        purchase.verificationData.source == 'app_store' ? 'app_store' : 'play_store';
    return ValidatePurchaseRequest(
      store: store,
      productId: purchase.productID,
      receipt: purchase.verificationData.serverVerificationData,
    );
  }

  Future<void> _finishIfNeeded(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  @override
  Future<void> dispose() async {
    await _purchaseSub?.cancel();
    _purchaseSub = null;
    await _resultController.close();
    _initialized = false;
  }
}
