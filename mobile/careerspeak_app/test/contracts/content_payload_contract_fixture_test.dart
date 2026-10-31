import 'dart:convert';
import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/content_payload_decoder.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content payload v1 fixture remains compatible with the decoder', () {
    final fixture = jsonDecode(
      File(
        'test/contracts/fixtures/content_payload_v1.json',
      ).readAsStringSync(),
    );

    const decoder = ContentPayloadDecoder();
    final result = decoder.decode(fixture);

    expect(result, isA<Success<ContentPayload>>());
    final payload = (result as Success<ContentPayload>).value;
    expect(payload.ref.identity.code, 'JAVA_Q_001');
    expect(payload.ref.identity.type, ContentType.interview);
    expect(payload.ref.revision, 3);
    expect(payload.title, 'Dependency Injection');
    expect(payload.categoryCode, 'JAVA_BACKEND');
    expect(payload.category, 'Java Backend');
    expect(payload.levelCode, 'SENIOR');
    expect(payload.level, 'Senior');
    expect(payload.minutes, 6);
    expect(payload.hasAudio, isTrue);
  });
}
