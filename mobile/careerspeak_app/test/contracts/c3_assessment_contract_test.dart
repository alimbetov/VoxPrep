import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C3 contract freezes exact assessment revisions and scoring', () {
    final contract = File('../../contracts/c3-assessment-v1.yaml');
    expect(contract.existsSync(), isTrue);

    final source = contract.readAsStringSync();
    for (final requiredFragment in <String>[
      '/api/v1/assessment/practice-tests/{practiceTestCode}/revisions/{revision}:',
      '/api/v1/assessment/questions/{questionCode}/revisions/{revision}:',
      'PracticeTestRevision:',
      'QuestionRevision:',
      'QuestionRevisionRef:',
      'TestQuestionRef:',
      'SingleChoiceQuestionBody:',
      'passingScoreBasisPoints:',
      'correctOptionIndex:',
      'skillCode:',
      'explanation:',
      'scoreBasisPoints:',
      'const: singleChoice',
    ]) {
      expect(
        source,
        contains(requiredFragment),
        reason: 'Missing C3 contract fragment: $requiredFragment',
      );
    }

    expect(source, isNot(contains('freeText')));
    expect(source, isNot(contains('LearningActivity')));
    expect(source, isNot(contains('recommendation')));
  });

  test('C3 scoring contract explicitly avoids floating-point semantics', () {
    final document = File('../../docs/backend/C3_ASSESSMENT_CONTRACT.md');
    expect(document.existsSync(), isTrue);

    final source = document.readAsStringSync();
    expect(source, contains('integer basis points only'));
    expect(source, contains('integer floor division'));
    expect(source, contains('newer QuestionRevision'));
    expect(source, contains('Missing exact `QuestionRevision`'));
  });
}
