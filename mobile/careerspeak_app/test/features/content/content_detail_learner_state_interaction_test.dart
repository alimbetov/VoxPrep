import 'dart:async';

import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/content/content_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('favorite is repository-driven and toggles through stream state', (
    tester,
  ) async {
    final repository = _ReactiveLearnerStateRepository();
    addTearDown(repository.dispose);
    await _pump(tester, repository);

    expect(find.byTooltip('Add favorite'), findsOneWidget);
    await tester.tap(find.byTooltip('Add favorite'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Remove favorite'), findsOneWidget);
    expect(repository.favoriteWrites, 1);

    await tester.tap(find.byTooltip('Remove favorite'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Add favorite'), findsOneWidget);
    expect(repository.favoriteWrites, 2);
  });

  testWidgets('completed state changes only after repository stream update', (
    tester,
  ) async {
    final repository = _ReactiveLearnerStateRepository();
    addTearDown(repository.dispose);
    await _pump(tester, repository);

    expect(find.text('Mark completed'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Mark completed'));
    await tester.pumpAndSettle();

    expect(find.text('Mark incomplete'), findsOneWidget);
    expect(repository.completedWrites, 1);
    expect(repository.lastCompletedRevision, _item.revision);
  });

  testWidgets('learner state read failure replaces mutable content UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerStateRepositoryProvider.overrideWithValue(
            const _FailingLearnerStateRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ContentDetailPanel(item: _item)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Unable to load learner state.'), findsOneWidget);
    expect(find.text('Mark completed'), findsNothing);
    expect(find.byTooltip('Add favorite'), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester,
  LearnerStateRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [learnerStateRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(
        home: Scaffold(body: ContentDetailPanel(item: _item)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _item = ContentItem(
  code: 'TOPIC_STATE',
  type: ContentType.topic,
  title: 'Learner state topic',
  subtitle: 'Repository-driven state',
  description: 'State must come back through the repository stream.',
  category: 'JAVA',
  level: 'B2',
  minutes: 2,
  revision: 4,
  hasAudio: false,
);

final class _ReactiveLearnerStateRepository implements LearnerStateRepository {
  final _controller =
      StreamController<Result<Map<ContentIdentity, ContentMarkerState>>>.broadcast();
  final Map<ContentIdentity, ContentMarkerState> _markers =
      <ContentIdentity, ContentMarkerState>{};

  int favoriteWrites = 0;
  int completedWrites = 0;
  int? lastCompletedRevision;

  void dispose() => _controller.close();

  void _emit() {
    _controller.add(
      Success<Map<ContentIdentity, ContentMarkerState>>(
        Map<ContentIdentity, ContentMarkerState>.unmodifiable(_markers),
      ),
    );
  }

  ContentMarkerState _state(ContentIdentity identity) =>
      _markers[identity] ?? const ContentMarkerState();

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() async* {
    yield Success<Map<ContentIdentity, ContentMarkerState>>(
      Map<ContentIdentity, ContentMarkerState>.unmodifiable(_markers),
    );
    yield* _controller.stream;
  }

  @override
  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  }) async {
    favoriteWrites++;
    _markers[identity] = _state(identity).copyWith(favorite: favorite);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async {
    completedWrites++;
    lastCompletedRevision = lastRevisionSeen;
    _markers[identity] = _state(identity).copyWith(
      completed: completed,
      lastRevisionSeen: lastRevisionSeen,
    );
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  }) async {
    _markers[identity] = _state(identity).copyWith(
      listened: listened,
      lastRevisionSeen: lastRevisionSeen,
    );
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async {
    _markers[identity] = _state(identity).copyWith(
      lastPositionMs: positionMs,
      lastRevisionSeen: lastRevisionSeen,
    );
    _emit();
    return const Success<void>(null);
  }
}

final class _FailingLearnerStateRepository implements LearnerStateRepository {
  const _FailingLearnerStateRepository();

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() =>
      Stream<Result<Map<ContentIdentity, ContentMarkerState>>>.value(
        const FailureResult<Map<ContentIdentity, ContentMarkerState>>(
          ApplicationFailure(
            code: 'SYNTHETIC_LEARNER_READ_FAILURE',
            message: 'synthetic learner read failure',
          ),
        ),
      );

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);
}
