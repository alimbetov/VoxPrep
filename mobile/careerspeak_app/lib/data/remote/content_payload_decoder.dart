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
      final object = _object(value, r'$');
      _requireExactKeys(object, _payloadKeys, r'$');

      final contentCode = _string(object, 'contentCode', r'$');
      if (!_contentCodePattern.hasMatch(contentCode)) {
        throw const _PayloadViolation(
          r'$.contentCode',
          'must be a stable business code',
        );
      }

      final typeName = _string(object, 'contentType', r'$');
      if (contentTypeFromWireName(typeName) == null) {
        throw const _PayloadViolation(
          r'$.contentType',
          'contains an unsupported content type',
        );
      }

      final categoryCode = _stableCode(object, 'categoryCode', r'$');
      final levelCode = _stableCode(object, 'levelCode', r'$');
      final skillCodes = _stableCodeList(object, 'skillCodes', r'$');
      final body = _body(object['body'], typeName);

      final dto = ContentPayloadDto(
        contentCode: contentCode,
        contentType: typeName,
        revision: _integer(object, 'revision', r'$'),
        checksum: _string(object, 'checksum', r'$'),
        title: _string(object, 'title', r'$'),
        subtitle: _string(object, 'subtitle', r'$'),
        description: _string(object, 'description', r'$'),
        categoryCode: categoryCode,
        categoryLabel: _string(object, 'categoryLabel', r'$'),
        levelCode: levelCode,
        levelLabel: _string(object, 'levelLabel', r'$'),
        minutes: _integer(object, 'minutes', r'$'),
        hasAudio: _boolean(object, 'hasAudio', r'$'),
        skillCodes: skillCodes,
        body: body,
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

  ContentBodyDto _body(Object? value, String expectedKind) {
    final object = _object(value, r'$.body');
    final kind = _string(object, 'kind', r'$.body');
    if (kind != expectedKind) {
      throw _PayloadViolation(
        r'$.body.kind',
        'must match contentType $expectedKind',
      );
    }

    switch (kind) {
      case 'vocabulary':
        _requireExactKeys(object, _vocabularyKeys, r'$.body');
        return VocabularyBodyDto(
          term: _string(object, 'term', r'$.body'),
          definition: _string(object, 'definition', r'$.body'),
          partOfSpeech: _optionalString(object, 'partOfSpeech', r'$.body'),
          examples: _nonBlankStringList(object, 'examples', r'$.body'),
        );
      case 'interview':
        _requireExactKeys(object, _interviewKeys, r'$.body');
        return InterviewBodyDto(
          prompt: _string(object, 'prompt', r'$.body'),
          modelAnswer: _string(object, 'modelAnswer', r'$.body'),
          keyPoints: _nonBlankStringList(object, 'keyPoints', r'$.body'),
        );
      case 'topic':
        _requireExactKeys(object, _topicKeys, r'$.body');
        return TopicBodyDto(
          sections: _objectList(object, 'sections', r'$.body').indexed
              .map((entry) {
                final path =
                    r'$.body.sections['
                    '${entry.$1}]';
                final section = entry.$2;
                _requireExactKeys(section, _topicSectionKeys, path);
                return TopicSectionDto(
                  heading: _string(section, 'heading', path),
                  text: _string(section, 'text', path),
                );
              })
              .toList(growable: false),
        );
      case 'phrase':
        _requireExactKeys(object, _phraseKeys, r'$.body');
        return PhraseBodyDto(
          phrase: _string(object, 'phrase', r'$.body'),
          usage: _string(object, 'usage', r'$.body'),
          examples: _nonBlankStringList(object, 'examples', r'$.body'),
        );
      case 'shadowing':
        _requireExactKeys(object, _shadowingKeys, r'$.body');
        return ShadowingBodyDto(
          transcript: _string(object, 'transcript', r'$.body'),
          segments: _objectList(object, 'segments', r'$.body').indexed
              .map((entry) {
                final path =
                    r'$.body.segments['
                    '${entry.$1}]';
                final segment = entry.$2;
                _requireExactKeys(segment, _shadowingSegmentKeys, path);
                return ShadowingSegmentDto(
                  order: _integer(segment, 'order', path),
                  text: _string(segment, 'text', path),
                  startMs: _optionalInteger(segment, 'startMs', path),
                  endMs: _optionalInteger(segment, 'endMs', path),
                );
              })
              .toList(growable: false),
        );
      default:
        throw const _PayloadViolation(
          r'$.body.kind',
          'contains an unsupported body kind',
        );
    }
  }

  Map<String, Object?> _object(Object? value, String path) {
    if (value is! Map) {
      throw _PayloadViolation(path, 'must be a JSON object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw _PayloadViolation(path, 'contains a non-string key');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  List<Map<String, Object?>> _objectList(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final value = object[key];
    if (value is! List || value.isEmpty) {
      throw _PayloadViolation('$path.$key', 'must be a non-empty array');
    }
    return value.indexed
        .map((entry) => _object(entry.$2, '$path.$key[${entry.$1}]'))
        .toList(growable: false);
  }

  String _string(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      throw _PayloadViolation('$path.$key', 'must be a non-blank string');
    }
    return value.trim();
  }

  String? _optionalString(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final value = object[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw _PayloadViolation(
        '$path.$key',
        'must be null or a non-blank string',
      );
    }
    return value.trim();
  }

  int _integer(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! int) {
      throw _PayloadViolation('$path.$key', 'must be an integer');
    }
    return value;
  }

  int? _optionalInteger(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value == null) {
      return null;
    }
    if (value is! int) {
      throw _PayloadViolation('$path.$key', 'must be null or an integer');
    }
    return value;
  }

  bool _boolean(Map<String, Object?> object, String key, String path) {
    final value = object[key];
    if (value is! bool) {
      throw _PayloadViolation('$path.$key', 'must be a boolean');
    }
    return value;
  }

  String _stableCode(Map<String, Object?> object, String key, String path) {
    final value = _string(object, key, path);
    if (!_stableCodePattern.hasMatch(value)) {
      throw _PayloadViolation(
        '$path.$key',
        'must be an uppercase stable business code',
      );
    }
    return value;
  }

  List<String> _stableCodeList(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final value = object[key];
    if (value is! List) {
      throw _PayloadViolation('$path.$key', 'must be an array');
    }
    final result = <String>[];
    final seen = <String>{};
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! String || !_stableCodePattern.hasMatch(item.trim())) {
        throw _PayloadViolation(
          '$path.$key[$index]',
          'must be an uppercase stable business code',
        );
      }
      final normalized = item.trim();
      if (!seen.add(normalized)) {
        throw _PayloadViolation('$path.$key', 'must not contain duplicates');
      }
      result.add(normalized);
    }
    return List<String>.unmodifiable(result);
  }

  List<String> _nonBlankStringList(
    Map<String, Object?> object,
    String key,
    String path,
  ) {
    final value = object[key];
    if (value is! List || value.isEmpty) {
      throw _PayloadViolation('$path.$key', 'must be a non-empty array');
    }
    final result = <String>[];
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! String || item.trim().isEmpty) {
        throw _PayloadViolation(
          '$path.$key[$index]',
          'must be a non-blank string',
        );
      }
      result.add(item.trim());
    }
    return List<String>.unmodifiable(result);
  }

  void _requireExactKeys(
    Map<String, Object?> object,
    Set<String> allowed,
    String path,
  ) {
    for (final key in object.keys) {
      if (!allowed.contains(key)) {
        throw _PayloadViolation('$path.$key', 'is not a supported field');
      }
    }
  }
}

const _payloadKeys = <String>{
  'contentCode',
  'contentType',
  'revision',
  'checksum',
  'title',
  'subtitle',
  'description',
  'categoryCode',
  'categoryLabel',
  'levelCode',
  'levelLabel',
  'minutes',
  'hasAudio',
  'skillCodes',
  'body',
};
const _vocabularyKeys = <String>{
  'kind',
  'term',
  'definition',
  'partOfSpeech',
  'examples',
};
const _interviewKeys = <String>{'kind', 'prompt', 'modelAnswer', 'keyPoints'};
const _topicKeys = <String>{'kind', 'sections'};
const _topicSectionKeys = <String>{'heading', 'text'};
const _phraseKeys = <String>{'kind', 'phrase', 'usage', 'examples'};
const _shadowingKeys = <String>{'kind', 'transcript', 'segments'};
const _shadowingSegmentKeys = <String>{'order', 'text', 'startMs', 'endMs'};

final _contentCodePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _stableCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9._-]*$');

final class _PayloadViolation implements Exception {
  const _PayloadViolation(this.path, this.reason);

  final String path;
  final String reason;
}
