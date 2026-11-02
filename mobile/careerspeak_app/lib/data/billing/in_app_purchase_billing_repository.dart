import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../application/access/store_product.dart';
import '../../application/access/store_purchase_event.dart';
import '../../application/ports/billing_repository.dart';
import '../../application/result/result.dart';

final class InAppPurchaseBillingRepository implements BillingRepository {
  InAppPurchaseBillingRepository({InAppPurchase? inAppPurchase})
      : _inAppPurchase = inAppPurchase ?? InAppPurchase.instance {
    _events = _inAppPurchase.purchaseStream.expand(_mapPurchaseList);
  }

  final InAppPurchase _inAppPurchase;
  final Map<String, ProductDetails> _productDetailsById = <String, ProductDetails>{};
  final Map<String, PurchaseDetails> _purchaseDetailsByEventId =
      <String, PurchaseDetails>{};
  late final Stream<StorePurchaseEvent> _events;
  int _eventSequence = 0;

  @override
  Future<Result<StoreProduct>> loadFullUnlockProduct() async {
    try {
      if (!await _inAppPurchase.isAvailable()) {
        return const FailureResult<StoreProduct>(
          ApplicationFailure(
            code: 'STORE_UNAVAILABLE',
            message: 'Store purchases are temporarily unavailable.',
            retryable: true,
          ),
        );
      }

      final response = await _inAppPurchase.queryProductDetails(
        const <String>{fullUnlockProductId},
      );
      if (response.error != null ||
          response.notFoundIDs.contains(fullUnlockProductId)) {
        return const FailureResult<StoreProduct>(
          ApplicationFailure(
            code: 'STORE_PRODUCT_UNAVAILABLE',
            message: 'Full Unlock is temporarily unavailable.',
            retryable: true,
          ),
        );
      }

      final matches = response.productDetails
          .where((product) => product.id == fullUnlockProductId)
          .toList(growable: false);
      if (matches.length != 1) {
        return const FailureResult<StoreProduct>(
          ApplicationFailure(
            code: 'STORE_PRODUCT_UNAVAILABLE',
            message: 'Full Unlock is temporarily unavailable.',
            retryable: true,
          ),
        );
      }

      final details = matches.single;
      _productDetailsById[details.id] = details;
      return Success<StoreProduct>(_toStoreProduct(details));
    } on Object catch (error) {
      return FailureResult<StoreProduct>(
        ApplicationFailure(
          code: 'STORE_UNAVAILABLE',
          message: 'Store purchases are temporarily unavailable.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  @override
  Stream<StorePurchaseEvent> watchPurchaseEvents() => _events;

  @override
  Future<Result<void>> purchaseFullUnlock(StoreProduct product) async {
    if (!product.isFullUnlock) {
      return const FailureResult<void>(
        ApplicationFailure(
          code: 'STORE_PRODUCT_INVALID',
          message: 'This Store product cannot unlock VoxPrep.',
        ),
      );
    }

    try {
      var details = _productDetailsById[product.productId];
      if (details == null) {
        final loaded = await loadFullUnlockProduct();
        if (loaded case FailureResult<StoreProduct>(:final failure)) {
          return FailureResult<void>(failure);
        }
        details = _productDetailsById[product.productId];
      }
      if (details == null) {
        return const FailureResult<void>(
          ApplicationFailure(
            code: 'STORE_PRODUCT_UNAVAILABLE',
            message: 'Full Unlock is temporarily unavailable.',
            retryable: true,
          ),
        );
      }

      final launched = await _inAppPurchase.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!launched) {
        return const FailureResult<void>(
          ApplicationFailure(
            code: 'PURCHASE_UNAVAILABLE',
            message: 'Purchase could not be started.',
            retryable: true,
          ),
        );
      }
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'PURCHASE_UNAVAILABLE',
          message: 'Purchase could not be started.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  @override
  Future<Result<void>> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'STORE_UNAVAILABLE',
          message: 'Purchases could not be restored right now.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  @override
  Future<Result<void>> completePurchase(String eventId) async {
    final purchase = _purchaseDetailsByEventId[eventId];
    if (purchase == null) {
      return const FailureResult<void>(
        ApplicationFailure(
          code: 'PURCHASE_EVENT_UNKNOWN',
          message: 'Purchase completion is unavailable.',
        ),
      );
    }

    try {
      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
      _purchaseDetailsByEventId.remove(eventId);
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'PURCHASE_COMPLETION_FAILED',
          message: 'Purchase completion could not be confirmed.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  Iterable<StorePurchaseEvent> _mapPurchaseList(
    List<PurchaseDetails> purchases,
  ) sync* {
    for (final purchase in purchases) {
      if (purchase.productID != fullUnlockProductId) continue;
      final eventId = 'store-event-${++_eventSequence}';
      _purchaseDetailsByEventId[eventId] = purchase;
      yield StorePurchaseEvent(
        eventId: eventId,
        provider: _providerFromSource(purchase.verificationData.source),
        productId: purchase.productID,
        status: _status(purchase.status),
        serverVerificationData: switch (purchase.status) {
          PurchaseStatus.purchased || PurchaseStatus.restored =>
            purchase.verificationData.serverVerificationData,
          _ => null,
        },
      );
    }
  }

  StoreProduct _toStoreProduct(ProductDetails details) {
    return StoreProduct(
      productId: details.id,
      title: details.title,
      description: details.description,
      localizedPrice: details.price,
    );
  }

  StoreProvider _providerFromSource(String source) {
    return switch (source) {
      'google_play' => StoreProvider.googlePlay,
      'app_store' => StoreProvider.appStore,
      _ => throw FormatException('Unsupported Store verification source.'),
    };
  }

  StorePurchaseStatus _status(PurchaseStatus status) {
    return switch (status) {
      PurchaseStatus.pending => StorePurchaseStatus.pending,
      PurchaseStatus.purchased => StorePurchaseStatus.purchased,
      PurchaseStatus.restored => StorePurchaseStatus.restored,
      PurchaseStatus.canceled => StorePurchaseStatus.cancelled,
      PurchaseStatus.error => StorePurchaseStatus.failed,
    };
  }
}
