import 'dart:async';

import 'package:careerspeak_app/application/content_delivery/content_audio_policy.dart';
import 'package:careerspeak_app/application/ports/audio_playback_engine.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/application/services/role_audio_clip_controller.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeAudioEngine engine;
  late List<ContentAudioRole> resolvedRoles;
  late RoleAudioClipController controller;

  setUp(() {
    engine = _FakeAudioEngine();
    resolvedRoles = <ContentAudioRole>[];
    controller = RoleAudioClipController(
      resolveAudioAsset: (content, revision, role) async {
        resolvedRoles.add(role);
        return Success<ResolvedAsset>(
          ResolvedAsset(
            assetId: 'asset-${role.wireName}',
            localPath: '/tmp/${role.wireName}.mp3',
            mediaType: 'audio/mpeg',
          ),
        );
      },
      engine: engine,
    );
  });

  tearDown(() async {
    await controller.dispose();
    await engine.close();
  });

  test('interview question and sample answer resolve independent roles', () async {
    final item = _interview();

    (await controller.play(item, ContentAudioRole.question)).getOrThrow();
    expect(controller.state.role, ContentAudioRole.question);

    (await controller.play(item, ContentAudioRole.sampleAnswer)).getOrThrow();
    expect(controller.state.role, ContentAudioRole.sampleAnswer);
    expect(resolvedRoles, <ContentAudioRole>[
      ContentAudioRole.question,
      ContentAudioRole.sampleAnswer,
    ]);
    expect(engine.sessions, hasLength(2));
    expect(engine.sessions.first.stopCalls, 1);
    expect(engine.sessions.first.disposed, isTrue);
  });

  test('rejects a role that does not belong to the content type', () async {
    final result = await controller.play(
      _topic(),
      ContentAudioRole.sampleAnswer,
    );

    expect(result, isA<FailureResult<void>>());
    final failure = (result as FailureResult<void>).failure;
    expect(failure.code, 'AUDIO_ROLE_NOT_ALLOWED');
    expect(engine.sessions, isEmpty);
  });

  test('rejects a non-audio role asset', () async {
    final invalid = RoleAudioClipController(
      resolveAudioAsset: (content, revision, role) async => const Success(
        ResolvedAsset(
          assetId: 'image-1',
          localPath: '/tmp/image.webp',
          mediaType: 'image/webp',
        ),
      ),
      engine: engine,
    );
    addTearDown(invalid.dispose);

    final result = await invalid.play(
      _interview(),
      ContentAudioRole.question,
    );

    expect(result, isA<FailureResult<void>>());
    expect((result as FailureResult<void>).failure.code, 'ASSET_NOT_AUDIO');
  });
}

ContentItem _interview() => const ContentItem(
  code: 'JAVA_INTERVIEW_Q1',
  type: ContentType.interview,
  title: 'Question',
  subtitle: 'Interview',
  description: 'Description',
  category: 'Java',
  level: 'B2',
  minutes: 2,
  revision: 3,
  hasAudio: true,
);

ContentItem _topic() => const ContentItem(
  code: 'JAVA_TOPIC_1',
  type: ContentType.topic,
  title: 'Topic',
  subtitle: 'Topic',
  description: 'Description',
  category: 'Java',
  level: 'B2',
  minutes: 2,
  revision: 3,
  hasAudio: true,
);

final class _FakeAudioEngine implements AudioPlaybackEngine {
  final List<_FakeSession> sessions = <_FakeSession>[];

  @override
  Future<Result<AudioPlaybackSession>> openLocal({
    required String path,
    required String mediaType,
  }) async {
    final session = _FakeSession();
    sessions.add(session);
    return Success<AudioPlaybackSession>(session);
  }

  Future<void> close() async {
    for (final session in sessions) {
      await session.close();
    }
  }
}

final class _FakeSession implements AudioPlaybackSession {
  final StreamController<AudioPlaybackEvent> _events =
      StreamController<AudioPlaybackEvent>.broadcast(sync: true);
  int stopCalls = 0;
  bool disposed = false;

  @override
  Duration? initialDuration = const Duration(seconds: 10);

  @override
  Stream<AudioPlaybackEvent> get events => _events.stream;

  @override
  Future<Result<void>> pause() async => const Success<void>(null);

  @override
  Future<Result<void>> play() async => const Success<void>(null);

  @override
  Future<Result<void>> seek(Duration position) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> stop() async {
    stopCalls += 1;
    return const Success<void>(null);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  Future<void> close() async {
    if (!_events.isClosed) await _events.close();
  }
}
