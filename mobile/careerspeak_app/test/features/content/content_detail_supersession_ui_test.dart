import 'dart:async';

import 'package:careerspeak_app/app/audio_playback_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/ports/audio_playback_engine.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/application/services/audio_playback_controller.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/content/content_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'rapid double Play supersession is silent and latest request wins',
    (tester) async {
      final resolver = _ControlledResolver();
      final engine = _Engine();
      final learnerState = _LearnerState();
      final controller = AudioPlaybackController(
        resolveAudioAsset: resolver.resolve,
        engine: engine,
        learnerState: learnerState,
      );

      debugPrint('[A1-AUDIO] entering test');
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              learnerStateRepositoryProvider.overrideWithValue(learnerState),
              audioPlaybackControllerProvider.overrideWithValue(controller),
            ],
            child: const MaterialApp(
              home: Scaffold(body: ContentDetailPanel(item: _topic)),
            ),
          ),
        );
        debugPrint('[A1-AUDIO] widget mounted');
        // Do not pumpAndSettle against an asynchronous playback state:
        // an in-flight audio resolve deliberately has an animated spinner.
        for (
          var frame = 0;
          frame < 5 &&
              find.widgetWithText(FilledButton, 'Play').evaluate().isEmpty;
          frame++
        ) {
          await tester.pump();
        }
        debugPrint('[A1-AUDIO] initial play button located');
        expect(find.widgetWithText(FilledButton, 'Play'), findsOneWidget);

        final play = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Play'),
        );
        play.onPressed!();
        play.onPressed!();

        for (
          var frame = 0;
          frame < 30 && resolver.pending.length < 2;
          frame++
        ) {
          await tester.pump();
        }
        debugPrint('[A1-AUDIO] resolve calls: ${resolver.pending.length}');
        expect(resolver.pending, hasLength(2));

        resolver.complete(0, _asset('superseded'));
        await tester.pump();
        expect(find.textContaining('Audio playback failed:'), findsNothing);

        debugPrint('[A1-AUDIO] losing completion handled');
        resolver.complete(1, _asset('winner'));
        for (var frame = 0; frame < 5; frame++) {
          await tester.pump();
        }
        expect(find.textContaining('Audio playback failed:'), findsNothing);
        expect(find.text('Pause'), findsOneWidget);
        expect(engine.openedAssetIds, <String>['winner']);
        debugPrint('[A1-AUDIO] winning completion asserted');
      } finally {
        debugPrint('[A1-AUDIO] entering cleanup');
        // Riverpod's StreamProvider is listening to controller.states.
        // Unmount it *before* awaiting the broadcast controller's close().
        // Otherwise test finalization can await a paused FakeAsync listener
        // indefinitely even if the supersession behavior is correct.
        await tester.pumpWidget(const SizedBox.shrink());
        debugPrint('[A1-AUDIO] widget unmounted');
        await tester.pump();
        debugPrint('[A1-AUDIO] controller closing');
        // Disposal awaits an audio event-subscription cancellation and a
        // persisted-progress future. Drive both outside widget FakeAsync,
        // which otherwise leaves these asynchronous completions suspended.
        await tester.runAsync(() async {
          await controller.dispose();
        });
        debugPrint('[A1-AUDIO] controller closed');
      }
    },
  );
}

const _topic = ContentItem(
  code: 'UI_RACE_TOPIC',
  type: ContentType.topic,
  title: 'UI race topic',
  subtitle: 'Rapid play',
  description: 'Supersession should be silent.',
  category: 'RACE',
  level: 'B2',
  minutes: 1,
  revision: 1,
  hasAudio: true,
);

ResolvedAsset _asset(String id) => ResolvedAsset(
  assetId: id,
  localPath: '/tmp/$id.mp3',
  mediaType: 'audio/mpeg',
);

final class _ControlledResolver {
  final List<Completer<Result<ResolvedAsset>>> pending =
      <Completer<Result<ResolvedAsset>>>[];

  Future<Result<ResolvedAsset>> resolve(ContentIdentity content, int revision) {
    final completer = Completer<Result<ResolvedAsset>>();
    pending.add(completer);
    return completer.future;
  }

  void complete(int index, ResolvedAsset asset) {
    pending[index].complete(Success<ResolvedAsset>(asset));
  }
}

final class _Engine implements AudioPlaybackEngine {
  final List<String> openedAssetIds = <String>[];

  @override
  Future<Result<AudioPlaybackSession>> openLocal({
    required String path,
    required String mediaType,
  }) async {
    openedAssetIds.add(path.split('/').last.replaceAll('.mp3', ''));
    return Success<AudioPlaybackSession>(_Session());
  }
}

final class _Session implements AudioPlaybackSession {
  @override
  Duration? get initialDuration => const Duration(seconds: 10);

  @override
  Stream<AudioPlaybackEvent> get events =>
      const Stream<AudioPlaybackEvent>.empty();

  @override
  Future<Result<void>> play() async => const Success<void>(null);

  @override
  Future<Result<void>> pause() async => const Success<void>(null);

  @override
  Future<Result<void>> seek(Duration position) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> stop() async => const Success<void>(null);

  @override
  Future<void> dispose() async {}
}

final class _LearnerState implements LearnerStateRepository {
  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() =>
      Stream<Result<Map<ContentIdentity, ContentMarkerState>>>.value(
        const Success<Map<ContentIdentity, ContentMarkerState>>(
          <ContentIdentity, ContentMarkerState>{},
        ),
      );

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

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);
}
