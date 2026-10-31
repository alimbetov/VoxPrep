// ignore_for_file: prefer_initializing_formals

import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/localized_content_payload.dart';
import '../../application/result/result.dart';
import 'dto/localized_content_payload_dto.dart';
import 'localized_content_payload_mapper.dart';

final class LocalizedContentPayloadDecoder {
  const LocalizedContentPayloadDecoder({
    LocalizedContentPayloadMapper mapper = const LocalizedContentPayloadMapper(),
  }) : _mapper = mapper;

  final LocalizedContentPayloadMapper _mapper;

  Result<LocalizedContentPayload> decode(Object? value) {
    try {
      final object = _object(value);
      final contentCode = _string(object, 'contentCode');
      if (!_contentCodePattern.hasMatch(contentCode)) {
        throw const _LocalizedPayloadViolation(
          r'$.contentCode',
          'must be a stable business code',
        );
      }

      final contentType = _string(object, 'contentType');
      if (contentTypeFromWireName(contentType) == null) {
        throw const _LocalizedPayloadViolation(
          r'$.contentType',
          'contains an unsupported content type',
        );
      }

      final locale = _string(object, 'locale');
      if (!_localePattern.hasMatch(locale)) {
        throw const _LocalizedPayloadViolation(
          r'$.locale',
          'must be a BCP-47-compatible locale identifier',
        );
      }

      final dto = LocalizedContentPayloadDto(
        contentCode: contentCode,
        contentType: contentType,
        contentRevision: _integer(object, 'contentRevision'),
        locale: locale,
        localizationRevision: _integer(object, 'localizationRevision'),
        checksum: _string(object, 'checksum'),
        title: _optionalString(object, 'title'),
        subtitle: _optionalString(object, 'subtitle'),
        description: _optionalString(object, 'description'),
        translation: _optionalString(object, 'translation'),
        hint: _optionalString(object, 'hint'),
        explanation: _optionalString(object, 'explanation'),
      );

      return Success<LocalizedContentPayload>(_mapper.map(dto));
    } on _LocalizedPayloadViolation catch (error) {
      return FailureResult<LocalizedContentPayload>(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_PAYLOAD_INVALID',
          message: 'The server returned an invalid localized content payload.',
          details: <String, Object?>{
            'field': error.path,
            'reason': error.reason,
          },
        ),
      );
    } on ArgumentError catch (error) {
      return FailureResult<LocalizedContentPayload>(
        ApplicationFailure(
          code: 'LOCALIZED_CONTENT_PAYLOAD_INVALID',
          message: 'The server returned an invalid localized content payload.',
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
      throw const _LocalizedPayloadViolation(r'$', 'must be a JSON object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const _LocalizedPayloadViolation(
          r'$',
          'contains a non-string key',
        );
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  String _string(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      throw _LocalizedPayloadViolation(
        '\$.$key',
        'must be a non-blank string',
      );
    }
    return value.trim();
  }

  String? _optionalString(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value == null) {
      return null;
    }
    if (value is! String || value.trim().isEmpty) {
      throw _LocalizedPayloadViolation(
        '\$.$key',
        'must be null or a non-blank string',
      );
    }
    return value.trim();
  }

  int _integer(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value is! int) {
      throw _LocalizedPayloadViolation('\$.$key', 'must be an integer');
    }
    return value;
  }
}

final _contentCodePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _localePattern = RegExp(r'^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$');

final class _LocalizedPayloadViolation implements Exception {
  const _LocalizedPayloadViolation(this.path, this.reason);

  final String path;
  final String reason;
}
