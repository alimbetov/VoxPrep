import '../../domain/mock_practice_test.dart';

abstract interface class PracticeTestRepository {
  List<MockPracticeTest> get all;

  MockPracticeTest? byCode(String code);
}
