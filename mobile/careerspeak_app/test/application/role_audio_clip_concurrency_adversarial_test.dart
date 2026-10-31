import 'dart:async';

import 'package:careerspeak_app/application/content_delivery/content_audio_policy.dart';
import 'package:careerspeak_app/application/ports/audio_playback_engine.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/application/services/role_audio_clip_controller.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rapid QUESTION to SAMPLE_ANSWER switch is last-request-wins', () async {
    final resolver = _ControlledRoleResolver();
    final engine = _Engine();
    final controller = RoleAudioClipController(
      resolveAudioAsset: resolver.resolve,
      engine: engine,
    );
    addTearDown(controller.dispose);

    final question = controller.play(_interview, ContentAudioRole.question);
    await _waitUntil(() => resolver.pending.length == 1);
    final answer = controller.play(_interview, ContentAudioRole.sampleAnswer);
    await _waitUntil(() => resolver.pending.length == 2);

    resolver.complete(0, _asset('question-late'));
    final questionResult = await question;
    expect(questionResult, isA<FailureResult<void>>());
    expect(
      (questionResult as FailureResult<void>).failure.code,
      'ROLE_AUDIO_REQUEST_SUPERSEDED',
    );
    expect(engine.sessions, isEmpty);

    resolver.complete(1, _asset('sample-answer'));
    expect(await answer, isA<Success<void>>());
    expect(engine.sessions, hasLength(1));
    expect(controller.state.role, ContentAudioRole.sampleAnswer);
    expect(controller.state.phase, AudioPlaybackPhase.playing);
  });

  test('Stop during role resolve prevents late engine open', () async {
    final resolver = _ControlledRoleResolver();
    final engine = _Engine();
    final controller = RoleAudioClipController(
      resolveAudioAsset: resolver.resolve,
      engine: engine,
    );
    addTearDown(controller.dispose);

    final play = controller.play(_interview, ContentAudioRole.question);
    await _waitUntil(() => resolver.pending.length == 1);
    expect(controller.state.phase, AudioPlaybackPhase.resolving);

    expect(await controller.stop(), isA<Success<void>>());
    expect(controller.state.phase, AudioPlaybackPhase.stopped);

    resolver.complete(0, _asset('question-late'));
    final result = await play;
    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure.code,
      'ROLE_AUDIO_REQUEST_SUPERSEDED',
    );
    expect(engine.sessions, isEmpty);
    expect(controller.state.phase, AudioPlaybackPhase.stopped);
  });

  test('late completion from superseded role cannot replace active role state', () async {
    final engine = _Engine();
    final controller = RoleAudioClipController(
      resolveAudioAsset: (content, revision, role) async =>
          Success<ResolvedAsset>(_asset(role.wireName)),
      engine: engine,
    );
    addTearDown(controller.dispose);

    expect(
      await controller.play(_interview, ContentAudioRole.question),
      isA<Success<void>>(),
    );
    final oldSession = engine.sessions.single;

    expect(
      await controller.play(_interview, ContentAudioRole.sampleAnswer),
      isA<Success<void>>(),
    );
    oldSession.emit(const AudioPlaybackCompleted());
    await pumpEventQueue();

    expect(controller.state.role, ContentAudioRole.sampleAnswer);
    expect(controller.state.phase, AudioPlaybackPhase.playing);
  });
}

ResolvedAsset _asset(String id) => ResolvedAsset(
  assetId: id,
  localPath: '/tmp/$id.mp3',
  mediaType: 'audio/mpeg',
);

const _interview = ContentItem(
  code: 'INTERVIEW_RACE',
  type: ContentType.interview,
  title: 'Interview race',
  subtitle: 'Interview race',
  description: 'Interview race',
  category: 'JAVA',
  level: 'B2',
  minutes: 1,
  revision: 4,
  hasAudio: true,
);

Future<void> _waitUntil(bool Function() predicate) async {
  for (var i = 0; i < 100 && !predicate(); i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue);
}

final class _ControlledRoleResolver {
  final List<Completer<Result<ResolvedAsset>>> pending =
      <Completer<Result<ResolvedAsset>>>[];

  Future<Result<ResolvedAsset>> resolve(
    ContentIdentity content,
    int revision,
    ContentAudioRole role,
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

  @override
  Duration? get initialDuration => const Duration(seconds: 20);

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
  Future<void> dispose() async {}
}
