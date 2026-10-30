import 'dto/api_error_dto.dart';

final class ApiErrorDecoder {
  const ApiErrorDecoder();

  ApiErrorDto decode(Object? value) {
    final object = value is Map ? value : const <Object?, Object?>{};
    return ApiErrorDto(
      code: _nonBlankString(object['code']),
      message: _nonBlankString(object['message']),
      traceId: _nonBlankString(object['traceId']),
      details: _details(object['details']),
    );
  }

  String? _nonBlankString(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  Map<String, Object?> _details(Object? value) {
    if (value is! Map) return const <String, Object?>{};
    return Map<String, Object?>.unmodifiable(
      value.map((key, detail) => MapEntry(key.toString(), detail)),
    );
  }
}
