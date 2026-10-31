import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all five C2 bodies expose their exact content type', () {
    final bodies = <TypedContentBody>[
      VocabularyBody(
        term: 'idempotent',
        definition: 'Safe to repeat without changing the result.',
        partOfSpeech: 'adjective',
        examples: const <String>['The retry endpoint is idempotent.'],
      ),
      InterviewBody(
        prompt: 'How do you design an idempotent API?',
        modelAnswer: 'Use a stable idempotency key and durable result storage.',
        keyPoints: const <String>['stable key', 'durable outcome'],
      ),
      TopicBody(
        sections: <TopicSection>[
          TopicSection(
            heading: 'Trade-offs',
            text: 'Prefer simple transaction boundaries first.',
          ),
        ],
      ),
      PhraseBody(
        phrase: 'Could you clarify the requirement?',
        usage: 'Use when a requirement is ambiguous.',
        examples: const <String>['Could you clarify the latency target?'],
      ),
      ShadowingBody(
        transcript: 'First validate the input. Then persist the change.',
        segments: <ShadowingSegment>[
          ShadowingSegment(
            order: 0,
            text: 'First validate the input.',
            startMs: 0,
            endMs: 1200,
          ),
          ShadowingSegment(
            order: 1,
            text: 'Then persist the change.',
            startMs: 1200,
            endMs: 2500,
          ),
        ],
      ),
    ];

    expect(bodies.map((body) => body.contentType), <ContentType>[
      ContentType.vocabulary,
      ContentType.interview,
      ContentType.topic,
      ContentType.phrase,
      ContentType.shadowing,
    ]);
  });

  test('typed body fields are normalized and immutable', () {
    final body = InterviewBody(
      prompt: '  Tell me about yourself.  ',
      modelAnswer: '  I am a backend engineer.  ',
      keyPoints: const <String>['  role  ', ' impact '],
    );

    expect(body.prompt, 'Tell me about yourself.');
    expect(body.modelAnswer, 'I am a backend engineer.');
    expect(body.keyPoints, <String>['role', 'impact']);
    expect(() => body.keyPoints.add('extra'), throwsUnsupportedError);
  });

  test('shadowing rejects incomplete or overlapping timing', () {
    expect(
      () => ShadowingSegment(order: 0, text: 'A', startMs: 0),
      throwsArgumentError,
    );

    expect(
      () => ShadowingBody(
        transcript: 'A B',
        segments: <ShadowingSegment>[
          ShadowingSegment(order: 0, text: 'A', startMs: 0, endMs: 1000),
          ShadowingSegment(order: 1, text: 'B', startMs: 900, endMs: 1500),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('typed bodies reject empty required collections', () {
    expect(
      () => VocabularyBody(
        term: 'term',
        definition: 'definition',
        examples: const <String>[],
      ),
      throwsArgumentError,
    );
    expect(
      () => TopicBody(sections: const <TopicSection>[]),
      throwsArgumentError,
    );
  });
}
