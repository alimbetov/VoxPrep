import 'dart:io';

import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_learner_state_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  late CareerSpeakDatabase database;
  late DriftLearnerStateRepository repository;

  const identity = ContentIdentity(
    code: 'JAVA_DI_001',
    type: ContentType.interview,
  );
  final now = DateTime.utc(2026, 10, 30, 11);

  setUp(() {
    database = createTestDatabase();
    repository = DriftLearnerStateRepository(database, now: () => now);
  });

  tearDown(() async {
    await database.close();
  });

  test('favorite writes round-trip through marker projection', () async {
    final write = await repository.setFavorite(identity, favorite: true);
    expect(write, isA<Success<void>>());

    final markers = await _currentMarkers(repository);
    expect(markers[identity]?.favorite, isTrue);
    expect(markers[identity]?.listened, isFalse);
    expect(markers[identity]?.completed, isFalse);

    final remove = await repository.setFavorite(identity, favorite: false);
    expect(remove, isA<Success<void>>());

    final afterRemoval = await _currentMarkers(repository);
    expect(afterRemoval, isNot(contains(identity)));
  });

  test('listened transition increments count only when becoming listened', () async {
    await repository.setListened(
      identity,
      listened: true,
      lastRevisionSeen: 7,
    );

    var row = await database.select(database.contentLearningStates).getSingle();
    expect(row.listenedAt, now);
    expect(row.listenCount, 1);
    expect(row.lastRevisionSeen, 7);

    await repository.setListened(identity, listened: true);
    row = await database.select(database.contentLearningStates).getSingle();
    expect(row.listenCount, 1);

    await repository.setListened(identity, listened: false);
    row = await database.select(database.contentLearningStates).getSingle();
    expect(row.listenedAt, isNull);
    expect(row.listenCount, 1);

    await repository.setListened(identity, listened: true);
    row = await database.select(database.contentLearningStates).getSingle();
    expect(row.listenCount, 2);
  });

  test('completion and playback position merge into one learner state', () async {
    await repository.setCompleted(
      identity,
      completed: true,
      completionSource: 'TEST',
      lastRevisionSeen: 8,
    );
    await repository.savePlaybackPosition(identity, positionMs: 1250);

    final row = await database.select(database.contentLearningStates).getSingle();
    expect(row.completedAt, now);
    expect(row.completionSource, 'TEST');
    expect(row.lastRevisionSeen, 8);
    expect(row.lastPositionMs, 1250);

    final markers = await _currentMarkers(repository);
    expect(markers[identity]?.completed, isTrue);
    expect(markers[identity]?.lastPositionMs, 1250);

    await repository.setCompleted(identity, completed: false);
    final cleared = await database
        .select(database.contentLearningStates)
        .getSingle();
    expect(cleared.completedAt, isNull);
    expect(cleared.completionSource, isNull);
  });

  test('negative playback position fails without writing state', () async {
    final result = await repository.savePlaybackPosition(
      identity,
      positionMs: -1,
    );

    expect(result, isA<FailureResult<void>>());
    final failure = (result as FailureResult<void>).failure;
    expect(failure.code, 'INVALID_PLAYBACK_POSITION');
    expect(failure.retryable, isFalse);
    expect(await database.select(database.contentLearningStates).get(), isEmpty);
  });

  test('content identity type survives Drift storage round-trip', () async {
    const identities = <ContentIdentity>[
      ContentIdentity(code: 'VOCAB', type: ContentType.vocabulary),
      ContentIdentity(code: 'INTERVIEW', type: ContentType.interview),
      ContentIdentity(code: 'TOPIC', type: ContentType.topic),
      ContentIdentity(code: 'SHADOW', type: ContentType.shadowing),
      ContentIdentity(code: 'PHRASE', type: ContentType.phrase),
    ];

    for (final item in identities) {
      await repository.setFavorite(item, favorite: true);
    }

    final markers = await _currentMarkers(repository);
    expect(markers.keys.toSet(), identities.toSet());
    expect(markers.values.every((marker) => marker.favorite), isTrue);
  });

  test('learner state survives database close and reopen', () async {
    await database.close();

    final directory = await Directory.systemTemp.createTemp(
      'careerspeak-p2-2-reopen-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/careerspeak.sqlite');

    final firstDatabase = CareerSpeakDatabase(NativeDatabase(file));
    final firstRepository = DriftLearnerStateRepository(
      firstDatabase,
      now: () => now,
    );

    (await firstRepository.setFavorite(identity, favorite: true)).getOrThrow();
    (await firstRepository.setListened(identity, listened: true)).getOrThrow();
    (await firstRepository.setCompleted(identity, completed: true)).getOrThrow();
    (await firstRepository.savePlaybackPosition(
      identity,
      positionMs: 42000,
    )).getOrThrow();

    final beforeReopen = await _currentMarkers(firstRepository);
    expect(beforeReopen[identity]?.favorite, isTrue);
    expect(beforeReopen[identity]?.listened, isTrue);
    expect(beforeReopen[identity]?.completed, isTrue);
    expect(beforeReopen[identity]?.lastPositionMs, 42000);

    await firstDatabase.close();

    final reopenedDatabase = CareerSpeakDatabase(NativeDatabase(file));
    final reopenedRepository = DriftLearnerStateRepository(
      reopenedDatabase,
      now: () => now.add(const Duration(minutes: 5)),
    );

    final restored = await _currentMarkers(reopenedRepository);
    expect(restored[identity]?.favorite, isTrue);
    expect(restored[identity]?.listened, isTrue);
    expect(restored[identity]?.completed, isTrue);
    expect(restored[identity]?.lastPositionMs, 42000);

    await reopenedDatabase.close();

    database = createTestDatabase();
    repository = DriftLearnerStateRepository(database, now: () => now);
  });
}

Future<Map<ContentIdentity, dynamic>> _currentMarkers(
  DriftLearnerStateRepository repository,
) async {
  final result = await repository.watchMarkers().first;
  return result.getOrThrow();
}
