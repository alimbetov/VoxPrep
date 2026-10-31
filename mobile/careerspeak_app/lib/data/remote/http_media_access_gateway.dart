import '../../application/ports/api_client.dart';
import '../../application/ports/media_access_gateway.dart';
import '../../application/result/result.dart';

final class HttpMediaAccessGateway implements MediaAccessGateway {
  const HttpMediaAccessGateway({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<MediaAccessGrant>> resolve(String assetId) async {
    final normalizedAssetId = assetId.trim();
    if (normalizedAssetId.isEmpty) {
      return const FailureResult(
        ApplicationFailure(
          code: 'MEDIA_ACCESS_TARGET_INVALID',
          message: 'The requested asset identity is invalid.',
        ),
      );
    }

    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.post,
        path: '/api/v1/media/access',
        jsonBody: <String, Object?>{'assetId': normalizedAssetId},
      ),
    );
    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    if (apiResponse.statusCode != 200) {
      return FailureResult(_statusFailure(apiResponse));
    }

    try {
      final body = apiResponse.jsonBody;
      if (body is! Map) {
        throw const FormatException('response must be a JSON object');
      }
      final object = <String, Object?>{};
      for (final entry in body.entries) {
        if (entry.key is! String) {
          throw const FormatException('response contains a non-string key');
        }
        object[entry.key as String] = entry.value;
      }
      const expected = <String>{'assetId', 'url', 'expiresAt'};
      if (object.keys.toSet().length != expected.length ||
          !object.keys.toSet().containsAll(expected)) {
        throw const FormatException(
          'response must contain exactly assetId, url and expiresAt',
        );
      }

      final responseAssetId = object['assetId'];
      final urlValue = object['url'];
      final expiresAtValue = object['expiresAt'];
      if (responseAssetId is! String ||
          urlValue is! String ||
          expiresAtValue is! String ||
          responseAssetId != normalizedAssetId) {
        throw const FormatException('response identity or field types are invalid');
      }
      final url = Uri.tryParse(urlValue);
      final expiresAt = DateTime.tryParse(expiresAtValue);
      if (url == null || expiresAt == null) {
        throw const FormatException('response URL or expiry is invalid');
      }

      return Success(
        MediaAccessGrant(
          assetId: responseAssetId,
          url: url,
          expiresAt: expiresAt,
        ),
      );
    } on Object catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'MEDIA_ACCESS_RESPONSE_INVALID',
          message: 'The media access endpoint returned an invalid grant.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  static ApplicationFailure _statusFailure(ApiResponse response) {
    return switch (response.statusCode) {
      401 => ApplicationFailure(
        code: 'INSTALLATION_UNAUTHORIZED',
        message: 'The installation is not authorized to request media.',
        traceId: response.traceId,
      ),
      403 => ApplicationFailure(
        code: 'MEDIA_ACCESS_FORBIDDEN',
        message: 'Media access is forbidden for this installation.',
        traceId: response.traceId,
      ),
      404 => ApplicationFailure(
        code: 'ASSET_NOT_FOUND',
        message: 'The requested published asset was not found.',
        traceId: response.traceId,
      ),
      409 => ApplicationFailure(
        code: 'ASSET_NOT_READY',
        message: 'The requested asset is not ready for delivery.',
        traceId: response.traceId,
        retryable: true,
      ),
      429 => ApplicationFailure(
        code: 'RATE_LIMITED',
        message: 'Media access requests are temporarily rate limited.',
        traceId: response.traceId,
        retryable: true,
      ),
      500 || 503 => ApplicationFailure(
        code: 'MEDIA_ACCESS_UNAVAILABLE',
        message: 'Media access is temporarily unavailable.',
        traceId: response.traceId,
        retryable: true,
      ),
      _ => ApplicationFailure(
        code: 'MEDIA_ACCESS_RESPONSE_INVALID',
        message: 'The media access endpoint returned an unexpected status.',
        traceId: response.traceId,
        details: <String, Object?>{'statusCode': response.statusCode},
      ),
    };
  }
}
