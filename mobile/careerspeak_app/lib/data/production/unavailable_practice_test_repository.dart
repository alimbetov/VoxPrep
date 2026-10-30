import '../../application/ports/practice_test_repository.dart';
import '../../application/query/page.dart';
import '../../application/query/practice_test_query.dart';
import '../../application/result/result.dart';
import '../../domain/practice_test.dart';

final class UnavailablePracticeTestRepository
    implements PracticeTestRepository {
  const UnavailablePracticeTestRepository();

  static const ApplicationFailure _unavailable = ApplicationFailure(
    code: 'ASSESSMENT_UNAVAILABLE',
    message: 'Assessment content is not available in production yet.',
  );

  @override
  Stream<Result<Page<PracticeTestSummary>>> watchTests(
    PracticeTestQuery query,
  ) {
    return const Stream<Result<Page<PracticeTestSummary>>>.value(
      FailureResult<Page<PracticeTestSummary>>(_unavailable),
    );
  }

  @override
  Future<Result<PracticeTest?>> getByCode(String code) async {
    return const FailureResult<PracticeTest?>(_unavailable);
  }
}
