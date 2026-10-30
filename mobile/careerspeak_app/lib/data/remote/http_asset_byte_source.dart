import 'dart:async';

import 'package:http/http.dart' as http;

import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/asset_byte_source.dart';
import '../../application/result/result.dart';

final class HttpAssetByteSource implements AssetByteSource {
  factory HttpAssetByteSource({
    required http.Client client,
    required Uri baseUri,
    Duration timeout = const Duration(seconds: 20),
  }) {
    return HttpAssetByteSource._(
      client,
      _validateBaseUri(baseUri),
      _validateTimeout(timeout),
    );
  }

  const HttpAssetByteSource._(this._client, this._baseUri, this._timeout);

  final http.Client _client;
  final Uri _baseUri;
  final Duration _timeout;

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    final request = http.Request('GET', _resolve(asset.deliveryKey))
      ..headers['accept'] = '*/*';

    try {
      final response = await _client.send(request).timeout(_timeout);
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

  Uri _resolve(String deliveryKey) {
    final path = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    return _baseUri.replace(path: path).resolve(deliveryKey);
  }

  static Uri _validateBaseUri(Uri value) {
    if (!value.isAbsolute ||
        (value.scheme != 'http' && value.scheme != 'https') ||
        value.host.isEmpty ||
        value.userInfo.isNotEmpty ||
        value.hasQuery ||
        value.hasFragment) {
      throw ArgumentError.value(
        value,
        'baseUri',
        'must be an absolute HTTP(S) URI without credentials, query, or fragment',
      );
    }
    return value;
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
        message: 'The published asset was not found.',
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
      message: 'The asset source rejected the request.',
      details: <String, Object?>{'statusCode': statusCode},
    );
  }
}
