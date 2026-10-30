import '../../domain/practice_test.dart';
import '../query/page.dart';
import '../query/practice_test_query.dart';
import '../result/result.dart';

abstract interface class PracticeTestRepository {
  Stream<Result<Page<PracticeTestSummary>>> watchTests(PracticeTestQuery query);

  Future<Result<PracticeTest?>> getByCode(String code);
}
