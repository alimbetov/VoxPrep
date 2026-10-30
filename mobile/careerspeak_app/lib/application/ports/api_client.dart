import '../result/result.dart';

enum ApiMethod { get, post, put, patch, delete }

enum ApiAuthentication { none, installation }

final class ApiRequest {
  factory ApiRequest({
    required ApiMethod method,
    required String path,
    Map<String, String> queryParameters = const <String, String>{},
    Map<String, String> headers = const <String, String>{},
    Object? jsonBody,
    ApiAuthentication authentication = ApiAuthentication.installation,
  }) {
    final normalizedPath = path.trim();
    final parsedPath = Uri.tryParse(normalizedPath);
    final invalidPath =
        normalizedPath.isEmpty ||
        !normalizedPath.startsWith('/') ||
        parsedPath == null ||
        parsedPath.hasScheme ||
        parsedPath.hasAuthority ||
        parsedPath.hasQuery ||
        parsedPath.hasFragment ||
        _hasUnsafePathSegment(normalizedPath);

    if (invalidPath) {
      throw ArgumentError.value(
        path,
        'path',
        'must be an origin-relative path without query, fragment, dot segments, or encoded separators',
      );
    }
    if (method == ApiMethod.get && jsonBody != null) {
      throw ArgumentError.value(
        jsonBody,
        'jsonBody',
        'GET requests must not contain a JSON body',
      );
    }

    return ApiRequest._(
      method: method,
      path: normalizedPath,
      queryParameters: Map<String, String>.unmodifiable(queryParameters),
      headers: Map<String, String>.unmodifiable({
        for (final entry in headers.entries)
          entry.key.toLowerCase(): entry.value,
      }),
      jsonBody: jsonBody,
      authentication: authentication,
    );
  }

  const ApiRequest._({
    required this.method,
    required this.path,
    required this.queryParameters,
    required this.headers,
    required this.jsonBody,
    required this.authentication,
  });

  final ApiMethod method;
  final String path;
  final Map<String, String> queryParameters;
  final Map<String, String> headers;
  final Object? jsonBody;
  final ApiAuthentication authentication;

  bool get isSafeRead => method == ApiMethod.get;
}

final class ApiResponse {
  factory ApiResponse({
    required int statusCode,
    required Map<String, String> headers,
    required Object? jsonBody,
    String? traceId,
  }) {
    return ApiResponse._(
      statusCode: statusCode,
      headers: Map<String, String>.unmodifiable({
        for (final entry in headers.entries)
          entry.key.toLowerCase(): entry.value,
      }),
      jsonBody: jsonBody,
      traceId: traceId,
    );
  }

  const ApiResponse._({
    required this.statusCode,
    required this.headers,
    required this.jsonBody,
    required this.traceId,
  });

  final int statusCode;
  final Map<String, String> headers;
  final Object? jsonBody;
  final String? traceId;

  String? header(String name) => headers[name.toLowerCase()];
}

abstract interface class ApiClient {
  Future<Result<ApiResponse>> send(ApiRequest request);
}

bool _hasUnsafePathSegment(String path) {
  for (final rawSegment in path.split('/')) {
    final String segment;
    try {
      segment = Uri.decodeComponent(rawSegment);
    } on FormatException {
      return true;
    }

    if (segment == '.' ||
        segment == '..' ||
        segment.contains('/') ||
        segment.contains('\\')) {
      return true;
    }
  }
  return false;
}
