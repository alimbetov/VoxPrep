import 'dart:async';

import 'package:http/http.dart' as http;

import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/asset_byte_source.dart';
import '../../application/ports/media_access_gateway.dart';
import '../../application/result/result.dart';

final class HttpAssetByteSource implements AssetByteSource {
  factory HttpAssetByteSource({
    required http.Client client,
    required MediaAccessGateway accessGateway,
    Duration timeout = const Duration(seconds: 20),
  }) {
    return HttpAssetByteSource._(
      client,
      accessGateway,
      _validateTimeout(timeout),
    );
  }

  const HttpAssetByteSource._(this._client, this._accessGateway, this._timeout);

  final http.Client _client;
  final MediaAccessGateway _accessGateway;
  final Duration _timeout;

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) {
    return _open(asset, refreshForbiddenGrant: true);
  }

  Future<Result<AssetByteStream>> _open(
    ManifestAssetDescriptor asset, {
    required bool refreshForbiddenGrant,
  }) async {
    final grantResult = await _accessGateway.resolve(asset.assetId);
    if (grantResult case FailureResult<MediaAccessGrant>(:final failure)) {
      return FailureResult(failure);
    }
    final grant = (grantResult as Success<MediaAccessGrant>).value;
    if (grant.assetId != asset.assetId) {
      return const FailureResult(
        ApplicationFailure(
          code: 'MEDIA_ACCESS_RESPONSE_INVALID',
          message: 'The media access grant does not match the requested asset.',
        ),
      );
    }

    final request = http.Request('GET', grant.url)
      ..headers['accept'] = '*/*'
      ..followRedirects = false;

    try {
      final response = await _client.send(request).timeout(_timeout);
      if (response.statusCode == 403 && refreshForbiddenGrant) {
        await response.stream.drain<void>();
        return _open(asset, refreshForbiddenGrant: false);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.stream.drain<void>();
        return FailureResult(_httpFailure(response.statusCode));
      }

      return Success(
        AssetByteStream(
          bytes: response.stream,
          contentLength: response.contentLength,
        ),
      );
    } on TimeoutException {
      return const FailureResult(
        ApplicationFailure(
          code: 'ASSET_TIMEOUT',
          message: 'The asset request timed out.',
          retryable: true,
        ),
      );
    } on http.ClientException {
      return const FailureResult(
        ApplicationFailure(
          code: 'ASSET_OFFLINE',
          message: 'The asset request could not be completed.',
          retryable: true,
        ),
      );
    }
  }

  static Duration _validateTimeout(Duration value) {
    if (value <= Duration.zero) {
      throw ArgumentError.value(value, 'timeout', 'must be positive');
    }
    return value;
  }

  static ApplicationFailure _httpFailure(int statusCode) {
    if (statusCode == 404) {
      return const ApplicationFailure(
        code: 'ASSET_NOT_FOUND',
        message: 'The granted media object was not found.',
      );
    }
    if (statusCode == 408 ||
        statusCode == 429 ||
        statusCode == 500 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504) {
      return ApplicationFailure(
        code: 'ASSET_SOURCE_UNAVAILABLE',
        message: 'The asset source is temporarily unavailable.',
        retryable: true,
        details: <String, Object?>{'statusCode': statusCode},
      );
    }
    return ApplicationFailure(
      code: 'ASSET_DOWNLOAD_REJECTED',
      message: 'The asset source rejected the granted request.',
      details: <String, Object?>{'statusCode': statusCode},
    );
  }
}
