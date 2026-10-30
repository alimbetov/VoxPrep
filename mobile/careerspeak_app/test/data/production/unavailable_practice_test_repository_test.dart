import 'package:careerspeak_app/application/query/practice_test_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/production/unavailable_practice_test_repository.dart';
import 'package:careerspeak_app/domain/practice_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repository = UnavailablePracticeTestRepository();

  test('catalog fails explicitly instead of exposing mock tests', () async {
    final result = await repository
        .watchTests(const PracticeTestQuery())
        .first;

    expect(result, isA<FailureResult>());
    expect(
      (result as FailureResult).failure.code,
      'ASSESSMENT_UNAVAILABLE',
    );
  });

  test('detail fails explicitly instead of exposing mock questions', () async {
    final result = await repository.getByCode('MOCK_TEST');

    expect(result, isA<FailureResult<PracticeTest?>>());
    expect(
      (result as FailureResult<PracticeTest?>).failure.code,
      'ASSESSMENT_UNAVAILABLE',
    );
  });
}
