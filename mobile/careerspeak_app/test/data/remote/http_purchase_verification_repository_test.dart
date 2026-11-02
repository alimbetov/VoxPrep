import 'package:careerspeak_app/application/access/purchase_verification.dart';
import 'package:careerspeak_app/application/access/store_product.dart';
import 'package:careerspeak_app/application/access/store_purchase_event.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_purchase_verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('posts exact purchase verification wire contract', () async {
    final apiClient = _FakeApiClient(
      Success<ApiResponse>(
        ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{
            'verified': true,
            'accessLevel': 'FULL',
            'verifiedAt': '2026-11-02T10:00:00Z',
          },
        ),
      ),
    );
    final repository = HttpPurchaseVerificationRepository(apiClient: apiClient);

    final result = await repository.verify(_purchasedEvent());

    final verification = result.getOrThrow();
    expect(verification.verified, isTrue);
    expect(verification.accessLevel, AccessLevel.full);
    expect(verification.grantsFullAccess, isTrue);
    expect(verification.verifiedAt, DateTime.utc(2026, 11, 2, 10));

    expect(apiClient.requests, hasLength(1));
    final request = apiClient.requests.single;
    expect(request.method, ApiMethod.post);
    expect(request.path, '/api/v1/purchases/verify');
    expect(request.authentication, ApiAuthentication.installation);
    expect(request.jsonBody, const <String, Object?>{
      'provider': 'GOOGLE_PLAY',
      'productId': fullUnlockProductId,
      'purchaseEventId': 'purchase-event-123',
      'verificationData': 'opaque-store-proof',
    });
  });

  test('treats verified false as rejected without granting Full', () async {
    final apiClient = _FakeApiClient(
      Success<ApiResponse>(
        ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{'verified': false},
        ),
      ),
    );
    final repository = HttpPurchaseVerificationRepository(apiClient: apiClient);

    final verification = (await repository.verify(_purchasedEvent())).getOrThrow();

    expect(verification.verified, isFalse);
    expect(verification.accessLevel, AccessLevel.free);
    expect(verification.grantsFullAccess, isFalse);
    expect(verification.verifiedAt, isNull);
  });

  test('fails closed for malformed verified response', () async {
    final apiClient = _FakeApiClient(
      Success<ApiResponse>(
        ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{
            'verified': true,
            'accessLevel': 'FULL',
          },
        ),
      ),
    );
    final repository = HttpPurchaseVerificationRepository(apiClient: apiClient);

    final result = await repository.verify(_purchasedEvent());

    expect(result, isA<FailureResult<PurchaseVerification>>());
    expect(
      (result as FailureResult<PurchaseVerification>).failure.code,
      'PURCHASE_VERIFICATION_INVALID_RESPONSE',
    );
  });

  test('does not call backend for ineligible product event', () async {
    final apiClient = _FakeApiClient(
      Success<ApiResponse>(
        ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{'verified': true},
        ),
      ),
    );
    final repository = HttpPurchaseVerificationRepository(apiClient: apiClient);
    final event = StorePurchaseEvent(
      eventId: 'other-event',
      provider: StoreProvider.appStore,
      productId: 'other_product',
      status: StorePurchaseStatus.purchased,
      serverVerificationData: 'opaque-proof',
    );

    final verification = (await repository.verify(event)).getOrThrow();

    expect(verification.grantsFullAccess, isFalse);
    expect(apiClient.requests, isEmpty);
  });

  test('marks 503 verification failure retryable', () async {
    final apiClient = _FakeApiClient(
      Success<ApiResponse>(
        ApiResponse(
          statusCode: 503,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{},
          traceId: 'trace-503',
        ),
      ),
    );
    final repository = HttpPurchaseVerificationRepository(apiClient: apiClient);

    final result = await repository.verify(_purchasedEvent());

    expect(result, isA<FailureResult<PurchaseVerification>>());
    final failure = (result as FailureResult<PurchaseVerification>).failure;
    expect(failure.code, 'PURCHASE_VERIFICATION_FAILED');
    expect(failure.retryable, isTrue);
    expect(failure.traceId, 'trace-503');
  });
}

StorePurchaseEvent _purchasedEvent() => StorePurchaseEvent(
  eventId: 'purchase-event-123',
  provider: StoreProvider.googlePlay,
  productId: fullUnlockProductId,
  status: StorePurchaseStatus.purchased,
  serverVerificationData: 'opaque-store-proof',
);

final class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.result);

  final Result<ApiResponse> result;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    requests.add(request);
    return result;
  }
}
