import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C2 component contract freezes typed bodies and small catalogues', () {
    final contract = File('../../contracts/c2-content-catalog-v1.yaml');
    expect(contract.existsSync(), isTrue);

    final source = contract.readAsStringSync();
    for (final requiredFragment in <String>[
      'TypedContentPayload:',
      'ContentBody:',
      'VocabularyBody:',
      'InterviewBody:',
      'TopicBody:',
      'PhraseBody:',
      'ShadowingBody:',
      'LearningGoal:',
      'LearningTrack:',
      'LearningCollection:',
      'Category:',
      'Level:',
      'Skill:',
      'SupportedLocale:',
      'TtsVoice:',
      'PracticeTestRevisionRef:',
      'propertyName: kind',
      'const: vocabulary',
      'const: interview',
      'const: topic',
      'const: phrase',
      'const: shadowing',
    ]) {
      expect(
        source,
        contains(requiredFragment),
        reason: 'Missing C2 contract fragment: $requiredFragment',
      );
    }

    expect(source, isNot(contains('LearningActivity:')));
    expect(source, isNot(contains('workerModelPath')));
    expect(source, isNot(contains('rustfsKey')));
  });

  test('C2 checksum contract freezes one RFC 8785 hashing rule', () {
    final document = File(
      '../../docs/backend/C2_TYPED_CONTENT_CATALOG_CONTRACT.md',
    );
    expect(document.existsSync(), isTrue);

    final source = document.readAsStringSync();
    expect(source, contains('RFC 8785 JSON Canonicalization Scheme'));
    expect(source, contains('top-level `checksum` member omitted'));
    expect(source, contains('nested ref checksums      included normally'));
    expect(source, contains('publication input must be NFC-normalized'));
  });
}
