import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/content_payload_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

const _checksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  const decoder = ContentPayloadDecoder();

  test('production decoder accepts every frozen C2 body kind', () {
    final cases = <(String, Map<String, Object?>, Type)>[
      (
        'vocabulary',
        <String, Object?>{
          'kind': 'vocabulary',
          'term': 'idempotent',
          'definition': 'Safe to repeat without changing the result.',
          'partOfSpeech': 'adjective',
          'examples': <String>['The retry operation is idempotent.'],
        },
        VocabularyBody,
      ),
      (
        'interview',
        <String, Object?>{
          'kind': 'interview',
          'prompt': 'What is dependency injection?',
          'modelAnswer': 'Dependencies are supplied externally.',
          'keyPoints': <String>['loose coupling', 'testability'],
        },
        InterviewBody,
      ),
      (
        'topic',
        <String, Object?>{
          'kind': 'topic',
          'sections': <Object?>[
            <String, Object?>{
              'heading': 'Trade-offs',
              'text': 'Prefer simple transaction boundaries first.',
            },
          ],
        },
        TopicBody,
      ),
      (
        'phrase',
        <String, Object?>{
          'kind': 'phrase',
          'phrase': 'Could you clarify the requirement?',
          'usage': 'Use when a requirement is ambiguous.',
          'examples': <String>['Could you clarify the latency target?'],
        },
        PhraseBody,
      ),
      (
        'shadowing',
        <String, Object?>{
          'kind': 'shadowing',
          'transcript': 'Validate the input. Persist the change.',
          'segments': <Object?>[
            <String, Object?>{
              'order': 0,
              'text': 'Validate the input.',
              'startMs': 0,
              'endMs': 900,
            },
            <String, Object?>{
              'order': 1,
              'text': 'Persist the change.',
              'startMs': 900,
              'endMs': 1800,
            },
          ],
        },
        ShadowingBody,
      ),
    ];

    for (final entry in cases) {
      final result = decoder.decode(_payload(entry.$1, entry.$2));
      expect(result, isA<Success<ContentPayload>>(), reason: entry.$1);
      final payload = (result as Success<ContentPayload>).value;
      expect(payload.body.runtimeType, entry.$3, reason: entry.$1);
    }
  });

  test('production decoder rejects malformed shadowing topology', () {
    final result = decoder.decode(
      _payload('shadowing', <String, Object?>{
        'kind': 'shadowing',
        'transcript': 'A B',
        'segments': <Object?>[
          <String, Object?>{
            'order': 0,
            'text': 'A',
            'startMs': 0,
            'endMs': 1000,
          },
          <String, Object?>{
            'order': 1,
            'text': 'B',
            'startMs': 900,
            'endMs': 1500,
          },
        ],
      }),
    );

    expect(result, isA<FailureResult<ContentPayload>>());
    expect(
      (result as FailureResult<ContentPayload>).failure.code,
      'CONTENT_PAYLOAD_INVALID',
    );
  });
}

Map<String, Object?> _payload(String kind, Map<String, Object?> body) {
  return <String, Object?>{
    'contentCode': 'C2_${kind.toUpperCase()}',
    'contentType': kind,
    'revision': 1,
    'checksum': _checksum,
    'title': 'C2 $kind',
    'subtitle': 'Contract qualification',
    'description': 'Typed C2 payload qualification.',
    'categoryCode': 'SOFTWARE_ENGINEERING',
    'categoryLabel': 'Software Engineering',
    'levelCode': 'B2',
    'levelLabel': 'B2',
    'minutes': 5,
    'hasAudio': kind == 'shadowing',
    'skillCodes': <String>['COMMUNICATION'],
    'body': body,
  };
}
