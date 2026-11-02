import '../../application/access/purchase_verification.dart';
import '../../application/access/store_product.dart';
import '../../application/access/store_purchase_event.dart';
import '../../application/content_delivery/product_catalog.dart';
import '../../application/ports/api_client.dart';
import '../../application/ports/purchase_verification_repository.dart';
import '../../application/result/result.dart';

final class HttpPurchaseVerificationRepository
    implements PurchaseVerificationRepository {
  const HttpPurchaseVerificationRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<PurchaseVerification>> verify(StorePurchaseEvent event) async {
    final proof = event.serverVerificationData;
    if (!event.requiresVerification ||
        event.productId != fullUnlockProductId ||
        proof == null ||
        proof.isEmpty) {
      return Success<PurchaseVerification>(PurchaseVerification.rejected());
    }

    final result = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.post,
        path: '/api/v1/purchases/verify',
        authentication: ApiAuthentication.installation,
        jsonBody: <String, Object?>{
          'provider': event.provider.wireName,
          'productId': event.productId,
          'purchaseEventId': event.eventId,
          'verificationData': proof,
        },
      ),
    );
    if (result case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<PurchaseVerification>(failure);
    }

    final response = (result as Success<ApiResponse>).value;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return FailureResult<PurchaseVerification>(
        ApplicationFailure(
          code: 'PURCHASE_VERIFICATION_FAILED',
          message: 'Purchase could not be verified right now.',
          retryable: response.statusCode >= 500 || response.statusCode == 429,
          traceId: response.traceId,
        ),
      );
    }

    final body = response.jsonBody;
    if (body is! Map<String, Object?>) {
      return const FailureResult<PurchaseVerification>(
        ApplicationFailure(
          code: 'PURCHASE_VERIFICATION_INVALID_RESPONSE',
          message: 'Purchase verification returned an invalid response.',
        ),
      );
    }

    final verified = body['verified'];
    if (verified != true) {
      return Success<PurchaseVerification>(PurchaseVerification.rejected());
    }

    try {
      final accessLevelValue = body['accessLevel'];
      final verifiedAtValue = body['verifiedAt'];
      if (accessLevelValue is! String || verifiedAtValue is! String) {
        throw const FormatException('Missing verification fields.');
      }
      final accessLevel = AccessLevel.fromWireName(accessLevelValue);
      final verifiedAt = DateTime.parse(verifiedAtValue).toUtc();
      return Success<PurchaseVerification>(
        PurchaseVerification(
          verified: true,
          accessLevel: accessLevel,
          verifiedAt: verifiedAt,
        ),
      );
    } on Object {
      return const FailureResult<PurchaseVerification>(
        ApplicationFailure(
          code: 'PURCHASE_VERIFICATION_INVALID_RESPONSE',
          message: 'Purchase verification returned an invalid response.',
        ),
      );
    }
  }
}
