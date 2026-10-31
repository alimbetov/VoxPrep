import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/ports/assessment_revision_repository.dart';
import '../../application/ports/practice_test_repository.dart';
import '../../application/query/page.dart';
import '../../application/query/practice_test_query.dart';
import '../../application/result/result.dart';
import '../../domain/assessment.dart';
import '../../domain/assessment_bundle.dart';
import '../../domain/practice_test.dart';
import 'database/careerspeak_database.dart';
import 'publication_snapshot_storage.dart';

/// Learner-facing practice-test repository fenced by the CURRENT publication.
///
/// No revision is selected by MAX/latest/current-test semantics. The exact test
/// revision/checksum comes from publication_practice_test_refs for the single
/// CURRENT root contentVersion, then resolves through the immutable assessment
/// cache.
final class DriftPracticeTestRepository implements PracticeTestRepository {
  const DriftPracticeTestRepository(this._database, this._assessmentRepository);

  final CareerSpeakDatabase _database;
  final AssessmentRevisionRepository _assessmentRepository;

  @override
  Stream<Result<Page<PracticeTestSummary>>> watchTests(
    PracticeTestQuery query,
  ) async* {
    try {
      await PublicationSnapshotStorage(_database).ensureReady();
    } on Object catch (error) {
      yield FailureResult<Page<PracticeTestSummary>>(
        ApplicationFailure(
          code: 'PRACTICE_TEST_READ_FAILED',
          message: 'The CURRENT practice-test projection could not be read.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
      return;
    }

    final cursor = _decodeCursor(query.page.cursor);
    if (cursor case FailureResult<String?>(:final failure)) {
      yield FailureResult<Page<PracticeTestSummary>>(failure);
      return;
    }

    final afterCode = (cursor as Success<String?>).value;
    final variables = <Variable<Object>>[];
    final sql = StringBuffer(_summarySql);
    if (query.mode != null) {
      sql.write(' AND t.mode = ?');
      variables.add(Variable<String>(query.mode!.name));
    }
    if (afterCode != null) {
      sql.write(' AND p.practice_test_code > ?');
      variables.add(Variable<String>(afterCode));
    }
    sql.write(
      ' GROUP BY p.practice_test_code, p.revision, p.checksum, '
      't.title, t.subtitle, t.mode ORDER BY p.practice_test_code LIMIT ?',
    );
    variables.add(Variable<int>(query.page.limit + 1));

    try {
      final select = _database.customSelect(
        sql.toString(),
        variables: variables,
        readsFrom: <ResultSetImplementation>{
          _database.contentManifestStates,
          _database.practiceTestRevisionReads,
          _database.practiceTestQuestionRefs,
        },
      );
      await for (final rows in select.watch()) {
        try {
          final summaries = rows.map(_summaryFromRow).toList(growable: false);
          final hasMore = summaries.length > query.page.limit;
          final items = hasMore
              ? summaries.sublist(0, query.page.limit)
              : summaries;
          yield Success<Page<PracticeTestSummary>>(
            Page<PracticeTestSummary>(
              items: items,
              hasMore: hasMore,
              nextCursor: hasMore && items.isNotEmpty
                  ? _encodeCursor(items.last.code)
                  : null,
            ),
          );
        } on Object catch (error) {
          yield FailureResult<Page<PracticeTestSummary>>(_invalidLocal(error));
        }
      }
    } on Object catch (error) {
      yield FailureResult<Page<PracticeTestSummary>>(
        ApplicationFailure(
          code: 'PRACTICE_TEST_READ_FAILED',
          message: 'The CURRENT practice-test projection could not be read.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  @override
  Future<Result<PracticeTest?>> getByCode(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      return const FailureResult<PracticeTest?>(
        ApplicationFailure(
          code: 'PRACTICE_TEST_CODE_INVALID',
          message: 'Practice-test code must not be blank.',
        ),
      );
    }

    try {
      await PublicationSnapshotStorage(_database).ensureReady();
      final refs = await _database
          .customSelect(
            '''
        SELECT p.practice_test_code, p.revision, p.checksum
        FROM content_manifest_states s
        INNER JOIN publication_practice_test_refs p
          ON p.content_version = s.current_content_version
        WHERE s.id = 1
          AND p.practice_test_code = ?
        ''',
            variables: <Variable<Object>>[Variable<String>(normalizedCode)],
            readsFrom: <ResultSetImplementation>{
              _database.contentManifestStates,
            },
          )
          .get();
      if (refs.isEmpty) return const Success<PracticeTest?>(null);
      if (refs.length != 1) {
        return FailureResult<PracticeTest?>(
          _invalidLocal(
            StateError('duplicate CURRENT practice-test membership'),
          ),
        );
      }

      final ref = refs.single;
      final revision = ref.read<int>('revision');
      final checksum = ref.read<String>('checksum');
      final bundleResult = await _assessmentRepository.readBundle(
        practiceTestCode: normalizedCode,
        revision: revision,
        checksum: checksum,
      );
      if (bundleResult case FailureResult<AssessmentRevisionBundle?>(
        :final failure,
      )) {
        return FailureResult<PracticeTest?>(failure);
      }
      final bundle = (bundleResult as Success<AssessmentRevisionBundle?>).value;
      if (bundle == null) {
        return FailureResult<PracticeTest?>(
          ApplicationFailure(
            code: 'CURRENT_PRACTICE_TEST_MISSING',
            message:
                'The CURRENT publication references a practice-test payload that is not staged locally.',
            details: <String, Object?>{
              'practiceTestCode': normalizedCode,
              'revision': revision,
            },
          ),
        );
      }

      final questions = <PracticeQuestion>[];
      for (final question in bundle.questions) {
        final body = question.body;
        if (body is! SingleChoiceQuestionBody) {
          return FailureResult<PracticeTest?>(
            _invalidLocal(StateError('unsupported assessment question body')),
          );
        }
        questions.add(
          PracticeQuestion(
            code: question.id.questionCode,
            prompt: body.prompt,
            options: body.options,
            correctIndex: body.correctOptionIndex,
            skill: body.skillCode,
            explanation: body.explanation,
          ),
        );
      }

      return Success<PracticeTest?>(
        PracticeTest(
          code: bundle.test.practiceTestCode,
          title: bundle.test.title,
          subtitle: bundle.test.subtitle,
          mode: _mode(bundle.test.mode),
          questions: List<PracticeQuestion>.unmodifiable(questions),
        ),
      );
    } on Object catch (error) {
      return FailureResult<PracticeTest?>(_invalidLocal(error));
    }
  }

  PracticeTestSummary _summaryFromRow(QueryRow row) {
    return PracticeTestSummary(
      code: row.read<String>('practice_test_code'),
      title: row.read<String>('title'),
      subtitle: row.read<String>('subtitle'),
      mode: PracticeTestMode.values.byName(row.read<String>('mode')),
      questionCount: row.read<int>('question_count'),
    );
  }

  Result<String?> _decodeCursor(String? cursor) {
    if (cursor == null) return const Success<String?>(null);
    try {
      final decoded = utf8.decode(
        base64Url.decode(base64Url.normalize(cursor)),
      );
      if (decoded.trim().isEmpty) throw const FormatException();
      return Success<String?>(decoded);
    } on Object {
      return const FailureResult<String?>(
        ApplicationFailure(
          code: 'INVALID_PRACTICE_TEST_CURSOR',
          message: 'The practice-test cursor is invalid.',
        ),
      );
    }
  }

  String _encodeCursor(String code) => base64Url.encode(utf8.encode(code));

  PracticeTestMode _mode(AssessmentMode mode) =>
      PracticeTestMode.values.byName(mode.name);

  ApplicationFailure _invalidLocal(Object error) {
    return ApplicationFailure(
      code: 'PRACTICE_TEST_READ_MODEL_INVALID',
      message: 'The CURRENT practice-test read model is inconsistent.',
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}

const _summarySql = '''
SELECT
  p.practice_test_code,
  p.revision,
  p.checksum,
  t.title,
  t.subtitle,
  t.mode,
  count(q.question_order) AS question_count
FROM content_manifest_states s
INNER JOIN publication_practice_test_refs p
  ON p.content_version = s.current_content_version
INNER JOIN practice_test_revision_reads t
  ON t.practice_test_code = p.practice_test_code
 AND t.revision = p.revision
 AND t.checksum = p.checksum
LEFT JOIN practice_test_question_refs q
  ON q.practice_test_code = p.practice_test_code
 AND q.practice_test_revision = p.revision
WHERE s.id = 1
''';
