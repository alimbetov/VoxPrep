import 'dart:async';
import 'dart:io';

import 'package:careerspeak_app/app/asset_resolver_providers.dart';
import 'package:careerspeak_app/app/audio_playback_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/content_delivery/asset_retention.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/ports/asset_cache_retention_repository.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/ports/audio_playback_engine.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_cache_retention_manager.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/content/content_detail_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _checksum =
    '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a';
const _goodBytes = <int>[1, 2, 3, 4];
const _badBytes = <int>[4, 3, 2, 1];

void main() {
  testWidgets(
    'corrupted local audio is discarded and exact asset is redownloaded',
    (tester) async {
      final scenario = await _Scenario.create();
      addTearDown(scenario.dispose);
      await scenario.pump(tester);

      await scenario.play(tester);
      expect(scenario.source.openCount, 1);
      final path = scenario.engine.lastOpenedPath!;

      await scenario.stop(tester);
      await File(path).writeAsBytes(_badBytes, flush: true);
      expect(await File(path).readAsBytes(), _badBytes);

      await scenario.play(tester);

      expect(scenario.source.openCount, 2);
      expect(scenario.engine.openCount, 2);
      expect(await File(path).readAsBytes(), _goodBytes);
      expect(find.text('Pause'), findsOneWidget);
    },
  );

  testWidgets(
    'bad checksum download fails closed and is never opened by player',
    (tester) async {
      final scenario = await _Scenario.create(sourceBytes: _badBytes);
      addTearDown(scenario.dispose);
      await scenario.pump(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Play'));
      await tester.pumpAndSettle();

      expect(scenario.source.openCount, 1);
      expect(scenario.engine.openCount, 0);
      expect(find.textContaining('checksum'), findsWidgets);
      expect(find.text('Play'), findsOneWidget);
    },
  );

  testWidgets(
    'offline after eviction exhausts retries without inventing local audio',
    (tester) async {
      final scenario = await _Scenario.create();
      addTearDown(scenario.dispose);
      await scenario.pump(tester);

      await scenario.play(tester);
      scenario.engine.latestSession.complete();
      await tester.pumpAndSettle();
      final path = scenario.engine.lastOpenedPath!;

      await scenario.expireAndEvict();
      expect(await File(path).exists(), isFalse);

      scenario.source.online = false;
      await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
      await tester.pumpAndSettle();

      expect(
        scenario.source.openCount,
        4,
      ); // first success + three offline attempts
      expect(scenario.engine.openCount, 1);
      expect(await File(path).exists(), isFalse);
      expect(find.textContaining('offline'), findsWidgets);
      expect(find.text('Play'), findsOneWidget);
    },
  );

  testWidgets('next Play redownloads exact audio after network recovery', (
    tester,
  ) async {
    final scenario = await _Scenario.create();
    addTearDown(scenario.dispose);
    await scenario.pump(tester);

    await scenario.play(tester);
    scenario.engine.latestSession.complete();
    await tester.pumpAndSettle();
    final path = scenario.engine.lastOpenedPath!;

    await scenario.expireAndEvict();
    scenario.source.online = false;
    await tester.tap(find.widgetWithText(FilledButton, 'Replay'));
    await tester.pumpAndSettle();
    expect(scenario.source.openCount, 4);
    expect(await File(path).exists(), isFalse);

    scenario.source.online = true;
    await tester.tap(find.widgetWithText(FilledButton, 'Play'));
    await tester.pumpAndSettle();

    expect(scenario.source.openCount, 5);
    expect(scenario.engine.openCount, 2);
    expect(scenario.engine.lastOpenedPath, path);
    expect(await File(path).readAsBytes(), _goodBytes);
    expect(find.text('Pause'), findsOneWidget);
  });
}

const _topic = ContentItem(
  code: 'TOPIC_AUDIO_ADVERSARIAL',
  type: ContentType.topic,
  title: 'Topic audio adversarial',
  subtitle: 'Delivery hardening',
  description: 'Attacks corruption, checksum and offline recovery.',
  category: 'JAVA',
  level: 'B2',
  minutes: 2,
  revision: 2,
  hasAudio: true,
);

final class _Scenario {
  _Scenario._({
    required this.directory,
    required this.source,
    required this.store,
    required this.retention,
    required this.resolver,
    required this.engine,
    required this.learnerState,
    required this.readNow,
    required this.advanceNow,
  });

  final Directory directory;
  final _SwitchableSource source;
  final FileSystemAssetStore store;
  final _MemoryRetentionRepository retention;
  final AssetResolver resolver;
  final _FakePlaybackEngine engine;
  final _ReactiveLearnerStateRepository learnerState;
  final DateTime Function() readNow;
  final void Function(Duration duration) advanceNow;

  static Future<_Scenario> create({List<int> sourceBytes = _goodBytes}) async {
    final directory = await Directory.systemTemp.createTemp(
      'careerspeak-content-detail-audio-adversarial-',
    );
    var now = DateTime.utc(2026, 1, 1);
    final descriptor = ManifestAssetDescriptor(
      assetId: 'topic-narration-r2',
      checksumSha256: _checksum,
      deliveryKey: 'audio/topic/narration-r2.mp3',
      sizeBytes: _goodBytes.length,
      mediaType: 'audio/mpeg',
      requiredOffline: false,
    );
    final source = _SwitchableSource(sourceBytes);
    final store = FileSystemAssetStore(directory, now: () => now);
    final retention = _MemoryRetentionRepository(() => now);
    final resolver = AssetResolver(
      catalog: _Catalog(descriptor),
      store: store,
      downloads: AssetDownloadManager(
        source: source,
        store: store,
        maxAttempts: 3,
        delay: (_) async {},
      ),
      retention: retention,
    );
    return _Scenario._(
      directory: directory,
      source: source,
      store: store,
      retention: retention,
      resolver: resolver,
      engine: _FakePlaybackEngine(),
      learnerState: _ReactiveLearnerStateRepository(),
      readNow: () => now,
      advanceNow: (duration) => now = now.add(duration),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerStateRepositoryProvider.overrideWithValue(learnerState),
          assetResolverProvider.overrideWith((ref) async => resolver),
          audioPlaybackEngineProvider.overrideWithValue(engine),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ContentDetailPanel(item: _topic)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> play(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Play'));
    await tester.pumpAndSettle();
  }

  Future<void> stop(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(OutlinedButton, 'Stop'));
    await tester.pumpAndSettle();
  }

  Future<void> expireAndEvict() async {
    advanceNow(const Duration(days: 100));
    final result = await AssetCacheRetentionManager(
      retention: retention,
      evictionStore: store,
      audioTtl: const Duration(days: 90),
      now: readNow,
    ).cleanupExpiredAudio();
    expect(result, isA<Success<AssetRetentionCleanupReport>>());
    expect((result as Success<AssetRetentionCleanupReport>).value.evicted, 1);
  }

  Future<void> dispose() async {
    await learnerState.dispose();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}

final class _SwitchableSource implements AssetByteSource {
  _SwitchableSource(this.bytes);

  List<int> bytes;
  bool online = true;
  int openCount = 0;

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    openCount += 1;
    if (!online) {
      return const FailureResult<AssetByteStream>(
        ApplicationFailure(
          code: 'TEST_NETWORK_OFFLINE',
          message: 'The audio source is offline.',
          retryable: true,
        ),
      );
    }
    return Success<AssetByteStream>(
      AssetByteStream(
        bytes: Stream<List<int>>.value(bytes),
        contentLength: bytes.length,
      ),
    );
  }
}

final class _Catalog implements AssetCatalogRepository {
  const _Catalog(this.asset);

  final ManifestAssetDescriptor asset;

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(
    String assetId,
  ) async => Success<ManifestAssetDescriptor?>(
    assetId == asset.assetId ? asset : null,
  );

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async {
    if (content != ContentIdentity.fromItem(_topic) ||
        revision != _topic.revision ||
        role != 'narration') {
      return const Success<ManifestAssetDescriptor?>(null);
    }
    return Success<ManifestAssetDescriptor?>(asset);
  }
}

final class _FakePlaybackEngine implements AudioPlaybackEngine {
  int openCount = 0;
  String? lastOpenedPath;
  _FakePlaybackSession? _latestSession;

  _FakePlaybackSession get latestSession => _latestSession!;

  @override
  Future<Result<AudioPlaybackSession>> openLocal({
    required String path,
    required String mediaType,
  }) async {
    if (!await File(path).exists()) {
      return const FailureResult<AudioPlaybackSession>(
        ApplicationFailure(
          code: 'TEST_AUDIO_FILE_MISSING',
          message: 'Resolved audio file does not exist.',
        ),
      );
    }
    openCount += 1;
    lastOpenedPath = path;
    final session = _FakePlaybackSession();
    _latestSession = session;
    return Success<AudioPlaybackSession>(session);
  }
}

final class _FakePlaybackSession implements AudioPlaybackSession {
  final StreamController<AudioPlaybackEvent> _events =
      StreamController<AudioPlaybackEvent>.broadcast();

  @override
  Duration? get initialDuration => const Duration(seconds: 30);

  @override
  Stream<AudioPlaybackEvent> get events => _events.stream;

  void complete() {
    _events.add(const AudioPositionChanged(Duration(seconds: 30)));
    _events.add(const AudioPlaybackCompleted());
  }

  @override
  Future<Result<void>> pause() async => const Success<void>(null);

  @override
  Future<Result<void>> play() async => const Success<void>(null);

  @override
  Future<Result<void>> seek(Duration position) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> stop() async => const Success<void>(null);

  @override
  Future<void> dispose() async => _events.close();
}

final class _ReactiveLearnerStateRepository implements LearnerStateRepository {
  final Map<ContentIdentity, ContentMarkerState> current =
      <ContentIdentity, ContentMarkerState>{};
  final StreamController<Result<Map<ContentIdentity, ContentMarkerState>>>
  _changes =
      StreamController<
        Result<Map<ContentIdentity, ContentMarkerState>>
      >.broadcast();

  void _emit() {
    _changes.add(
      Success<Map<ContentIdentity, ContentMarkerState>>(
        Map<ContentIdentity, ContentMarkerState>.unmodifiable(current),
      ),
    );
  }

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>>
  watchMarkers() async* {
    yield Success<Map<ContentIdentity, ContentMarkerState>>(
      Map<ContentIdentity, ContentMarkerState>.unmodifiable(current),
    );
    yield* _changes.stream;
  }

  @override
  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  }) async {
    current[identity] = (current[identity] ?? const ContentMarkerState())
        .copyWith(favorite: favorite);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  }) async {
    current[identity] = (current[identity] ?? const ContentMarkerState())
        .copyWith(listened: listened, lastRevisionSeen: lastRevisionSeen);
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
    current[identity] = (current[identity] ?? const ContentMarkerState())
        .copyWith(completed: completed, lastRevisionSeen: lastRevisionSeen);
    _emit();
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async {
    current[identity] = (current[identity] ?? const ContentMarkerState())
        .copyWith(
          lastPositionMs: positionMs,
          lastRevisionSeen: lastRevisionSeen,
        );
    _emit();
    return const Success<void>(null);
  }

  Future<void> dispose() => _changes.close();
}

final class _MemoryRetentionRepository
    implements AssetCacheRetentionRepository {
  _MemoryRetentionRepository(this._now);

  final DateTime Function() _now;
  AssetRetentionEntry? entry;

  @override
  Future<Result<void>> recordAccess({
    required ManifestAssetDescriptor asset,
    AssetRetentionClass retentionClass = AssetRetentionClass.autoCache,
  }) async {
    final previous = entry;
    final effectiveClass =
        previous != null &&
            previous.retentionClass != AssetRetentionClass.autoCache
        ? previous.retentionClass
        : retentionClass;
    entry = AssetRetentionEntry(
      asset: asset,
      retentionClass: effectiveClass,
      cachedAt: previous?.cachedAt ?? _now(),
      lastAccessedAt: _now(),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AssetRetentionEntry>>> findExpiredAutoCache({
    required DateTime accessedBefore,
    int limit = 100,
  }) async {
    final currentEntry = entry;
    if (currentEntry == null ||
        currentEntry.retentionClass != AssetRetentionClass.autoCache ||
        currentEntry.asset.requiredOffline ||
        !currentEntry.asset.mediaType.startsWith('audio/') ||
        !currentEntry.lastAccessedAt.isBefore(accessedBefore)) {
      return const Success<List<AssetRetentionEntry>>(<AssetRetentionEntry>[]);
    }
    return Success<List<AssetRetentionEntry>>(<AssetRetentionEntry>[
      currentEntry,
    ]);
  }

  @override
  Future<Result<void>> forget(String assetId) async {
    if (entry?.asset.assetId == assetId) entry = null;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setRetentionClass({
    required String assetId,
    required AssetRetentionClass retentionClass,
  }) async {
    final currentEntry = entry;
    if (currentEntry != null && currentEntry.asset.assetId == assetId) {
      entry = AssetRetentionEntry(
        asset: currentEntry.asset,
        retentionClass: retentionClass,
        cachedAt: currentEntry.cachedAt,
        lastAccessedAt: currentEntry.lastAccessedAt,
      );
    }
    return const Success<void>(null);
  }
}
