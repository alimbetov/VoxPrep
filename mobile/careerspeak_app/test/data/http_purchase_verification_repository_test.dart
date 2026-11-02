import 'package:careerspeak_app/application/access/store_product.dart';
import 'package:careerspeak_app/application/access/store_purchase_event.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_purchase_verification_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('POSTs Store proof to purchase verification endpoint', () async {
    final api = _RecordingApiClient(
      response: ApiResponse(
        statusCode: 200,
        headers: const <String, String>{},
        jsonBody: <String, Object?>{
          'verified': true,
          'accessLevel': 'FULL',
          'verifiedAt': '2026-11-02T04:00:00.000Z',
        },
      ),
    );
    final repository = HttpPurchaseVerificationRepository(apiClient: api);

    final result = await repository.verify(
      StorePurchaseEvent(
        eventId: 'event-1',
        provider: StoreProvider.googlePlay,
        productId: fullUnlockProductId,
        status: StorePurchaseStatus.purchased,
        serverVerificationData: 'server-proof',
      ),
    );

    expect(result, isA<Success<Object?>>());
    final decision = result.getOrThrow();
    expect(decision.grantsFullAccess, isTrue);
    expect(decision.accessLevel, AccessLevel.full);
    expect(api.request?.method, ApiMethod.post);
    expect(api.request?.path, '/api/v1/purchases/verify');
    expect(api.request?.authentication, ApiAuthentication.installation);
    expect(api.request?.jsonBody, <String, Object?>{
      'provider': 'GOOGLE_PLAY',
      'productId': fullUnlockProductId,
      'purchaseEventId': 'event-1',
      'verificationData': 'server-proof',
    });
  });

  test('malformed verified response fails closed', () async {
    final api = _RecordingApiClient(
      response: ApiResponse(
        statusCode: 200,
        headers: const <String, String>{},
        jsonBody: <String, Object?>{'verified': true},
      ),
    );
    final repository = HttpPurchaseVerificationRepository(apiClient: api);

    final result = await repository.verify(
      StorePurchaseEvent(
        eventId: 'event-2',
        provider: StoreProvider.appStore,
        productId: fullUnlockProductId,
        status: StorePurchaseStatus.restored,
        serverVerificationData: 'server-proof',
      ),
    );

    expect(result, isA<FailureResult<Object?>>());
    final failure = (result as FailureResult).failure;
    expect(failure.code, 'PURCHASE_VERIFICATION_INVALID_RESPONSE');
  });
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({required this.response});

  final ApiResponse response;
  ApiRequest? request;

  @override
  Future<Result<ApiResponse>> send(ApiRequest value) async {
    request = value;
    return Success<ApiResponse>(response);
  }
}
