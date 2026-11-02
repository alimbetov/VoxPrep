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

import '../../support/ui_boundary_harness.dart';

const _longHint =
    'Подсказка может быть достаточно длинной: сопоставьте жизненный цикл объекта, '
    'момент создания зависимостей, порядок инициализации и поведение приложения при повторном использовании компонента.';

void main() {
  for (final boundary in adaptiveUiBoundaryCases) {
    testWidgets('content detail has no visual overflow at $boundary', (
      tester,
    ) async {
      await _pump(tester, boundary);

      expect(find.text(_item.title), findsOneWidget);
      expectNoLayoutExceptions(
        tester,
        reason: 'Content detail overflowed at $boundary',
      );

      await tester.ensureVisible(find.byTooltip('Hint'));
      await tester.pumpAndSettle();
      expectNoLayoutExceptions(
        tester,
        reason:
            'Content detail overflowed after scrolling to hint at $boundary',
      );
      expectFinderInsideViewport(
        tester,
        find.byTooltip('Hint'),
        viewport: boundary.size,
        reason: 'Localized hint control must remain tappable at $boundary',
      );

      await tester.tap(find.byTooltip('Hint'));
      await tester.pumpAndSettle();

      expect(find.text(_longHint), findsOneWidget);
      expectNoLayoutExceptions(
        tester,
        reason: 'Localized hint dialog overflowed at $boundary',
      );
      expectFinderInsideViewport(
        tester,
        find.byType(AlertDialog),
        viewport: boundary.size,
        reason: 'Localized hint dialog must fit viewport at $boundary',
      );
    });
  }
}

Future<void> _pump(WidgetTester tester, UiBoundaryCase boundary) async {
  await configureAdaptiveSurface(tester, boundary: boundary);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerStateRepositoryProvider.overrideWithValue(_LearnerState()),
      ],
      child: MaterialApp(
        builder: adaptiveMediaQueryBuilder(boundary),
        home: const Scaffold(
          body: ContentDetailPanel(item: _item, localizedHint: _longHint),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _item = ContentItem(
  code: 'LONG_LOCALIZED_CONTENT',
  type: ContentType.topic,
  title: 'Подробное объяснение архитектурных решений и жизненного цикла компонентов приложения',
  subtitle: 'Практический материал для подготовки к техническому собеседованию уровня senior',
  description:
      'Описание намеренно длинное, чтобы проверить перенос строк, вертикальную компоновку, '
      'доступность элементов управления и отсутствие визуальных дефектов при увеличенном масштабе текста.',
  category: 'SOFTWARE_ENGINEERING',
  level: 'ADVANCED',
  minutes: 12,
  revision: 5,
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
