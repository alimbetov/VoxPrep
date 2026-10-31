// ignore_for_file: prefer_initializing_formals

import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/content_payload.dart';
import '../../application/result/result.dart';
import 'content_payload_mapper.dart';
import 'dto/content_payload_dto.dart';

final class ContentPayloadDecoder {
  const ContentPayloadDecoder({
    ContentPayloadMapper mapper = const ContentPayloadMapper(),
  }) : _mapper = mapper;

  final ContentPayloadMapper _mapper;

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
      if (contentTypeFromWireName(typeName) == null) {
        throw const _PayloadViolation(
          r'$.contentType',
          'contains an unsupported content type',
        );
      }

      final categoryCode = _string(object, 'categoryCode');
      if (!_stableCodePattern.hasMatch(categoryCode)) {
        throw const _PayloadViolation(
          r'$.categoryCode',
          'must be an uppercase stable business code',
        );
      }
      final levelCode = _string(object, 'levelCode');
      if (!_stableCodePattern.hasMatch(levelCode)) {
        throw const _PayloadViolation(
          r'$.levelCode',
          'must be an uppercase stable business code',
        );
      }

      final dto = ContentPayloadDto(
        contentCode: contentCode,
        contentType: typeName,
        revision: _integer(object, 'revision'),
        checksum: _string(object, 'checksum'),
        title: _string(object, 'title'),
        subtitle: _string(object, 'subtitle'),
        description: _string(object, 'description'),
        categoryCode: categoryCode,
        categoryLabel: _string(object, 'categoryLabel'),
        levelCode: levelCode,
        levelLabel: _string(object, 'levelLabel'),
        minutes: _integer(object, 'minutes'),
        hasAudio: _boolean(object, 'hasAudio'),
      );

      return Success<ContentPayload>(_mapper.map(dto));
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
final _stableCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9._-]*$');

final class _PayloadViolation implements Exception {
  const _PayloadViolation(this.path, this.reason);

  final String path;
  final String reason;
}
