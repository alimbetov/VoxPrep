import 'dart:async';
import 'dart:io';

import 'package:careerspeak_app/app/asset_download_providers.dart';
import 'package:careerspeak_app/app/asset_resolver_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_asset_catalog_repository.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _checksum =
    '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
const _content = ContentIdentity(code: 'PHRASE_1', type: ContentType.phrase);

void main() {
  late Directory temporary;
  late Directory assets;
  late CareerSpeakDatabase database;
  late _ByteSource source;
  late AssetResolver resolver;

  CareerSpeakDatabase openDatabase() {
    return CareerSpeakDatabase(
      NativeDatabase(File('${temporary.path}/catalog.sqlite')),
    );
  }

  AssetResolver createResolver() {
    final store = FileSystemAssetStore(assets);
    return AssetResolver(
      catalog: DriftAssetCatalogRepository(database),
      store: store,
      downloads: AssetDownloadManager(
        source: source,
        store: store,
        maxAttempts: 1,
      ),
    );
  }

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('p2_8_assets_');
    assets = Directory('${temporary.path}/assets');
    database = openDatabase();
    source = _ByteSource();
    resolver = createResolver();
    await _seed(database);
  });

  tearDown(() async {
    await database.close();
    await temporary.delete(recursive: true);
  });

  test(
    'production providers connect CURRENT content to verified bytes',
    () async {
      final container = ProviderContainer(
        overrides: [
          careerSpeakDatabaseProvider.overrideWithValue(database),
          assetRootDirectoryProvider.overrideWith((ref) async => assets),
          assetByteSourceProvider.overrideWithValue(source),
        ],
      );
      addTearDown(container.dispose);
      expect(
        container.read(assetCatalogRepositoryProvider),
        isA<DriftAssetCatalogRepository>(),
      );
      final production = await container.read(assetResolverProvider.future);
      final result = await production.resolveContent(
        content: _content,
        revision: 1,
        role: 'promptAudio',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      final asset = result.getOrThrow();
      expect(asset.assetId, 'audio-1');
      expect(asset.mediaType, 'audio/mpeg');
      expect(await File(asset.localPath).readAsString(), 'hello');
      expect(source.calls, 1);

      final local = (await production.resolve('audio-1')).getOrThrow();
      expect(local.localPath, asset.localPath);
      expect(source.calls, 1);
      expect(database.schemaVersion, 18);
    },
  );

  test('localOnly never downloads even when requiredOffline is true', () async {
    final result = await resolver.resolve('audio-1');
    expect(_failureCode(result), 'ASSET_NOT_AVAILABLE_OFFLINE');
    expect(source.calls, 0);
    expect(await assets.exists(), isFalse);
  });

  test('download policy also reuses a verified local file', () async {
    final first = await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    final second = await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(second.getOrThrow().localPath, first.getOrThrow().localPath);
    expect(source.calls, 1);
  });

  test(
    'restart resolves the saved file with no network or credentials',
    () async {
      final downloaded = (await resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      )).getOrThrow();
      await database.close();
      database = openDatabase();
      source = _ByteSource()..failure = _offline;
      resolver = createResolver();

      final result = await resolver.resolveContent(
        content: _content,
        revision: 1,
        role: 'promptAudio',
      );
      expect(result.getOrThrow().localPath, downloaded.localPath);
      expect(await File(result.getOrThrow().localPath).readAsString(), 'hello');
      expect(source.calls, 0);
    },
  );

  test(
    'corrupt local bytes are rejected offline and repaired when allowed',
    () async {
      final first = (await resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      )).getOrThrow();
      await File(first.localPath).writeAsString('corrupt');
      source.failure = _offline;

      final offline = await resolver.resolve('audio-1');
      expect(_failureCode(offline), 'ASSET_NOT_AVAILABLE_OFFLINE');
      expect(await File(first.localPath).exists(), isFalse);

      source.failure = null;
      final repaired = await resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      expect(repaired, isA<Success<ResolvedAsset>>());
      expect(await File(repaired.getOrThrow().localPath).readAsString(), 'hello');
    },
  );

  test('does not return a source after ASSET_SIZE_MISMATCH', () async {
    source.bytes = 'hello!'.codeUnits;
    final result = await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(_failureCode(result), 'ASSET_SIZE_MISMATCH');
    expect(await assets.exists(), isTrue);
    expect(await assets.list().isEmpty, isTrue);
  });

  test('does not return a source after ASSET_CHECKSUM_MISMATCH', () async {
    source.bytes = 'HELLO'.codeUnits;
    final result = await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(_failureCode(result), 'ASSET_CHECKSUM_MISMATCH');
    expect(await assets.exists(), isTrue);
    expect(await assets.list().isEmpty, isTrue);
  });

  test('ignores an abandoned partial download', () async {
    await assets.create(recursive: true);
    final partial = File('${assets.path}/audio-1.partial');
    await partial.writeAsString('hello');

    final result = await resolver.resolve('audio-1');
    expect(_failureCode(result), 'ASSET_NOT_AVAILABLE_OFFLINE');
    expect(await partial.exists(), isTrue);
  });

  test('unknown assets and roles never reach the byte source', () async {
    final unknownAsset = await resolver.resolve(
      'missing',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    final unknownRole = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'sampleAnswerAudio',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(_failureCode(unknownAsset), 'ASSET_NOT_FOUND');
    expect(_failureCode(unknownRole), 'CONTENT_ASSET_NOT_FOUND');
    expect(source.calls, 0);
  });

  test('does not expose an asset from a STAGING pack', () async {
    await database.customStatement(
      "UPDATE pack_revisions SET lifecycle_state = 'STAGING'",
    );
    final result = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(_failureCode(result), 'CONTENT_ASSET_NOT_FOUND');
    expect(source.calls, 0);
  });

  test('does not expose an asset from a SUPERSEDED pack', () async {
    await database.customStatement(
      "UPDATE pack_revisions SET lifecycle_state = 'SUPERSEDED'",
    );
    final result = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(_failureCode(result), 'CONTENT_ASSET_NOT_FOUND');
    expect(source.calls, 0);
  });

  test('tombstoned content cannot resolve a previously cached file', () async {
    final downloaded = (await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    )).getOrThrow();
    expect(await File(downloaded.localPath).exists(), isTrue);
    await database.customStatement(
      "UPDATE contents SET tombstone_state = 'RETIRED' WHERE content_code = 'PHRASE_1'",
    );

    final result = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
    );
    expect(_failureCode(result), 'CONTENT_ASSET_NOT_FOUND');
    expect(await File(downloaded.localPath).exists(), isTrue);
  });

  test('selects exact content type, revision, role and pack variant', () async {
    await database.into(database.packRevisions).insert(
      PackRevisionsCompanion.insert(
        packCode: 'P2',
        variant: 'canonical',
        revision: 1,
        checksum: _checksum,
        lifecycleState: 'CURRENT',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await database.into(database.packContents).insert(
      PackContentsCompanion.insert(
        packCode: 'P2',
        variant: 'canonical',
        packRevision: 1,
        contentCode: 'PHRASE_1',
        contentType: ContentType.phrase.wireName,
        contentRevision: 1,
        contentChecksum: _checksum,
        sortOrder: 0,
      ),
    );
    await database.into(database.assetMetadata).insert(
      AssetMetadataCompanion.insert(
        assetId: 'audio-2',
        mediaType: 'audio/mpeg',
        checksum: _checksum,
        sizeBytes: 5,
        deliveryKey: 'audio/2.mp3',
        requiredOffline: false,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await database.into(database.packAssets).insert(
      PackAssetsCompanion.insert(
        packCode: 'P2',
        variant: 'canonical',
        packRevision: 1,
        assetId: 'audio-2',
      ),
    );
    await database.into(database.contentAssets).insert(
      ContentAssetsCompanion.insert(
        packCode: 'P2',
        variant: 'canonical',
        packRevision: 1,
        contentCode: 'PHRASE_1',
        contentType: ContentType.phrase.wireName,
        contentRevision: 1,
        role: 'sampleAnswerAudio',
        assetId: 'audio-2',
      ),
    );

    final prompt = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
    );
    final answer = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'sampleAnswerAudio',
    );
    expect(prompt.getOrThrow().assetId, 'audio-1');
    expect(answer.getOrThrow().assetId, 'audio-2');
  });

  test('repeated pack membership is not an ambiguous content role', () async {
    await database.into(database.packRevisions).insert(
      PackRevisionsCompanion.insert(
        packCode: 'P2',
        variant: 'canonical',
        revision: 1,
        checksum: _checksum,
        lifecycleState: 'CURRENT',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await database.into(database.packContents).insert(
      PackContentsCompanion.insert(
        packCode: 'P2',
        variant: 'canonical',
        packRevision: 1,
        contentCode: 'PHRASE_1',
        contentType: ContentType.phrase.wireName,
        contentRevision: 1,
        contentChecksum: _checksum,
        sortOrder: 0,
      ),
    );

    final result = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
    );
    expect(result.getOrThrow().assetId, 'audio-1');
  });

  test('multiple assets for the same role fail instead of choosing one', () async {
    await database.into(database.assetMetadata).insert(
      AssetMetadataCompanion.insert(
        assetId: 'audio-2',
        mediaType: 'audio/mpeg',
        checksum: _checksum,
        sizeBytes: 5,
        deliveryKey: 'audio/2.mp3',
        requiredOffline: false,
        createdAt: DateTime.now().toUtc(),
      ),
    );
    await database.into(database.packAssets).insert(
      PackAssetsCompanion.insert(
        packCode: 'P1',
        variant: 'canonical',
        packRevision: 1,
        assetId: 'audio-2',
      ),
    );
    await database.into(database.contentAssets).insert(
      ContentAssetsCompanion.insert(
        packCode: 'P1',
        variant: 'canonical',
        packRevision: 1,
        contentCode: 'PHRASE_1',
        contentType: ContentType.phrase.wireName,
        contentRevision: 1,
        role: 'promptAudio',
        assetId: 'audio-2',
      ),
    );

    final result = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
    );
    expect(_failureCode(result), 'CONTENT_ASSET_AMBIGUOUS');
  });

  test('content and asset membership must belong to the same pack revision', () async {
    await database.into(database.packRevisions).insert(
      PackRevisionsCompanion.insert(
        packCode: 'P1',
        variant: 'canonical',
        revision: 2,
        checksum: _checksum,
        lifecycleState: 'CURRENT',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await database.customStatement(
      "UPDATE pack_revisions SET lifecycle_state = 'SUPERSEDED' WHERE pack_code = 'P1' AND revision = 1",
    );

    final result = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
    );
    expect(_failureCode(result), 'CONTENT_ASSET_NOT_FOUND');
  });

  test('next lookup observes CURRENT activation without retaining old bindings', () async {
    final first = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
    );
    expect(first.getOrThrow().assetId, 'audio-1');

    await database.customStatement(
      "UPDATE pack_revisions SET lifecycle_state = 'SUPERSEDED' WHERE pack_code = 'P1' AND revision = 1",
    );
    await database.into(database.packRevisions).insert(
      PackRevisionsCompanion.insert(
        packCode: 'P1',
        variant: 'canonical',
        revision: 2,
        checksum: _checksum,
        lifecycleState: 'CURRENT',
        createdAt: DateTime.now().toUtc(),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    await database.into(database.packContents).insert(
      PackContentsCompanion.insert(
        packCode: 'P1',
        variant: 'canonical',
        packRevision: 2,
        contentCode: 'PHRASE_1',
        contentType: ContentType.phrase.wireName,
        contentRevision: 1,
        contentChecksum: _checksum,
        sortOrder: 0,
      ),
    );
    await database.into(database.packAssets).insert(
      PackAssetsCompanion.insert(
        packCode: 'P1',
        variant: 'canonical',
        packRevision: 2,
        assetId: 'audio-1',
      ),
    );
    await database.into(database.contentAssets).insert(
      ContentAssetsCompanion.insert(
        packCode: 'P1',
        variant: 'canonical',
        packRevision: 2,
        contentCode: 'PHRASE_1',
        contentType: ContentType.phrase.wireName,
        contentRevision: 1,
        role: 'promptAudio',
        assetId: 'audio-1',
      ),
    );

    final second = await resolver.resolveContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
    );
    expect(second.getOrThrow().assetId, 'audio-1');
  });

  test('concurrent downloads coalesce while localOnly remains independent', () async {
    final gate = Completer<void>();
    source.gate = gate.future;
    final first = resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    final second = resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    final localOnly = await resolver.resolve('audio-1');
    expect(_failureCode(localOnly), 'ASSET_NOT_AVAILABLE_OFFLINE');
    expect(source.calls, 1);

    gate.complete();
    expect((await first).getOrThrow().assetId, 'audio-1');
    expect((await second).getOrThrow().assetId, 'audio-1');
    expect(source.calls, 1);
  });

  test('preserves delivery failures and allows a new attempt after failure', () async {
    source.failure = const ApplicationFailure(
      code: 'ASSET_DELIVERY_UNAUTHORIZED',
      message: 'denied',
    );
    final first = await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(_failureCode(first), 'ASSET_DELIVERY_UNAUTHORIZED');

    source.failure = null;
    final second = await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(second, isA<Success<ResolvedAsset>>());
    expect(source.calls, 2);
  });

  test('invalid persisted descriptors fail before file or network access', () async {
    await database.customStatement(
      "UPDATE asset_metadata SET checksum = 'bad' WHERE asset_id = 'audio-1'",
    );
    final result = await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(_failureCode(result), 'ASSET_METADATA_INVALID');
    expect(source.calls, 0);
  });
}

Future<void> _seed(CareerSpeakDatabase database) async {
  final now = DateTime.now().toUtc();
  await database.into(database.packRevisions).insert(
    PackRevisionsCompanion.insert(
      packCode: 'P1',
      variant: 'canonical',
      revision: 1,
      checksum: _checksum,
      lifecycleState: 'CURRENT',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await database.into(database.contents).insert(
    ContentsCompanion.insert(
      contentCode: 'PHRASE_1',
      contentType: ContentType.phrase.wireName,
      revision: 1,
      checksum: _checksum,
      title: 'Hello',
      subtitle: 'Greeting',
      description: 'Greeting',
      categoryCode: 'GENERAL',
      categoryLabel: 'General',
      levelCode: 'A1',
      levelLabel: 'A1',
      minutes: 1,
      hasAudio: true,
      skillCodesJson: '[]',
      bodyJson: '{}',
      tombstoneState: 'ACTIVE',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await database.into(database.packContents).insert(
    PackContentsCompanion.insert(
      packCode: 'P1',
      variant: 'canonical',
      packRevision: 1,
      contentCode: 'PHRASE_1',
      contentType: ContentType.phrase.wireName,
      contentRevision: 1,
      contentChecksum: _checksum,
      sortOrder: 0,
    ),
  );
  await database.into(database.assetMetadata).insert(
    AssetMetadataCompanion.insert(
      assetId: 'audio-1',
      mediaType: 'audio/mpeg',
      checksum: _checksum,
      sizeBytes: 5,
      deliveryKey: 'audio/1.mp3',
      requiredOffline: true,
      createdAt: now,
    ),
  );
  await database.into(database.packAssets).insert(
    PackAssetsCompanion.insert(
      packCode: 'P1',
      variant: 'canonical',
      packRevision: 1,
      assetId: 'audio-1',
    ),
  );
  await database.into(database.contentAssets).insert(
    ContentAssetsCompanion.insert(
      packCode: 'P1',
      variant: 'canonical',
      packRevision: 1,
      contentCode: 'PHRASE_1',
      contentType: ContentType.phrase.wireName,
      contentRevision: 1,
      role: 'promptAudio',
      assetId: 'audio-1',
    ),
  );
}

String? _failureCode<T>(Result<T> result) {
  return switch (result) {
    FailureResult<T>(:final failure) => failure.code,
    Success<T>() => null,
  };
}

const _offline = ApplicationFailure(
  code: 'NETWORK_OFFLINE',
  message: 'offline',
  retryable: true,
);

final class _ByteSource implements AssetByteSource {
  List<int> bytes = 'hello'.codeUnits;
  ApplicationFailure? failure;
  Future<void>? gate;
  int calls = 0;

  @override
  Future<Result<AssetByteResponse>> fetch(AssetDescriptor asset) async {
    calls += 1;
    final gate = this.gate;
    if (gate != null) await gate;
    final failure = this.failure;
    if (failure != null) return FailureResult<AssetByteResponse>(failure);
    return Success<AssetByteResponse>(
      AssetByteResponse(bytes: bytes, contentLength: bytes.length),
    );
  }
}
