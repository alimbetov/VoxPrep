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
  test('rapid double Play is last-request-wins', () async {
    final resolver = _ControlledResolver();
    final engine = _Engine();
    final learner = _LearnerState();
    final controller = AudioPlaybackController(
      resolveAudioAsset: resolver.resolve,
      engine: engine,
      learnerState: learner,
    );
    addTearDown(controller.dispose);

    final first = controller.play(_first, learnerState: const ContentMarkerState());
    await _waitUntil(() => resolver.pending.length == 1);
    final second = controller.play(_first, learnerState: const ContentMarkerState());
    await _waitUntil(() => resolver.pending.length == 2);

    resolver.complete(0, _asset('first-request'));
    final firstResult = await first;
    expect(firstResult, isA<FailureResult<void>>());
    expect((firstResult as FailureResult<void>).failure.code, 'PLAYBACK_SUPERSEDED');
    expect(engine.sessions, isEmpty);

    resolver.complete(1, _asset('second-request'));
    expect(await second, isA<Success<void>>());
    expect(engine.sessions, hasLength(1));
    expect(controller.state.phase, AudioPlaybackPhase.playing);
  });

  test('switching content during resolve cannot resurrect the old item', () async {
    final resolver = _ControlledResolver();
    final engine = _Engine();
    final learner = _LearnerState();
    final controller = AudioPlaybackController(
      resolveAudioAsset: resolver.resolve,
      engine: engine,
      learnerState: learner,
    );
    addTearDown(controller.dispose);

    final first = controller.play(_first, learnerState: const ContentMarkerState());
    await _waitUntil(() => resolver.pending.length == 1);
    final second = controller.play(_second, learnerState: const ContentMarkerState());
    await _waitUntil(() => resolver.pending.length == 2);

    resolver.complete(1, _asset('second'));
    expect(await second, isA<Success<void>>());
    resolver.complete(0, _asset('first'));
    final firstResult = await first;

    expect(firstResult, isA<FailureResult<void>>());
    expect(controller.state.content, ContentIdentity.fromItem(_second));
    expect(controller.state.revision, _second.revision);
    expect(engine.sessions, hasLength(1));
  });

  test('Stop during resolve cancels the pending request before engine open', () async {
    final resolver = _ControlledResolver();
    final engine = _Engine();
    final learner = _LearnerState();
    final controller = AudioPlaybackController(
      resolveAudioAsset: resolver.resolve,
      engine: engine,
      learnerState: learner,
    );
    addTearDown(controller.dispose);

    final play = controller.play(_first, learnerState: const ContentMarkerState());
    await _waitUntil(() => resolver.pending.length == 1);
    expect(controller.state.phase, AudioPlaybackPhase.resolving);

    expect(await controller.stop(), isA<Success<void>>());
    expect(controller.state.phase, AudioPlaybackPhase.stopped);

    resolver.complete(0, _asset('late'));
    final playResult = await play;
    expect(playResult, isA<FailureResult<void>>());
    expect((playResult as FailureResult<void>).failure.code, 'PLAYBACK_SUPERSEDED');
    expect(engine.sessions, isEmpty);
    expect(controller.state.phase, AudioPlaybackPhase.stopped);
  });

  test('completion from a superseded session cannot mark old content listened', () async {
    final engine = _Engine();
    final learner = _LearnerState();
    final controller = AudioPlaybackController(
      resolveAudioAsset: (content, revision) async => Success<ResolvedAsset>(
        _asset('${content.code}-$revision'),
      ),
      engine: engine,
      learnerState: learner,
    );
    addTearDown(controller.dispose);

    expect(
      await controller.play(_first, learnerState: const ContentMarkerState()),
      isA<Success<void>>(),
    );
    final oldSession = engine.sessions.single;

    expect(
      await controller.play(_second, learnerState: const ContentMarkerState()),
      isA<Success<void>>(),
    );
    oldSession.emit(const AudioPlaybackCompleted());
    await pumpEventQueue();

    expect(learner.listened.map((item) => item.code), isNot(contains(_first.code)));
    expect(controller.state.content, ContentIdentity.fromItem(_second));
    expect(controller.state.phase, AudioPlaybackPhase.playing);
  });
}

ResolvedAsset _asset(String id) => ResolvedAsset(
  assetId: id,
  localPath: '/tmp/$id.mp3',
  mediaType: 'audio/mpeg',
);

const _first = ContentItem(
  code: 'RACE_FIRST',
  type: ContentType.topic,
  title: 'First',
  subtitle: 'First',
  description: 'First',
  category: 'RACE',
  level: 'B2',
  minutes: 1,
  revision: 1,
  hasAudio: true,
);

const _second = ContentItem(
  code: 'RACE_SECOND',
  type: ContentType.topic,
  title: 'Second',
  subtitle: 'Second',
  description: 'Second',
  category: 'RACE',
  level: 'B2',
  minutes: 1,
  revision: 2,
  hasAudio: true,
);

Future<void> _waitUntil(bool Function() predicate) async {
  for (var i = 0; i < 100 && !predicate(); i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue);
}

final class _ControlledResolver {
  final List<Completer<Result<ResolvedAsset>>> pending =
      <Completer<Result<ResolvedAsset>>>[];

  Future<Result<ResolvedAsset>> resolve(
    ContentIdentity content,
    int revision,
  ) {
    final completer = Completer<Result<ResolvedAsset>>();
    pending.add(completer);
    return completer.future;
  }

  void complete(int index, ResolvedAsset asset) {
    pending[index].complete(Success<ResolvedAsset>(asset));
  }
}

final class _Engine implements AudioPlaybackEngine {
  final List<_Session> sessions = <_Session>[];

  @override
  Future<Result<AudioPlaybackSession>> openLocal({
    required String path,
    required String mediaType,
  }) async {
    final session = _Session();
    sessions.add(session);
    return Success<AudioPlaybackSession>(session);
  }
}

final class _Session implements AudioPlaybackSession {
  final StreamController<AudioPlaybackEvent> _events =
      StreamController<AudioPlaybackEvent>.broadcast(sync: true);
  bool disposed = false;

  @override
  Duration? get initialDuration => const Duration(seconds: 30);

  @override
  Stream<AudioPlaybackEvent> get events => _events.stream;

  void emit(AudioPlaybackEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

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
  Future<void> dispose() async {
    disposed = true;
  }
}

final class _LearnerState implements LearnerStateRepository {
  final List<ContentIdentity> listened = <ContentIdentity>[];

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
    if (listened) this.listened.add(identity);
    return const Success<void>(null);
  }

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
