import 'dart:async';

import 'package:http/http.dart' as http;

import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/asset_byte_source.dart';
import '../../application/ports/installation_credential_store.dart';
import '../../application/result/result.dart';

/// Streams learner assets exclusively through the authenticated Backend API.
///
/// Flutter never receives or resolves RustFS/S3/CDN URLs. Storage topology,
/// deliveryKey resolution and object-store credentials remain Backend-internal.
final class HttpAssetByteSource implements AssetByteSource {
  factory HttpAssetByteSource({
    required http.Client client,
    required InstallationCredentialStore credentialStore,
    required Uri baseUri,
    Duration timeout = const Duration(seconds: 20),
  }) {
    return HttpAssetByteSource._(
      client,
      credentialStore,
      _validateBaseUri(baseUri),
      _validateTimeout(timeout),
    );
  }

  const HttpAssetByteSource._(
    this._client,
    this._credentialStore,
    this._baseUri,
    this._timeout,
  );

  final http.Client _client;
  final InstallationCredentialStore _credentialStore;
  final Uri _baseUri;
  final Duration _timeout;

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    final tokenResult = await _readToken();
    if (tokenResult case FailureResult<String>(:final failure)) {
      return FailureResult(failure);
    }
    final token = (tokenResult as Success<String>).value;

    final request = http.Request('GET', _assetUri(asset.assetId))
      ..headers['accept'] = asset.mediaType
      ..headers['authorization'] = 'Bearer $token'
      ..followRedirects = false;

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
          message: 'The Backend asset request timed out.',
          retryable: true,
        ),
      );
    } on http.ClientException {
      return const FailureResult(
        ApplicationFailure(
          code: 'ASSET_OFFLINE',
          message: 'The Backend asset request could not be completed.',
          retryable: true,
        ),
      );
    }
  }

  Future<Result<String>> _readToken() async {
    try {
      final token = await _credentialStore.readInstallationToken();
      if (token == null) {
        return const FailureResult(
          ApplicationFailure(
            code: 'UNAUTHORIZED',
            message: 'Installation credential is unavailable.',
          ),
        );
      }
      return Success(token.value);
    } on Object {
      return const FailureResult(
        ApplicationFailure(
          code: 'CREDENTIAL_STORE_ERROR',
          message: 'Installation credential could not be read.',
        ),
      );
    }
  }

  Uri _assetUri(String assetId) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    final normalizedBase = _baseUri.replace(path: basePath);
    final encodedAssetId = Uri.encodeComponent(assetId);
    return normalizedBase.resolve(
      'api/v1/media/assets/$encodedAssetId/content',
    );
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
        'must be an absolute HTTP(S) Backend URI without credentials, query, or fragment',
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
    return switch (statusCode) {
      401 => const ApplicationFailure(
        code: 'INSTALLATION_UNAUTHORIZED',
        message: 'The Backend rejected the installation credential.',
      ),
      403 => const ApplicationFailure(
        code: 'MEDIA_ACCESS_FORBIDDEN',
        message: 'The Backend denied access to the requested media asset.',
      ),
      404 => const ApplicationFailure(
        code: 'ASSET_NOT_FOUND',
        message: 'The requested published asset was not found.',
      ),
      409 => const ApplicationFailure(
        code: 'ASSET_NOT_READY',
        message: 'The requested asset is not ready for delivery.',
        retryable: true,
      ),
      408 || 429 || 500 || 502 || 503 || 504 => ApplicationFailure(
        code: 'ASSET_SOURCE_UNAVAILABLE',
        message: 'The Backend asset source is temporarily unavailable.',
        retryable: true,
        details: <String, Object?>{'statusCode': statusCode},
      ),
      _ => ApplicationFailure(
        code: 'ASSET_DOWNLOAD_REJECTED',
        message: 'The Backend rejected the asset request.',
        details: <String, Object?>{'statusCode': statusCode},
      ),
    };
  }
}
