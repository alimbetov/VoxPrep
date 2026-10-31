import 'package:careerspeak_app/app/asset_resolver_providers.dart';
import 'package:careerspeak_app/app/audio_playback_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/content_delivery/content_audio_policy.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/audio_playback_controller.dart'
    as content_audio;
import 'package:careerspeak_app/application/services/role_audio_clip_controller.dart'
    as role_audio;
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/content/content_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  testWidgets('INTERVIEW shows only QUESTION when sample answer is absent', (
    tester,
  ) async {
    await _pump(
      tester,
      item: _interview,
      repository: _FakeLearnerStateRepository(),
      assetCatalog: const _RoleCatalog(<String>{'question'}),
    );

    expect(find.text('Question'), findsOneWidget);
    expect(find.text('Sample answer'), findsNothing);
    expect(
      find.text('No interview audio is published for this revision.'),
      findsNothing,
    );
  });

  testWidgets('INTERVIEW shows only SAMPLE_ANSWER when question is absent', (
    tester,
  ) async {
    await _pump(
      tester,
      item: _interview,
      repository: _FakeLearnerStateRepository(),
      assetCatalog: const _RoleCatalog(<String>{'sampleAnswer'}),
    );

    expect(find.text('Question'), findsNothing);
    expect(find.text('Sample answer'), findsOneWidget);
  });

  testWidgets(
    'INTERVIEW renders explicit empty audio state when no roles exist',
    (tester) async {
      await _pump(
        tester,
        item: _interview,
        repository: _FakeLearnerStateRepository(),
        assetCatalog: const _RoleCatalog(<String>{}),
      );

      expect(
        find.text('No interview audio is published for this revision.'),
        findsOneWidget,
      );
      expect(find.text('Question'), findsNothing);
      expect(find.text('Sample answer'), findsNothing);
    },
  );

  testWidgets(
    'INTERVIEW exposes metadata failure instead of phantom controls',
    (tester) async {
      await _pump(
        tester,
        item: _interview,
        repository: _FakeLearnerStateRepository(),
        assetCatalog: const _FailingRoleCatalog(),
      );

      expect(
        find.textContaining('Interview audio metadata unavailable:'),
        findsOneWidget,
      );
      expect(find.text('Question'), findsNothing);
      expect(find.text('Sample answer'), findsNothing);
    },
  );

  testWidgets('INTERVIEW playback failure is learner-visible', (tester) async {
    await _pump(
      tester,
      item: _interview,
      repository: _FakeLearnerStateRepository(),
      assetCatalog: const _RoleCatalog(<String>{'question'}),
      roleState: const role_audio.RoleAudioClipState(
        phase: role_audio.AudioPlaybackPhase.failed,
        role: ContentAudioRole.question,
        failure: ApplicationFailure(
          code: 'SYNTHETIC_PLAYBACK_FAILURE',
          message: 'synthetic playback failure',
        ),
      ),
    );

    expect(find.text('synthetic playback failure'), findsOneWidget);
  });

  testWidgets(
    'generic audio failure is shown only for current exact revision',
    (tester) async {
      final identity = ContentIdentity.fromItem(_topicWithAudio);
      await _pump(
        tester,
        item: _topicWithAudio,
        repository: _FakeLearnerStateRepository(),
        assetCatalog: const _RoleCatalog(<String>{}),
        playbackState: content_audio.ContentPlaybackState(
          phase: content_audio.AudioPlaybackPhase.failed,
          content: identity,
          revision: _topicWithAudio.revision,
          failure: const ApplicationFailure(
            code: 'SYNTHETIC_GENERIC_AUDIO_FAILURE',
            message: 'generic playback failed',
          ),
        ),
      );

      expect(find.text('generic playback failed'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
    },
  );

  testWidgets('stale playback failure from another item never leaks into UI', (
    tester,
  ) async {
    await _pump(
      tester,
      item: _topicWithAudio,
      repository: _FakeLearnerStateRepository(),
      assetCatalog: const _RoleCatalog(<String>{}),
      playbackState: const content_audio.ContentPlaybackState(
        phase: content_audio.AudioPlaybackPhase.failed,
        content: ContentIdentity(code: 'OTHER_TOPIC', type: ContentType.topic),
        revision: 99,
        failure: ApplicationFailure(
          code: 'STALE_FAILURE',
          message: 'must not leak',
        ),
      ),
    );

    expect(find.text('must not leak'), findsNothing);
    expect(find.text('Play'), findsOneWidget);
  });

  testWidgets('completed generic audio exposes Replay for current revision', (
    tester,
  ) async {
    final identity = ContentIdentity.fromItem(_topicWithAudio);
    await _pump(
      tester,
      item: _topicWithAudio,
      repository: _FakeLearnerStateRepository(),
      assetCatalog: const _RoleCatalog(<String>{}),
      playbackState: content_audio.ContentPlaybackState(
        phase: content_audio.AudioPlaybackPhase.completed,
        content: identity,
        revision: _topicWithAudio.revision,
        positionMs: 60000,
        durationMs: 60000,
      ),
    );

    expect(find.text('Replay'), findsOneWidget);
  });

  testWidgets('idle generic audio disables seek and stop controls', (
    tester,
  ) async {
    await _pump(
      tester,
      item: _topicWithAudio,
      repository: _FakeLearnerStateRepository(),
      assetCatalog: const _RoleCatalog(<String>{}),
    );

    expect(
      tester.widget<IconButton>(find.byTooltip('Back 10 seconds')).onPressed,
      isNull,
    );
    expect(
      tester.widget<IconButton>(find.byTooltip('Forward 10 seconds')).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Stop'))
          .onPressed,
      isNull,
    );
  });

  testWidgets('stale saved position is not resumed for a newer revision', (
    tester,
  ) async {
    final identity = ContentIdentity.fromItem(_topicNoAudio);
    final repository = _FakeLearnerStateRepository(
      markers: <ContentIdentity, ContentMarkerState>{
        identity: const ContentMarkerState(
          lastPositionMs: 42000,
          lastRevisionSeen: 1,
        ),
      },
    );

    await _pump(
      tester,
      item: _topicNoAudio,
      repository: repository,
      assetCatalog: const _RoleCatalog(<String>{}),
    );

    expect(
      find.text('Saved playback position belongs to an older revision.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'favorite write failure is surfaced and current state is preserved',
    (tester) async {
      final repository = _FakeLearnerStateRepository(failWrites: true);
      await _pump(
        tester,
        item: _topicNoAudio,
        repository: repository,
        assetCatalog: const _RoleCatalog(<String>{}),
      );

      await tester.tap(find.byTooltip('Add favorite'));
      await tester.pump();

      expect(
        find.textContaining('Unable to update learner state:'),
        findsOneWidget,
      );
      expect(find.byTooltip('Add favorite'), findsOneWidget);
    },
  );

  testWidgets(
    'completed write failure is surfaced and does not fake completion',
    (tester) async {
      final repository = _FakeLearnerStateRepository(failWrites: true);
      await _pump(
        tester,
        item: _topicNoAudio,
        repository: repository,
        assetCatalog: const _RoleCatalog(<String>{}),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Mark completed'));
      await tester.pump();

      expect(
        find.textContaining('Unable to update learner state:'),
        findsOneWidget,
      );
      expect(find.text('Mark completed'), findsOneWidget);
    },
  );

  testWidgets('content without audio never renders playback controls', (
    tester,
  ) async {
    await _pump(
      tester,
      item: _topicNoAudio,
      repository: _FakeLearnerStateRepository(),
      assetCatalog: const _RoleCatalog(<String>{}),
    );

    expect(find.text('Interview audio'), findsNothing);
    expect(find.text('Audio'), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required ContentItem item,
  required LearnerStateRepository repository,
  required AssetCatalogRepository assetCatalog,
  role_audio.RoleAudioClipState roleState =
      const role_audio.RoleAudioClipState(),
  content_audio.ContentPlaybackState playbackState =
      const content_audio.ContentPlaybackState(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerStateRepositoryProvider.overrideWithValue(repository),
        assetCatalogRepositoryProvider.overrideWithValue(assetCatalog),
        interviewAudioClipStateProvider.overrideWith(
          (ref) => Stream<role_audio.RoleAudioClipState>.value(roleState),
        ),
        audioPlaybackStateProvider.overrideWith(
          (ref) =>
              Stream<content_audio.ContentPlaybackState>.value(playbackState),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(body: ContentDetailPanel(item: item)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _interview = ContentItem(
  code: 'INTERVIEW_ALPHA',
  type: ContentType.interview,
  title: 'Interview alpha',
  subtitle: 'Interview subtitle',
  description: 'Interview description',
  category: 'JAVA',
  level: 'B2',
  minutes: 4,
  revision: 3,
  hasAudio: true,
);

const _topicWithAudio = ContentItem(
  code: 'TOPIC_AUDIO',
  type: ContentType.topic,
  title: 'Topic with audio',
  subtitle: 'Topic subtitle',
  description: 'Topic description',
  category: 'JAVA',
  level: 'B2',
  minutes: 4,
  revision: 2,
  hasAudio: true,
);

const _topicNoAudio = ContentItem(
  code: 'TOPIC_ALPHA',
  type: ContentType.topic,
  title: 'Topic alpha',
  subtitle: 'Topic subtitle',
  description: 'Topic description',
  category: 'JAVA',
  level: 'B2',
  minutes: 4,
  revision: 2,
  hasAudio: false,
);

final class _FakeLearnerStateRepository implements LearnerStateRepository {
  _FakeLearnerStateRepository({
    Map<ContentIdentity, ContentMarkerState>? markers,
    this.failWrites = false,
  }) : markers = markers ?? <ContentIdentity, ContentMarkerState>{};

  final Map<ContentIdentity, ContentMarkerState> markers;
  final bool failWrites;

  Result<void> _writeResult() => failWrites
      ? const FailureResult<void>(
          ApplicationFailure(
            code: 'SYNTHETIC_LEARNER_WRITE_FAILURE',
            message: 'synthetic learner write failure',
          ),
        )
      : const Success<void>(null);

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() =>
      Stream<Result<Map<ContentIdentity, ContentMarkerState>>>.value(
        Success<Map<ContentIdentity, ContentMarkerState>>(markers),
      );

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async => _writeResult();

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async => _writeResult();

  @override
  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  }) async => _writeResult();

  @override
  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  }) async => _writeResult();
}

final class _RoleCatalog implements AssetCatalogRepository {
  const _RoleCatalog(this.roles);

  final Set<String> roles;

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(
    String assetId,
  ) async => const Success<ManifestAssetDescriptor?>(null);

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async {
    if (!roles.contains(role)) {
      return const Success<ManifestAssetDescriptor?>(null);
    }
    return Success<ManifestAssetDescriptor?>(
      ManifestAssetDescriptor(
        assetId: 'asset-$role',
        checksumSha256: _hash,
        deliveryKey: 'audio/asset-$role.mp3',
        sizeBytes: 4,
        mediaType: 'audio/mpeg',
        requiredOffline: false,
      ),
    );
  }
}

final class _FailingRoleCatalog implements AssetCatalogRepository {
  const _FailingRoleCatalog();

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(
    String assetId,
  ) async => const FailureResult<ManifestAssetDescriptor?>(
    ApplicationFailure(
      code: 'SYNTHETIC_ASSET_CATALOG_FAILURE',
      message: 'synthetic asset catalogue failure',
    ),
  );

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async => const FailureResult<ManifestAssetDescriptor?>(
    ApplicationFailure(
      code: 'SYNTHETIC_ASSET_CATALOG_FAILURE',
      message: 'synthetic asset catalogue failure',
    ),
  );
}
