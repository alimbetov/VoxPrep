import 'package:careerspeak_app/application/content_delivery/content_audio_policy.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interview exposes independent question and sample-answer roles', () {
    final policy = ContentAudioPolicy.forType(ContentType.interview);

    expect(policy.map((entry) => entry.role), <ContentAudioRole>[
      ContentAudioRole.question,
      ContentAudioRole.sampleAnswer,
    ]);
    expect(
      policy.map((entry) => entry.requirement),
      everyElement(AudioRequirement.recommended),
    );
  });

  test('shadowing requires its dedicated audio role', () {
    expect(
      ContentAudioPolicy.requiredRoles(ContentType.shadowing),
      <ContentAudioRole>[ContentAudioRole.shadowing],
    );
  });

  test('optional and recommended roles match the product policy', () {
    expect(
      ContentAudioPolicy.forType(ContentType.vocabulary).single.requirement,
      AudioRequirement.optional,
    );
    expect(
      ContentAudioPolicy.forType(ContentType.phrase).single.requirement,
      AudioRequirement.recommended,
    );
    expect(
      ContentAudioPolicy.forType(ContentType.topic).single.requirement,
      AudioRequirement.optional,
    );
  });

  test('audio roles are content-type scoped', () {
    expect(
      ContentAudioPolicy.allows(
        ContentType.interview,
        ContentAudioRole.sampleAnswer,
      ),
      isTrue,
    );
    expect(
      ContentAudioPolicy.allows(
        ContentType.topic,
        ContentAudioRole.sampleAnswer,
      ),
      isFalse,
    );
  });

  test('wire role lookup is exact and fail-closed', () {
    expect(
      ContentAudioRole.fromWireName('question'),
      ContentAudioRole.question,
    );
    expect(
      ContentAudioRole.fromWireName('sampleAnswer'),
      ContentAudioRole.sampleAnswer,
    );
    expect(ContentAudioRole.fromWireName('QUESTION'), isNull);
    expect(ContentAudioRole.fromWireName('promptAudio'), isNull);
  });
}
