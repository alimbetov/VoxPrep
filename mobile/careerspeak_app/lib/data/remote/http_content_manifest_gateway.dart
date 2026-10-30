import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/api_client.dart';
import '../../application/ports/content_manifest_gateway.dart';
import '../../application/result/result.dart';
import 'content_manifest_decoder.dart';

final class HttpContentManifestGateway implements ContentManifestGateway {
  factory HttpContentManifestGateway({
    required ApiClient apiClient,
    ContentManifestDecoder decoder = const ContentManifestDecoder(),
  }) {
    return HttpContentManifestGateway._(apiClient, decoder);
  }

  const HttpContentManifestGateway._(this._apiClient, this._decoder);

  final ApiClient _apiClient;
  final ContentManifestDecoder _decoder;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({
    required String translationLocale,
    String? etag,
  }) async {
    final locale = _normalizeLocale(translationLocale);
    if (locale == null) {
      return const FailureResult<RootManifestFetch>(
        ApplicationFailure(
          code: 'LOCALE_INVALID',
          message: 'Translation locale is invalid.',
        ),
      );
    }
    if (_containsUnsafeHeaderCharacter(etag)) {
      return const FailureResult<RootManifestFetch>(
        ApplicationFailure(
          code: 'ETAG_INVALID',
          message: 'The stored manifest ETag is invalid.',
        ),
      );
    }

    final normalizedEtag = _normalizeOptionalHeaderValue(etag);
    final headers = normalizedEtag == null
        ? const <String, String>{}
        : <String, String>{'if-none-match': normalizedEtag};
    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path: '/api/v1/content/manifest',
        queryParameters: <String, String>{'locale': locale},
        headers: headers,
      ),
    );

    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<RootManifestFetch>(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    final responseEtag = _normalizeOptionalHeaderValue(
      apiResponse.header('etag'),
    );

    if (apiResponse.statusCode == 304) {
      if (normalizedEtag == null) {
        return FailureResult<RootManifestFetch>(
          ApplicationFailure(
            code: 'MANIFEST_RESPONSE_INVALID',
            message:
                'The root manifest endpoint returned 304 '
                'without a request validator.',
            traceId: apiResponse.traceId,
            details: const <String, Object?>{'statusCode': 304},
          ),
        );
      }
      return Success<RootManifestFetch>(
        RootManifestNotModified(etag: responseEtag ?? normalizedEtag),
      );
    }
    if (apiResponse.statusCode != 200) {
      return FailureResult<RootManifestFetch>(
        ApplicationFailure(
          code: 'MANIFEST_RESPONSE_INVALID',
          message: 'The root manifest endpoint returned an invalid status.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{'statusCode': apiResponse.statusCode},
        ),
      );
    }

    final decoded = _decoder.decodeRoot(apiResponse.jsonBody);
    if (decoded case FailureResult<RootContentManifest>(:final failure)) {
      return FailureResult<RootManifestFetch>(failure);
    }

    return Success<RootManifestFetch>(
      RootManifestChanged(
        manifest: (decoded as Success<RootContentManifest>).value,
        etag: responseEtag,
      ),
    );
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path:
            '/api/v1/content/packs/${Uri.encodeComponent(target.identity.code)}/manifest',
        queryParameters: <String, String>{
          'variant': target.identity.variant,
          'revision': target.revision.toString(),
        },
      ),
    );

    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<PackContentManifest>(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    if (apiResponse.statusCode != 200) {
      return FailureResult<PackContentManifest>(
        ApplicationFailure(
          code: 'PACK_MANIFEST_RESPONSE_INVALID',
          message: 'The pack manifest endpoint returned an invalid status.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{'statusCode': apiResponse.statusCode},
        ),
      );
    }

    final decoded = _decoder.decodePack(apiResponse.jsonBody);
    if (decoded case FailureResult<PackContentManifest>(:final failure)) {
      return FailureResult<PackContentManifest>(failure);
    }

    final manifest = (decoded as Success<PackContentManifest>).value;
    if (manifest.identity != target.identity ||
        manifest.revision != target.revision ||
        manifest.checksum != target.checksum) {
      return FailureResult<PackContentManifest>(
        ApplicationFailure(
          code: 'PACK_MANIFEST_MISMATCH',
          message: 'The pack manifest does not match the root manifest target.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{
            'expectedPack': target.identity.toString(),
            'expectedRevision': target.revision,
            'actualPack': manifest.identity.toString(),
            'actualRevision': manifest.revision,
          },
        ),
      );
    }

    return Success<PackContentManifest>(manifest);
  }

  static String? _normalizeLocale(String value) {
    final normalized = value.trim();
    if (!_localePattern.hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  static String? _normalizeOptionalHeaderValue(String? value) {
    if (_containsUnsafeHeaderCharacter(value)) {
      return null;
    }
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static bool _containsUnsafeHeaderCharacter(String? value) {
    return value != null && (value.contains('\r') || value.contains('\n'));
  }
}

final _localePattern = RegExp(r'^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$');
