import 'dart:async';

import 'package:careerspeak_app/application/ports/audio_playback_engine.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/application/services/audio_playback_controller.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAudioEngine engine;
  late _FakeLearnerStateRepository learner;
  late AudioPlaybackController controller;

  setUp(() {
    engine = _FakeAudioEngine();
    learner = _FakeLearnerStateRepository();
    controller = AudioPlaybackController(
      resolveAudioAsset: (content, revision) async => const Success(
        ResolvedAsset(
          assetId: 'audio-1',
          localPath: '/tmp/audio-1.mp3',
          mediaType: 'audio/mpeg',
        ),
      ),
      engine: engine,
      learnerState: learner,
      progressSaveIntervalMs: 60000,
    );
  });

  tearDown(() async {
    await controller.dispose();
    await engine.close();
  });

  test('restores saved position only for the same content revision', () async {
    final item = _item('JAVA_PROMPT', revision: 7);

    (await controller.play(
      item,
      learnerState: const ContentMarkerState(
        lastPositionMs: 4200,
        lastRevisionSeen: 7,
      ),
    )).getOrThrow();

    expect(engine.sessions.single.seekPositions, <int>[4200]);

    await controller.stop();
    (await controller.play(
      _item('JAVA_PROMPT', revision: 8),
      learnerState: const ContentMarkerState(
        lastPositionMs: 4200,
        lastRevisionSeen: 7,
      ),
    )).getOrThrow();

    expect(engine.sessions.last.seekPositions, isEmpty);
  });

  test('pause persists current position with the active revision', () async {
    final item = _item('SYSTEM_DESIGN', revision: 3);
    (await controller.play(
      item,
      learnerState: const ContentMarkerState(),
    )).getOrThrow();

    engine.sessions.single.emit(
      const AudioPositionChanged(Duration(milliseconds: 12345)),
    );
    await Future<void>.delayed(Duration.zero);

    (await controller.pause()).getOrThrow();

    expect(learner.positions.last.positionMs, 12345);
    expect(learner.positions.last.revision, 3);
    expect(controller.state.phase, AudioPlaybackPhase.paused);
  });

  test(
    'natural completion marks listened once and never marks completed',
    () async {
      final item = _item('BEHAVIORAL', revision: 5);
      (await controller.play(
        item,
        learnerState: const ContentMarkerState(),
      )).getOrThrow();

      final session = engine.sessions.single;
      session.emit(const AudioDurationChanged(Duration(seconds: 60)));
      session.emit(const AudioPositionChanged(Duration(seconds: 59)));
      session.emit(const AudioPlaybackCompleted());
      session.emit(const AudioPlaybackCompleted());
      await pumpEventQueue();

      expect(learner.listened, hasLength(1));
      expect(learner.listened.single.revision, 5);
      expect(learner.completedCalls, 0);
      expect(learner.positions.last.positionMs, 0);
      expect(learner.positions.last.revision, 5);
      expect(controller.state.phase, AudioPlaybackPhase.completed);
    },
  );

  test('late events from the previous track are ignored', () async {
    final first = _item('FIRST', revision: 1);
    final second = _item('SECOND', revision: 2);

    (await controller.play(
      first,
      learnerState: const ContentMarkerState(),
    )).getOrThrow();
    final oldSession = engine.sessions.single;

    (await controller.play(
      second,
      learnerState: const ContentMarkerState(),
    )).getOrThrow();
    final newSession = engine.sessions.last;

    oldSession.emit(const AudioPositionChanged(Duration(seconds: 55)));
    newSession.emit(const AudioPositionChanged(Duration(seconds: 2)));
    await Future<void>.delayed(Duration.zero);

    expect(controller.state.content, ContentIdentity.fromItem(second));
    expect(controller.state.revision, 2);
    expect(controller.state.positionMs, 2000);
  });
}

ContentItem _item(String code, {required int revision}) => ContentItem(
  code: code,
  type: ContentType.phrase,
  title: code,
  subtitle: 'subtitle',
  description: 'description',
  category: 'category',
  level: 'B2',
  minutes: 1,
  revision: revision,
);

final class _FakeAudioEngine implements AudioPlaybackEngine {
  final List<_FakeAudioSession> sessions = <_FakeAudioSession>[];

  @override
  Future<Result<AudioPlaybackSession>> openLocal({
    required String path,
    required String mediaType,
  }) async {
    final session = _FakeAudioSession();
    sessions.add(session);
    return Success<AudioPlaybackSession>(session);
  }

  Future<void> close() async {
    for (final session in sessions) {
      await session.closeEvents();
    }
  }
}

final class _FakeAudioSession implements AudioPlaybackSession {
  final StreamController<AudioPlaybackEvent> _events =
      StreamController<AudioPlaybackEvent>.broadcast(sync: true);
  final List<int> seekPositions = <int>[];
  int playCalls = 0;
  int pauseCalls = 0;
  int stopCalls = 0;
  bool disposed = false;

  @override
  Duration? initialDuration = const Duration(seconds: 60);

  @override
  Stream<AudioPlaybackEvent> get events => _events.stream;

  void emit(AudioPlaybackEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  @override
  Future<Result<void>> play() async {
    playCalls += 1;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> pause() async {
    pauseCalls += 1;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> seek(Duration position) async {
    seekPositions.add(position.inMilliseconds);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> stop() async {
    stopCalls += 1;
    return const Success<void>(null);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  Future<void> closeEvents() async {
    if (!_events.isClosed) await _events.close();
  }
}

final class _FakeLearnerStateRepository implements LearnerStateRepository {
  final List<_PositionWrite> positions = <_PositionWrite>[];
  final List<_ListenedWrite> listened = <_ListenedWrite>[];
  int completedCalls = 0;

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() =>
      const Stream<Result<Map<ContentIdentity, ContentMarkerState>>>.empty();

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
  }) async {
    this.listened.add(
      _ListenedWrite(
        identity: identity,
        listened: listened,
        revision: lastRevisionSeen,
      ),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async {
    completedCalls += 1;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async {
    positions.add(
      _PositionWrite(
        identity: identity,
        positionMs: positionMs,
        revision: lastRevisionSeen,
      ),
    );
    return const Success<void>(null);
  }
}

final class _PositionWrite {
  const _PositionWrite({
    required this.identity,
    required this.positionMs,
    required this.revision,
  });

  final ContentIdentity identity;
  final int positionMs;
  final int? revision;
}

final class _ListenedWrite {
  const _ListenedWrite({
    required this.identity,
    required this.listened,
    required this.revision,
  });

  final ContentIdentity identity;
  final bool listened;
  final int? revision;
}
