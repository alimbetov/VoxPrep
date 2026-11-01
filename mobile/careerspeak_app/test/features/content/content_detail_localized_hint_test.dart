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
  testWidgets('localized hint action is absent when translation has no hint', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byTooltip('Hint'), findsNothing);
    expect(find.text('Hint'), findsNothing);
  });

  testWidgets('localized hint opens popup only when localized hint exists', (
    tester,
  ) async {
    await _pump(
      tester,
      localizedHint: 'Подумайте о жизненном цикле Spring Bean.',
    );

    expect(find.byTooltip('Hint'), findsOneWidget);
    expect(find.text('Подумайте о жизненном цикле Spring Bean.'), findsNothing);

    await tester.tap(find.byTooltip('Hint'));
    await tester.pumpAndSettle();

    expect(find.text('Hint'), findsOneWidget);
    expect(
      find.text('Подумайте о жизненном цикле Spring Bean.'),
      findsOneWidget,
    );
  });
}

Future<void> _pump(WidgetTester tester, {String? localizedHint}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerStateRepositoryProvider.overrideWithValue(_LearnerState()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ContentDetailPanel(item: _topic, localizedHint: localizedHint),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _topic = ContentItem(
  code: 'LOCALIZED_HINT_TOPIC',
  type: ContentType.topic,
  title: 'Canonical title',
  subtitle: 'Canonical subtitle',
  description: 'Canonical description',
  category: 'JAVA',
  level: 'B2',
  minutes: 3,
  revision: 1,
  hasAudio: false,
);

final class _LearnerState implements LearnerStateRepository {
  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() =>
      Stream<Result<Map<ContentIdentity, ContentMarkerState>>>.value(
        const Success<Map<ContentIdentity, ContentMarkerState>>(
          <ContentIdentity, ContentMarkerState>{},
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
