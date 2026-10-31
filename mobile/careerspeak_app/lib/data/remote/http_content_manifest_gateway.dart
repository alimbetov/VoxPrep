import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/publication_manifest_canonicalizer.dart';
import '../../application/ports/api_client.dart';
import '../../application/ports/content_manifest_gateway.dart';
import '../../application/result/result.dart';
import 'content_manifest_decoder.dart';
import 'publication_manifest_wire_guard.dart';

final class HttpContentManifestGateway implements ContentManifestGateway {
  factory HttpContentManifestGateway({
    required ApiClient apiClient,
    ContentManifestDecoder decoder = const ContentManifestDecoder(),
    PublicationManifestWireGuard wireGuard =
        const PublicationManifestWireGuard(),
    PublicationManifestCanonicalizer canonicalizer =
        const PublicationManifestCanonicalizer(),
  }) {
    return HttpContentManifestGateway._(
      apiClient,
      decoder,
      wireGuard,
      canonicalizer,
    );
  }

  const HttpContentManifestGateway._(
    this._apiClient,
    this._decoder,
    this._wireGuard,
    this._canonicalizer,
  );

  final ApiClient _apiClient;
  final ContentManifestDecoder _decoder;
  final PublicationManifestWireGuard _wireGuard;
  final PublicationManifestCanonicalizer _canonicalizer;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
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

    final shape = _wireGuard.validateRoot(apiResponse.jsonBody);
    if (shape case FailureResult<void>(:final failure)) {
      return FailureResult<RootManifestFetch>(failure);
    }

    final decoded = _decoder.decodeRoot(apiResponse.jsonBody);
    if (decoded case FailureResult<RootContentManifest>(:final failure)) {
      return FailureResult<RootManifestFetch>(failure);
    }

    final manifest = (decoded as Success<RootContentManifest>).value;
    final calculatedChecksum = _canonicalizer.rootDigest(manifest);
    if (calculatedChecksum != manifest.checksum) {
      return FailureResult<RootManifestFetch>(
        ApplicationFailure(
          code: 'ROOT_MANIFEST_CHECKSUM_MISMATCH',
          message:
              'The root manifest checksum does not match its canonical immutable body.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{
            'declaredChecksum': manifest.checksum,
            'calculatedChecksum': calculatedChecksum,
          },
        ),
      );
    }

    return Success<RootManifestFetch>(
      RootManifestChanged(manifest: manifest, etag: responseEtag),
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

    final shape = _wireGuard.validatePack(apiResponse.jsonBody);
    if (shape case FailureResult<void>(:final failure)) {
      return FailureResult<PackContentManifest>(failure);
    }

    final decoded = _decoder.decodePack(apiResponse.jsonBody);
    if (decoded case FailureResult<PackContentManifest>(:final failure)) {
      return FailureResult<PackContentManifest>(failure);
    }

    final manifest = (decoded as Success<PackContentManifest>).value;
    final calculatedChecksum = _canonicalizer.packDigest(manifest);
    if (calculatedChecksum != manifest.checksum) {
      return FailureResult<PackContentManifest>(
        ApplicationFailure(
          code: 'PACK_MANIFEST_CHECKSUM_MISMATCH',
          message:
              'The pack manifest checksum does not match its canonical immutable body.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{
            'declaredChecksum': manifest.checksum,
            'calculatedChecksum': calculatedChecksum,
          },
        ),
      );
    }

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
