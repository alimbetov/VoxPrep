import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/content_payload.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';

final class ContentPayloadDecoder {
  const ContentPayloadDecoder();

  Result<ContentPayload> decode(Object? value) {
    try {
      final object = _object(value);
      final contentCode = _string(object, 'contentCode');
      if (!_contentCodePattern.hasMatch(contentCode)) {
        throw const _PayloadViolation(
          r'$.contentCode',
          'must be a stable business code',
        );
      }

      final typeName = _string(object, 'contentType');
      final type = contentTypeFromWireName(typeName);
      if (type == null) {
        throw const _PayloadViolation(
          r'$.contentType',
          'contains an unsupported content type',
        );
      }

      final ref = ContentPayloadRef(
        identity: ContentIdentity(code: contentCode, type: type),
        revision: _integer(object, 'revision'),
        checksum: _string(object, 'checksum'),
      );
      return Success<ContentPayload>(
        ContentPayload(
          ref: ref,
          title: _string(object, 'title'),
          subtitle: _string(object, 'subtitle'),
          description: _string(object, 'description'),
          category: _string(object, 'category'),
          level: _string(object, 'level'),
          minutes: _integer(object, 'minutes'),
          hasAudio: _boolean(object, 'hasAudio'),
        ),
      );
    } on _PayloadViolation catch (error) {
      return FailureResult<ContentPayload>(
        ApplicationFailure(
          code: 'CONTENT_PAYLOAD_INVALID',
          message: 'The server returned an invalid content payload.',
          details: <String, Object?>{
            'field': error.path,
            'reason': error.reason,
          },
        ),
      );
    } on ArgumentError catch (error) {
      return FailureResult<ContentPayload>(
        ApplicationFailure(
          code: 'CONTENT_PAYLOAD_INVALID',
          message: 'The server returned an invalid content payload.',
          details: <String, Object?>{
            if (error.name != null) 'field': error.name,
            if (error.message != null) 'reason': error.message.toString(),
          },
        ),
      );
    }
  }

  Map<String, Object?> _object(Object? value) {
    if (value is! Map) {
      throw const _PayloadViolation(r'$', 'must be a JSON object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const _PayloadViolation(r'$', 'contains a non-string key');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  String _string(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      throw _PayloadViolation('\$.$key', 'must be a non-blank string');
    }
    return value.trim();
  }

  int _integer(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value is! int) {
      throw _PayloadViolation('\$.$key', 'must be an integer');
    }
    return value;
  }

  bool _boolean(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value is! bool) {
      throw _PayloadViolation('\$.$key', 'must be a boolean');
    }
    return value;
  }
}

final _contentCodePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');

final class _PayloadViolation implements Exception {
  const _PayloadViolation(this.path, this.reason);

  final String path;
  final String reason;
}
