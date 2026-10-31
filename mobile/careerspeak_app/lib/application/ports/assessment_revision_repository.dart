import '../../domain/assessment_bundle.dart';
import '../result/result.dart';

abstract interface class AssessmentRevisionRepository {
  Future<Result<AssessmentRevisionBundle?>> readBundle({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  });

  Future<Result<AssessmentRevisionBundle>> saveBundle(
    AssessmentRevisionBundle bundle,
  );
}
