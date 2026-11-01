import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_attempt_repository.dart';
import 'package:careerspeak_app/data/local/publication_snapshot_storage.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  group('DriftPracticeTestAttemptRepository', () {
    test('v13 capability persists active attempt across repository reopen', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      expect(database.schemaVersion, greaterThanOrEqualTo(13));

      await _publishPracticeTest(database, code: 'JAVA_CORE', revision: 7);
      final clock = DateTime.utc(2026, 11, 1, 10);
      final repository = DriftPracticeTestAttemptRepository(
        database,
        now: () => clock,
      );

      final started = await repository.startActiveAttempt('JAVA_CORE');
      final active = (started as Success<PracticeTestAttempt>).value;
      expect(active.practiceTestCode, 'JAVA_CORE');
      expect(active.practiceTestRevision, 7);
      expect(active.currentIndex, 0);
      expect(active.answers, isEmpty);

      final progressed = active.copyWith(
        currentIndex: 3,
        answers: const <int, int>{0: 2, 1: 1, 3: 0},
        updatedAt: clock.add(const Duration(minutes: 2)),
      );
      final saved = await repository.saveActiveAttempt(progressed);
      expect(saved, isA<Success<PracticeTestAttempt>>());

      final reopenedRepository = DriftPracticeTestAttemptRepository(database);
      final reopened = await reopenedRepository.getActiveAttempt();
      final restored = (reopened as Success<PracticeTestAttempt?>).value!;

      expect(restored.practiceTestCode, progressed.practiceTestCode);
      expect(restored.practiceTestRevision, progressed.practiceTestRevision);
      expect(restored.currentIndex, progressed.currentIndex);
      expect(restored.answers, progressed.answers);
      expect(restored.startedAt, progressed.startedAt);
      expect(restored.updatedAt, progressed.updatedAt);
    });

    test('start pins only the revision from CURRENT publication', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      await _publishPracticeTest(database, code: 'INTERVIEW', revision: 11);
      final repository = DriftPracticeTestAttemptRepository(database);

      final result = await repository.startActiveAttempt('INTERVIEW');
      final attempt = (result as Success<PracticeTestAttempt>).value;

      expect(attempt.practiceTestRevision, 11);
    });

    test('submit/reset storage semantics remove the resumable row', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      await _publishPracticeTest(database, code: 'QUICK', revision: 2);
      final repository = DriftPracticeTestAttemptRepository(database);

      expect(
        await repository.startActiveAttempt('QUICK'),
        isA<Success<PracticeTestAttempt>>(),
      );
      expect(await repository.clearActiveAttempt(), isA<Success<void>>());

      final read = await repository.getActiveAttempt();
      expect((read as Success<PracticeTestAttempt?>).value, isNull);
    });

    test('cannot start a test outside CURRENT publication', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      await _setCurrentContentVersion(database, 5);
      final repository = DriftPracticeTestAttemptRepository(database);

      final result = await repository.startActiveAttempt('STALE');

      expect(result, isA<FailureResult<PracticeTestAttempt>>());
      expect(
        (result as FailureResult<PracticeTestAttempt>).failure.code,
        'PRACTICE_TEST_ATTEMPT_NOT_CURRENT',
      );
    });
  });
}

Future<void> _publishPracticeTest(
  CareerSpeakDatabase database, {
  required String code,
  required int revision,
}) async {
  await _setCurrentContentVersion(database, 5);
  await PublicationSnapshotStorage(database).ensureReady();
  await database.customStatement(
    '''
    INSERT INTO publication_practice_test_refs (
      content_version,
      practice_test_code,
      revision,
      checksum
    ) VALUES (?, ?, ?, ?)
    ''',
    <Object?>[5, code, revision, List<String>.filled(64, 'a').join()],
  );
}

Future<void> _setCurrentContentVersion(
  CareerSpeakDatabase database,
  int version,
) async {
  await database.customStatement(
    '''
    INSERT INTO content_manifest_states (
      id,
      schema_version,
      current_content_version,
      current_manifest_checksum,
      updated_at
    ) VALUES (1, 1, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      current_content_version = excluded.current_content_version,
      current_manifest_checksum = excluded.current_manifest_checksum,
      updated_at = excluded.updated_at
    ''',
    <Object?>[
      version,
      List<String>.filled(64, 'b').join(),
      DateTime.utc(2026, 11, 1).millisecondsSinceEpoch,
    ],
  );
}
