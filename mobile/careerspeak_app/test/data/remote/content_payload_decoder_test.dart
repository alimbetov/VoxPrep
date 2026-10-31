import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/content_payload_decoder.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _contentHash =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  const decoder = ContentPayloadDecoder();

  test('decodes an exact immutable typed learner payload revision', () {
    final result = decoder.decode(_payloadJson());

    expect(result, isA<Success<ContentPayload>>());
    final payload = (result as Success<ContentPayload>).value;
    expect(payload.ref.identity.code, 'JAVA_Q_001');
    expect(payload.ref.identity.type, ContentType.interview);
    expect(payload.ref.revision, 3);
    expect(payload.ref.checksum, _contentHash);
    expect(payload.title, 'Dependency Injection');
    expect(payload.categoryCode, 'JAVA_BACKEND');
    expect(payload.category, 'Java Backend');
    expect(payload.levelCode, 'SENIOR');
    expect(payload.level, 'Senior');
    expect(payload.minutes, 6);
    expect(payload.hasAudio, isTrue);
    expect(payload.skillCodes, <String>['SYSTEM_DESIGN', 'COMMUNICATION']);
    expect(payload.body, isA<InterviewBody>());
    final body = payload.body! as InterviewBody;
    expect(body.prompt, 'What is dependency injection?');
    expect(body.keyPoints, <String>['loose coupling', 'testability']);
  });

  test('rejects unsupported content type', () {
    final json = _payloadJson()..['contentType'] = 'unknown';

    final result = decoder.decode(json);

    expect(result, isA<FailureResult<ContentPayload>>());
    final failure = (result as FailureResult<ContentPayload>).failure;
    expect(failure.code, 'CONTENT_PAYLOAD_INVALID');
    expect(failure.details['field'], r'$.contentType');
  });

  test('rejects body kind that does not match content type', () {
    final json = _payloadJson();
    json['body'] = <String, Object?>{
      'kind': 'phrase',
      'phrase': 'Dependency injection',
      'usage': 'Architecture discussion',
      'examples': <String>['We use dependency injection.'],
    };

    final result = decoder.decode(json);

    expect(result, isA<FailureResult<ContentPayload>>());
    final failure = (result as FailureResult<ContentPayload>).failure;
    expect(failure.code, 'CONTENT_PAYLOAD_INVALID');
    expect(failure.details['field'], r'$.body.kind');
  });

  test('rejects unsupported body field fail closed', () {
    final json = _payloadJson();
    final body = json['body']! as Map<String, Object?>;
    body['debug'] = true;

    final result = decoder.decode(json);

    expect(result, isA<FailureResult<ContentPayload>>());
    final failure = (result as FailureResult<ContentPayload>).failure;
    expect(failure.details['field'], r'$.body.debug');
  });

  test('rejects duplicate skill codes', () {
    final json = _payloadJson()
      ..['skillCodes'] = <String>['COMMUNICATION', 'COMMUNICATION'];

    final result = decoder.decode(json);

    expect(result, isA<FailureResult<ContentPayload>>());
    final failure = (result as FailureResult<ContentPayload>).failure;
    expect(failure.details['field'], r'$.skillCodes');
  });

  test('rejects legacy payload without typed body', () {
    final json = _payloadJson()..remove('body');

    final result = decoder.decode(json);

    expect(result, isA<FailureResult<ContentPayload>>());
    final failure = (result as FailureResult<ContentPayload>).failure;
    expect(failure.code, 'CONTENT_PAYLOAD_INVALID');
    expect(failure.details['field'], r'$.body');
  });

  test('rejects non-stable taxonomy code', () {
    final json = _payloadJson()..['categoryCode'] = 'Java Backend';

    final result = decoder.decode(json);

    expect(result, isA<FailureResult<ContentPayload>>());
    final failure = (result as FailureResult<ContentPayload>).failure;
    expect(failure.code, 'CONTENT_PAYLOAD_INVALID');
    expect(failure.details['field'], r'$.categoryCode');
  });

  test('rejects invalid presentation payload', () {
    final json = _payloadJson()..['minutes'] = 0;

    final result = decoder.decode(json);

    expect(result, isA<FailureResult<ContentPayload>>());
    expect(
      (result as FailureResult<ContentPayload>).failure.code,
      'CONTENT_PAYLOAD_INVALID',
    );
  });
}

Map<String, Object?> _payloadJson() {
  return <String, Object?>{
    'contentCode': 'JAVA_Q_001',
    'contentType': 'interview',
    'revision': 3,
    'checksum': _contentHash,
    'title': 'Dependency Injection',
    'subtitle': 'Java Backend',
    'description': 'Explain constructor injection and its tradeoffs.',
    'categoryCode': 'JAVA_BACKEND',
    'categoryLabel': 'Java Backend',
    'levelCode': 'SENIOR',
    'levelLabel': 'Senior',
    'minutes': 6,
    'hasAudio': true,
    'skillCodes': <String>['SYSTEM_DESIGN', 'COMMUNICATION'],
    'body': <String, Object?>{
      'kind': 'interview',
      'prompt': 'What is dependency injection?',
      'modelAnswer': 'Dependencies are provided from outside the class.',
      'keyPoints': <String>['loose coupling', 'testability'],
    },
  };
}
