import 'dart:convert';
import 'dart:io';

import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/api_error_decoder.dart';
import 'package:careerspeak_app/data/remote/installation_registration_decoder.dart';
import 'package:careerspeak_app/data/remote/installation_registration_mapper.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('api error fixture decodes into the common wire envelope', () {
    const decoder = ApiErrorDecoder();

    final error = decoder.decode(_fixture('api_error_v1.json'));

    expect(error.code, 'CONTENT_NOT_FOUND');
    expect(error.message, 'Content was not found');
    expect(error.traceId, 'trace-001');
    expect(error.details['contentCode'], 'JAVA_Q_001');
  });

  test('installation registration request matches the shared fixture', () {
    const mapper = InstallationRegistrationMapper();

    final request = mapper.request(InstallationId('installation-123'));

    expect(request.toJson(), _fixture('installation_registration_request_v1.json'));
  });

  test('installation registration response maps to a domain token', () {
    const decoder = InstallationRegistrationDecoder();

    final result = decoder.decode(
      _fixture('installation_registration_response_v1.json'),
    );

    expect(result, isA<Success<InstallationToken>>());
    final token = (result as Success<InstallationToken>).value;
    expect(token.value, 'token-abc-123');
  });

  test('installation registration rejects a missing token', () {
    const decoder = InstallationRegistrationDecoder();

    final result = decoder.decode(<String, Object?>{});

    expect(result, isA<FailureResult<InstallationToken>>());
    final failure = (result as FailureResult<InstallationToken>).failure;
    expect(failure.code, 'INSTALLATION_REGISTRATION_RESPONSE_INVALID');
    expect(failure.details['field'], r'$.installationToken');
  });
}

Object? _fixture(String name) {
  return jsonDecode(
    File('test/contracts/fixtures/$name').readAsStringSync(),
  );
}
