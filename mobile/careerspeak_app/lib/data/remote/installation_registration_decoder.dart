import '../../application/result/result.dart';
import '../../domain/installation_credentials.dart';
import 'dto/installation_registration_dto.dart';
import 'installation_registration_mapper.dart';

final class InstallationRegistrationDecoder {
  const InstallationRegistrationDecoder({
    InstallationRegistrationMapper mapper = const InstallationRegistrationMapper(),
  }) : _mapper = mapper;

  final InstallationRegistrationMapper _mapper;

  Result<InstallationToken> decode(Object? value) {
    try {
      final object = _object(value);
      final dto = InstallationRegistrationResponseDto(
        installationToken: _string(object, 'installationToken'),
      );
      return Success<InstallationToken>(_mapper.response(dto));
    } on _RegistrationViolation catch (error) {
      return FailureResult<InstallationToken>(
        ApplicationFailure(
          code: 'INSTALLATION_REGISTRATION_RESPONSE_INVALID',
          message: 'The server returned an invalid installation registration response.',
          details: <String, Object?>{
            'field': error.path,
            'reason': error.reason,
          },
        ),
      );
    } on ArgumentError catch (error) {
      return FailureResult<InstallationToken>(
        ApplicationFailure(
          code: 'INSTALLATION_REGISTRATION_RESPONSE_INVALID',
          message: 'The server returned an invalid installation registration response.',
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
      throw const _RegistrationViolation(r'$', 'must be a JSON object');
    }
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const _RegistrationViolation(r'$', 'contains a non-string key');
      }
      result[entry.key as String] = entry.value;
    }
    return result;
  }

  String _string(Map<String, Object?> object, String key) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      throw _RegistrationViolation('\$.$key', 'must be a non-blank string');
    }
    return value.trim();
  }
}

final class _RegistrationViolation implements Exception {
  const _RegistrationViolation(this.path, this.reason);

  final String path;
  final String reason;
}
