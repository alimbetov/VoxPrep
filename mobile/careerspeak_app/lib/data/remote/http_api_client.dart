import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../application/ports/api_client.dart';
import '../../application/ports/installation_credential_store.dart';
import '../../application/result/result.dart';
import '../../domain/installation_credentials.dart';
import 'api_error_decoder.dart';

typedef ApiDelay = Future<void> Function(Duration duration);

const _managedRequestHeaders = <String>{
  'accept',
  'authorization',
  'connection',
  'content-length',
  'content-type',
  'cookie',
  'host',
  'transfer-encoding',
};

final class HttpApiClient implements ApiClient {
  factory HttpApiClient({
    required http.Client client,
    required InstallationCredentialStore credentialStore,
    required Uri baseUri,
    Duration requestTimeout = const Duration(seconds: 10),
    int maxGetAttempts = 3,
    ApiDelay? delay,
    ApiErrorDecoder errorDecoder = const ApiErrorDecoder(),
  }) {
    return HttpApiClient._(
      client,
      credentialStore,
      _validateBaseUri(baseUri),
      _validateTimeout(requestTimeout),
      _validateMaxAttempts(maxGetAttempts),
      delay ?? Future<void>.delayed,
      errorDecoder,
    );
  }

  HttpApiClient._(
    this._client,
    this._credentialStore,
    this._baseUri,
    this._requestTimeout,
    this._maxGetAttempts,
    this._delay,
    this._errorDecoder,
  );

  final http.Client _client;
  final InstallationCredentialStore _credentialStore;
  final Uri _baseUri;
  final Duration _requestTimeout;
  final int _maxGetAttempts;
  final ApiDelay _delay;
  final ApiErrorDecoder _errorDecoder;

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    final maxAttempts = request.isSafeRead ? _maxGetAttempts : 1;

    for (var attempt = 1; attempt <= maxAttempts; attempt += 1) {
      final result = await _sendOnce(request);
      if (result is Success<ApiResponse>) {
        return result;
      }

      final failure = (result as FailureResult<ApiResponse>).failure;
      if (!failure.retryable || attempt == maxAttempts) {
        return result;
      }

      await _delay(_retryDelay(attempt));
    }

    throw StateError('HTTP retry loop exited unexpectedly.');
  }

  Future<Result<ApiResponse>> _sendOnce(ApiRequest request) async {
    final headers = <String, String>{
      'accept': 'application/json',
      for (final entry in request.headers.entries)
        if (!_managedRequestHeaders.contains(entry.key)) entry.key: entry.value,
    };

    if (request.authentication == ApiAuthentication.installation) {
      final InstallationToken? token;
      try {
        token = await _credentialStore.readInstallationToken();
      } on Object {
        return const FailureResult<ApiResponse>(
          ApplicationFailure(
            code: 'CREDENTIAL_STORE_ERROR',
            message: 'Installation credential could not be read.',
          ),
        );
      }

      if (token == null) {
        return const FailureResult<ApiResponse>(
          ApplicationFailure(
            code: 'UNAUTHORIZED',
            message: 'Installation credential is unavailable.',
          ),
        );
      }
      headers['authorization'] = 'Bearer ${token.value}';
    }

    final String? encodedBody;
    if (request.jsonBody == null) {
      encodedBody = null;
    } else {
      try {
        encodedBody = jsonEncode(request.jsonBody);
      } on Object {
        return const FailureResult<ApiResponse>(
          ApplicationFailure(
            code: 'REQUEST_ENCODING_FAILED',
            message: 'The request body could not be encoded as JSON.',
          ),
        );
      }
    }

    if (encodedBody != null) {
      headers['content-type'] = 'application/json; charset=utf-8';
    }

    final httpRequest = http.Request(
      _wireMethod(request.method),
      _resolveUri(request),
    )..headers.addAll(headers);

    if (encodedBody != null) {
      httpRequest.body = encodedBody;
    }

    try {
      final response = await _client
          .send(httpRequest)
          .then(http.Response.fromStream)
          .timeout(_requestTimeout);
      return _mapResponse(response);
    } on TimeoutException {
      return const FailureResult<ApiResponse>(
        ApplicationFailure(
          code: 'TIMEOUT',
          message: 'The request timed out.',
          retryable: true,
        ),
      );
    } on http.ClientException {
      return const FailureResult<ApiResponse>(
        ApplicationFailure(
          code: 'OFFLINE',
          message: 'The network request could not be completed.',
          retryable: true,
        ),
      );
    }
  }

  Result<ApiResponse> _mapResponse(http.Response response) {
    final headers = <String, String>{
      for (final entry in response.headers.entries)
        entry.key.toLowerCase(): entry.value,
    };
    final success = _isSuccess(response.statusCode);

    Object? decodedBody;
    if (response.body.trim().isNotEmpty) {
      try {
        decodedBody = jsonDecode(response.body);
      } on FormatException {
        if (success) {
          return FailureResult<ApiResponse>(
            ApplicationFailure(
              code: 'API_RESPONSE_INVALID',
              message: 'The server returned an invalid JSON response.',
              traceId: headers['x-trace-id'],
            ),
          );
        }
      }
    }

    final traceId = _traceId(decodedBody, headers);
    if (success) {
      return Success<ApiResponse>(
        ApiResponse(
          statusCode: response.statusCode,
          headers: headers,
          jsonBody: decodedBody,
          traceId: traceId,
        ),
      );
    }

    return FailureResult<ApiResponse>(
      _failureFromResponse(
        statusCode: response.statusCode,
        decodedBody: decodedBody,
        traceId: traceId,
      ),
    );
  }

  ApplicationFailure _failureFromResponse({
    required int statusCode,
    required Object? decodedBody,
    required String? traceId,
  }) {
    final envelope = _errorDecoder.decode(decodedBody);
    final backendCode = envelope.code;
    final code = switch (statusCode) {
      401 => 'UNAUTHORIZED',
      403 => 'FORBIDDEN',
      _ => backendCode ?? _fallbackCode(statusCode),
    };
    final message = envelope.message ?? _fallbackMessage(statusCode);
    final details = <String, Object?>{
      ...envelope.details,
      if ((statusCode == 401 || statusCode == 403) &&
          backendCode != null &&
          backendCode != code)
        'backendCode': backendCode,
    };

    return ApplicationFailure(
      code: code,
      message: message,
      retryable: _retryableStatus(statusCode),
      traceId: traceId ?? envelope.traceId,
      details: Map<String, Object?>.unmodifiable(details),
    );
  }

  Uri _resolveUri(ApiRequest request) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    final normalizedBase = _baseUri.replace(path: basePath);
    final resolved = normalizedBase.resolve(request.path.substring(1));

    if (request.queryParameters.isEmpty) {
      return resolved;
    }
    return resolved.replace(queryParameters: request.queryParameters);
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
      throw ArgumentError.value(value, 'requestTimeout', 'must be positive');
    }
    return value;
  }

  static int _validateMaxAttempts(int value) {
    if (value < 1) {
      throw ArgumentError.value(value, 'maxGetAttempts', 'must be at least 1');
    }
    return value;
  }

  static String _wireMethod(ApiMethod method) => switch (method) {
    ApiMethod.get => 'GET',
    ApiMethod.post => 'POST',
    ApiMethod.put => 'PUT',
    ApiMethod.patch => 'PATCH',
    ApiMethod.delete => 'DELETE',
  };

  static bool _isSuccess(int statusCode) =>
      (statusCode >= 200 && statusCode < 300) || statusCode == 304;

  static bool _retryableStatus(int statusCode) =>
      statusCode == 408 ||
      statusCode == 429 ||
      statusCode == 500 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;

  static Duration _retryDelay(int completedAttempt) {
    final multiplier = 1 << (completedAttempt - 1);
    return Duration(milliseconds: 200 * multiplier);
  }

  static String _fallbackCode(int statusCode) => switch (statusCode) {
    401 => 'UNAUTHORIZED',
    403 => 'FORBIDDEN',
    404 => 'NOT_FOUND',
    408 => 'TIMEOUT',
    429 => 'RATE_LIMITED',
    >= 500 => 'SERVER_ERROR',
    _ => 'HTTP_ERROR',
  };

  static String _fallbackMessage(int statusCode) => switch (statusCode) {
    401 => 'The installation credential was rejected.',
    403 => 'The request is forbidden.',
    404 => 'The requested resource was not found.',
    408 => 'The server timed out while processing the request.',
    429 => 'Too many requests were sent.',
    >= 500 => 'The server could not complete the request.',
    _ => 'The server rejected the request.',
  };

  static String? _traceId(Object? body, Map<String, String> headers) {
    final headerTraceId = _nonBlankString(headers['x-trace-id']);
    if (headerTraceId != null) {
      return headerTraceId;
    }
    if (body is Map) {
      return _nonBlankString(body['traceId']);
    }
    return null;
  }

  static String? _nonBlankString(Object? value) {
    if (value is! String) {
      return null;
    }
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }
}
