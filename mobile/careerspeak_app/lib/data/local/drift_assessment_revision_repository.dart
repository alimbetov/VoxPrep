import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/ports/assessment_revision_repository.dart';
import '../../application/result/result.dart';
import '../../domain/assessment.dart';
import '../../domain/assessment_bundle.dart';
import 'database/careerspeak_database.dart' as db;

final class DriftAssessmentRevisionRepository
    implements AssessmentRevisionRepository {
  const DriftAssessmentRevisionRepository(this._database);

  final db.CareerSpeakDatabase _database;

  @override
  Future<Result<AssessmentRevisionBundle?>> readBundle({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) async {
    try {
      final normalizedCode = practiceTestCode.trim();
      if (!_businessCodePattern.hasMatch(normalizedCode) ||
          revision < 1 ||
          !_sha256Pattern.hasMatch(checksum)) {
        return const FailureResult<AssessmentRevisionBundle?>(
          ApplicationFailure(
            code: 'ASSESSMENT_TARGET_INVALID',
            message: 'The requested assessment revision identity is invalid.',
          ),
        );
      }

      final testRow =
          await (_database.select(_database.practiceTestRevisionReads)..where(
                (row) =>
                    row.practiceTestCode.equals(normalizedCode) &
                    row.revision.equals(revision),
              ))
              .getSingleOrNull();
      if (testRow == null) {
        return const Success<AssessmentRevisionBundle?>(null);
      }
      if (testRow.checksum != checksum) {
        return FailureResult<AssessmentRevisionBundle?>(
          _checksumConflict(
            code: normalizedCode,
            revision: revision,
            expectedChecksum: checksum,
            actualChecksum: testRow.checksum,
          ),
        );
      }

      final refRows =
          await (_database.select(_database.practiceTestQuestionRefs)
                ..where(
                  (row) =>
                      row.practiceTestCode.equals(normalizedCode) &
                      row.practiceTestRevision.equals(revision),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.questionOrder)]))
              .get();
      if (refRows.isEmpty) {
        return const FailureResult<AssessmentRevisionBundle?>(
          ApplicationFailure(
            code: 'ASSESSMENT_LOCAL_INCOMPLETE',
            message: 'The local assessment revision has no question refs.',
          ),
        );
      }

      final refs = <PracticeTestQuestionRef>[];
      final questions = <AssessmentQuestionRevision>[];
      for (final refRow in refRows) {
        final questionId = QuestionRevisionId(
          questionCode: refRow.questionCode,
          revision: refRow.questionRevision,
          checksum: refRow.questionChecksum,
        );
        refs.add(
          PracticeTestQuestionRef(
            order: refRow.questionOrder,
            question: questionId,
            points: refRow.points,
          ),
        );

        final questionRow =
            await (_database.select(_database.assessmentQuestionReads)..where(
                  (row) =>
                      row.questionCode.equals(refRow.questionCode) &
                      row.revision.equals(refRow.questionRevision),
                ))
                .getSingleOrNull();
        if (questionRow == null) {
          return FailureResult<AssessmentRevisionBundle?>(
            ApplicationFailure(
              code: 'ASSESSMENT_LOCAL_INCOMPLETE',
              message: 'An exact referenced question revision is missing.',
              details: <String, Object?>{
                'questionCode': refRow.questionCode,
                'revision': refRow.questionRevision,
              },
            ),
          );
        }
        if (questionRow.checksum != refRow.questionChecksum) {
          return FailureResult<AssessmentRevisionBundle?>(
            _checksumConflict(
              code: refRow.questionCode,
              revision: refRow.questionRevision,
              expectedChecksum: refRow.questionChecksum,
              actualChecksum: questionRow.checksum,
            ),
          );
        }
        questions.add(_questionFromRow(questionRow));
      }

      final test = PracticeTestRevision(
        practiceTestCode: testRow.practiceTestCode,
        revision: testRow.revision,
        checksum: testRow.checksum,
        title: testRow.title,
        subtitle: testRow.subtitle,
        mode: _modeFromStorage(testRow.mode),
        passingScoreBasisPoints: testRow.passingScoreBasisPoints,
        questionRefs: refs,
      );
      return Success<AssessmentRevisionBundle?>(
        AssessmentRevisionBundle(test: test, questions: questions),
      );
    } on ArgumentError catch (error) {
      return FailureResult<AssessmentRevisionBundle?>(_localCorrupt(error));
    } on FormatException catch (error) {
      return FailureResult<AssessmentRevisionBundle?>(
        _localCorrupt(error),
      );
    } on StateError catch (error) {
      return FailureResult<AssessmentRevisionBundle?>(_localCorrupt(error));
    }
  }

  @override
  Future<Result<AssessmentRevisionBundle>> saveBundle(
    AssessmentRevisionBundle bundle,
  ) async {
    try {
      await _database.transaction(() async {
        final existingTest =
            await (_database.select(_database.practiceTestRevisionReads)..where(
                  (row) =>
                      row.practiceTestCode.equals(bundle.test.practiceTestCode) &
                      row.revision.equals(bundle.test.revision),
                ))
                .getSingleOrNull();
        if (existingTest != null &&
            existingTest.checksum != bundle.test.checksum) {
          throw _AssessmentStorageViolation(
            _checksumConflict(
              code: bundle.test.practiceTestCode,
              revision: bundle.test.revision,
              expectedChecksum: existingTest.checksum,
              actualChecksum: bundle.test.checksum,
            ),
          );
        }

        for (final question in bundle.questions) {
          final existingQuestion =
              await (_database.select(_database.assessmentQuestionReads)..where(
                    (row) =>
                        row.questionCode.equals(question.id.questionCode) &
                        row.revision.equals(question.id.revision),
                  ))
                  .getSingleOrNull();
          if (existingQuestion != null &&
              existingQuestion.checksum != question.id.checksum) {
            throw _AssessmentStorageViolation(
              _checksumConflict(
                code: question.id.questionCode,
                revision: question.id.revision,
                expectedChecksum: existingQuestion.checksum,
                actualChecksum: question.id.checksum,
              ),
            );
          }
        }

        final now = DateTime.now().toUtc();
        await _database
            .into(_database.practiceTestRevisionReads)
            .insertOnConflictUpdate(
              db.PracticeTestRevisionReadsCompanion.insert(
                practiceTestCode: bundle.test.practiceTestCode,
                revision: bundle.test.revision,
                checksum: bundle.test.checksum,
                title: bundle.test.title,
                subtitle: bundle.test.subtitle,
                mode: bundle.test.mode.name,
                passingScoreBasisPoints: bundle.test.passingScoreBasisPoints,
                createdAt: now,
              ),
            );

        for (final question in bundle.questions) {
          final body = question.body;
          if (body is! SingleChoiceQuestionBody) {
            throw const _AssessmentStorageViolation(
              ApplicationFailure(
                code: 'ASSESSMENT_BODY_UNSUPPORTED',
                message: 'The assessment body kind is not supported locally.',
              ),
            );
          }
          await _database
              .into(_database.assessmentQuestionReads)
              .insertOnConflictUpdate(
                db.AssessmentQuestionReadsCompanion.insert(
                  questionCode: question.id.questionCode,
                  revision: question.id.revision,
                  checksum: question.id.checksum,
                  bodyKind: 'singleChoice',
                  prompt: body.prompt,
                  optionsJson: jsonEncode(body.options),
                  correctOptionIndex: body.correctOptionIndex,
                  skillCode: body.skillCode,
                  explanation: body.explanation,
                  createdAt: now,
                ),
              );
        }

        await (_database.delete(_database.practiceTestQuestionRefs)..where(
              (row) =>
                  row.practiceTestCode.equals(bundle.test.practiceTestCode) &
                  row.practiceTestRevision.equals(bundle.test.revision),
            ))
            .go();
        for (final ref in bundle.test.questionRefs) {
          await _database.into(_database.practiceTestQuestionRefs).insert(
                db.PracticeTestQuestionRefsCompanion.insert(
                  practiceTestCode: bundle.test.practiceTestCode,
                  practiceTestRevision: bundle.test.revision,
                  questionOrder: ref.order,
                  questionCode: ref.question.questionCode,
                  questionRevision: ref.question.revision,
                  questionChecksum: ref.question.checksum,
                  points: ref.points,
                ),
              );
        }
      });
      return Success<AssessmentRevisionBundle>(bundle);
    } on _AssessmentStorageViolation catch (error) {
      return FailureResult<AssessmentRevisionBundle>(error.failure);
    } on ArgumentError catch (error) {
      return FailureResult<AssessmentRevisionBundle>(_localCorrupt(error));
    } on StateError catch (error) {
      return FailureResult<AssessmentRevisionBundle>(_localCorrupt(error));
    }
  }

  AssessmentQuestionRevision _questionFromRow(db.AssessmentQuestionRead row) {
    if (row.bodyKind != 'singleChoice') {
      throw StateError('Unsupported stored assessment body kind.');
    }
    final decoded = jsonDecode(row.optionsJson);
    if (decoded is! List || decoded.any((value) => value is! String)) {
      throw const FormatException('Stored assessment options are invalid.');
    }
    return AssessmentQuestionRevision(
      id: QuestionRevisionId(
        questionCode: row.questionCode,
        revision: row.revision,
        checksum: row.checksum,
      ),
      body: SingleChoiceQuestionBody(
        prompt: row.prompt,
        options: decoded.cast<String>(),
        correctOptionIndex: row.correctOptionIndex,
        skillCode: row.skillCode,
        explanation: row.explanation,
      ),
    );
  }

  AssessmentMode _modeFromStorage(String value) => switch (value) {
    'learn' => AssessmentMode.learn,
    'exam' => AssessmentMode.exam,
    'quick' => AssessmentMode.quick,
    _ => throw StateError('Unsupported stored assessment mode.'),
  };
}

ApplicationFailure _checksumConflict({
  required String code,
  required int revision,
  required String expectedChecksum,
  required String actualChecksum,
}) {
  return ApplicationFailure(
    code: 'ASSESSMENT_REVISION_CHECKSUM_CONFLICT',
    message: 'One assessment code/revision cannot have multiple checksums.',
    details: <String, Object?>{
      'code': code,
      'revision': revision,
      'expectedChecksum': expectedChecksum,
      'actualChecksum': actualChecksum,
    },
  );
}

ApplicationFailure _localCorrupt(Object error) {
  return ApplicationFailure(
    code: 'ASSESSMENT_LOCAL_CORRUPT',
    message: 'The local assessment revision is internally inconsistent.',
    details: <String, Object?>{'error': error.toString()},
  );
}

final class _AssessmentStorageViolation implements Exception {
  const _AssessmentStorageViolation(this.failure);

  final ApplicationFailure failure;
}

final _businessCodePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
