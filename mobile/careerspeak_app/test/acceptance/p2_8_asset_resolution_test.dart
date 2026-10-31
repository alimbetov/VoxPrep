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
      expect(database.schemaVersion, 8);
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
      await File(first.localPath).writeAsString('jello');

      final offline = await resolver.resolve('audio-1');
      expect(_failureCode(offline), 'ASSET_NOT_AVAILABLE_OFFLINE');
      expect(source.calls, 1);

      final repaired = await resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      expect(
        await File(repaired.getOrThrow().localPath).readAsString(),
        'hello',
      );
      expect(source.calls, 2);
    },
  );

  for (final invalid in <String, String>{
    'bad': 'ASSET_SIZE_MISMATCH',
    'wrong': 'ASSET_CHECKSUM_MISMATCH',
  }.entries) {
    test('does not return a source after ${invalid.value}', () async {
      source.payload = invalid.key;
      final result = await resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      expect(_failureCode(result), invalid.value);
      if (await assets.exists()) {
        expect(
          await assets.list(recursive: true).where((e) => e is File).toList(),
          isEmpty,
        );
      }
    });
  }

  test('ignores an abandoned partial download', () async {
    await assets.create(recursive: true);
    await File('${assets.path}/abandoned.part').writeAsString('hello');
    expect(
      _failureCode(await resolver.resolve('audio-1')),
      'ASSET_NOT_AVAILABLE_OFFLINE',
    );
    expect(source.calls, 0);
  });

  test('unknown assets and roles never reach the byte source', () async {
    expect(
      _failureCode(
        await resolver.resolve(
          'unknown',
          policy: AssetResolutionPolicy.downloadIfMissing,
        ),
      ),
      'ASSET_NOT_CURRENT',
    );
    expect(
      _failureCode(
        await resolver.resolveContent(
          content: _content,
          revision: 1,
          role: 'missingRole',
          policy: AssetResolutionPolicy.downloadIfMissing,
        ),
      ),
      'ASSET_NOT_CURRENT',
    );
    expect(source.calls, 0);
  });

  for (final state in ['STAGING', 'SUPERSEDED']) {
    test('does not expose an asset from a $state pack', () async {
      await database.customStatement(
        'UPDATE content_pack_revisions SET state = ?',
        [state],
      );
      expect(
        _failureCode(await resolver.resolve('audio-1')),
        'ASSET_NOT_CURRENT',
      );
      expect(
        _failureCode(
          await resolver.resolveContent(
            content: _content,
            revision: 1,
            role: 'promptAudio',
          ),
        ),
        'ASSET_NOT_CURRENT',
      );
      expect(source.calls, 0);
    });
  }

  test('tombstoned content cannot resolve a previously cached file', () async {
    await resolver.resolve(
      'audio-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    await database.customStatement(
      "UPDATE local_content_records SET snapshot_state = 'TOMBSTONED'",
    );
    expect(
      _failureCode(
        await resolver.resolveContent(
          content: _content,
          revision: 1,
          role: 'promptAudio',
        ),
      ),
      'ASSET_NOT_CURRENT',
    );
    expect(source.calls, 1);
  });

  test('selects exact content type, revision, role and pack variant', () async {
    await _seed(database, assetId: 'audio-ru', variant: 'locale:ru');
    final catalog = DriftAssetCatalogRepository(database);
    final canonical = await catalog.findCurrentForContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
    );
    final russian = await catalog.findCurrentForContent(
      content: _content,
      revision: 1,
      role: 'promptAudio',
      variant: 'locale:ru',
    );
    expect(canonical.getOrThrow()!.assetId, 'audio-1');
    expect(russian.getOrThrow()!.assetId, 'audio-ru');
    for (final query in [
      catalog.findCurrentForContent(
        content: _content,
        revision: 2,
        role: 'promptAudio',
      ),
      catalog.findCurrentForContent(
        content: const ContentIdentity(
          code: 'PHRASE_1',
          type: ContentType.interview,
        ),
        revision: 1,
        role: 'promptAudio',
      ),
      catalog.findCurrentForContent(
        content: _content,
        revision: 1,
        role: 'promptAudio',
        variant: 'locale:kk',
      ),
    ]) {
      expect((await query).getOrThrow(), isNull);
    }
  });

  test('repeated pack membership is not an ambiguous content role', () async {
    await _seed(database, packCode: 'SECOND_PACK');
    final result = await DriftAssetCatalogRepository(database)
        .findCurrentForContent(
          content: _content,
          revision: 1,
          role: 'promptAudio',
        );
    expect(result.getOrThrow()!.assetId, 'audio-1');
    expect(result.getOrThrow()!.requiredOffline, isTrue);
  });

  test(
    'multiple assets for the same role fail instead of choosing one',
    () async {
      await _seed(database, assetId: 'audio-2');
      final result = await resolver.resolveContent(
        content: _content,
        revision: 1,
        role: 'promptAudio',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      expect(_failureCode(result), 'ASSET_REFERENCE_AMBIGUOUS');
      expect(source.calls, 0);
    },
  );

  test(
    'content and asset membership must belong to the same pack revision',
    () async {
      await database.customStatement(
        'UPDATE pack_asset_refs SET pack_revision = 2',
      );
      expect(
        _failureCode(
          await resolver.resolveContent(
            content: _content,
            revision: 1,
            role: 'promptAudio',
          ),
        ),
        'ASSET_NOT_CURRENT',
      );
    },
  );

  test(
    'next lookup observes CURRENT activation without retaining old bindings',
    () async {
      await resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      await database.transaction(() async {
        await database.customStatement(
          "UPDATE content_pack_revisions SET state = 'SUPERSEDED'",
        );
        await database.customStatement(
          "UPDATE local_content_records SET snapshot_state = 'SUPERSEDED'",
        );
        await _seed(database, revision: 2, assetId: 'audio-2');
      });
      expect(
        _failureCode(await resolver.resolve('audio-1')),
        'ASSET_NOT_CURRENT',
      );
      expect(
        _failureCode(
          await resolver.resolveContent(
            content: _content,
            revision: 1,
            role: 'promptAudio',
          ),
        ),
        'ASSET_NOT_CURRENT',
      );
      final current = await resolver.resolveContent(
        content: _content,
        revision: 2,
        role: 'promptAudio',
      );
      expect(current.getOrThrow().assetId, 'audio-2');
      expect(source.calls, 1);
    },
  );

  test(
    'concurrent downloads coalesce while localOnly remains independent',
    () async {
      final gate = Completer<void>();
      source.gate = gate.future;
      final first = resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      await source.opened.future;
      final second = resolver.resolveContent(
        content: _content,
        revision: 1,
        role: 'promptAudio',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      final local = await resolver.resolve('audio-1');
      expect(_failureCode(local), 'ASSET_NOT_AVAILABLE_OFFLINE');
      gate.complete();
      final results = await Future.wait([first, second]);
      expect(
        results[0].getOrThrow().localPath,
        results[1].getOrThrow().localPath,
      );
      expect(source.calls, 1);
    },
  );

  test(
    'preserves delivery failures and allows a new attempt after failure',
    () async {
      source.failure = _offline;
      final failed = await resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      expect((failed as FailureResult<ResolvedAsset>).failure, same(_offline));
      source.failure = null;
      final retried = await resolver.resolve(
        'audio-1',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      expect(retried, isA<Success<ResolvedAsset>>());
      expect(source.calls, 2);
    },
  );

  test(
    'invalid persisted descriptors fail before file or network access',
    () async {
      await database.customStatement(
        "UPDATE asset_catalog SET checksum_sha256 = 'invalid'",
      );
      expect(
        _failureCode(
          await resolver.resolve(
            'audio-1',
            policy: AssetResolutionPolicy.downloadIfMissing,
          ),
        ),
        'ASSET_CATALOG_INVALID',
      );
      expect(source.calls, 0);
    },
  );
}

String _failureCode(Result<ResolvedAsset> result) {
  return (result as FailureResult<ResolvedAsset>).failure.code;
}

const _offline = ApplicationFailure(
  code: 'ASSET_OFFLINE',
  message: 'The network is unavailable.',
  retryable: true,
);

final class _ByteSource implements AssetByteSource {
  int calls = 0;
  String payload = 'hello';
  ApplicationFailure? failure;
  Future<void>? gate;
  final opened = Completer<void>();

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    calls += 1;
    if (!opened.isCompleted) opened.complete();
    await gate;
    final error = failure;
    if (error != null) return FailureResult(error);
    return Success(
      AssetByteStream(
        bytes: Stream<List<int>>.value(payload.codeUnits),
        contentLength: payload.length,
      ),
    );
  }
}

Future<void> _seed(
  CareerSpeakDatabase database, {
  String assetId = 'audio-1',
  String packCode = 'PACK',
  String variant = 'canonical',
  int revision = 1,
}) async {
  final now = DateTime.utc(2026, 10, 30);
  await database
      .into(database.assetCatalog)
      .insertOnConflictUpdate(
        AssetCatalogCompanion.insert(
          assetId: assetId,
          checksumSha256: _checksum,
          assetKind: 'AUDIO',
          mimeType: 'audio/mpeg',
          sizeBytes: 5,
          deliveryKey: 'audio/hello.mp3',
          createdAt: now,
        ),
      );
  await database
      .into(database.contentPackRevisions)
      .insertOnConflictUpdate(
        ContentPackRevisionsCompanion.insert(
          packCode: packCode,
          variantKey: variant,
          revision: revision,
          schemaVersion: 1,
          checksum: _checksum,
          state: 'CURRENT',
          sourceContentVersion: revision,
          stagedAt: now,
        ),
      );
  await database
      .into(database.localContentRecords)
      .insertOnConflictUpdate(
        LocalContentRecordsCompanion.insert(
          contentCode: _content.code,
          contentType: 'PHRASE',
          revision: revision,
          checksum: _checksum,
          snapshotState: 'CURRENT',
          sourceSchemaVersion: 1,
          createdAt: now,
        ),
      );
  await database
      .into(database.packContentRefs)
      .insertOnConflictUpdate(
        PackContentRefsCompanion.insert(
          packCode: packCode,
          variantKey: variant,
          packRevision: revision,
          contentCode: _content.code,
          contentType: 'PHRASE',
          contentRevision: revision,
        ),
      );
  await database
      .into(database.packAssetRefs)
      .insertOnConflictUpdate(
        PackAssetRefsCompanion.insert(
          packCode: packCode,
          variantKey: variant,
          packRevision: revision,
          assetId: assetId,
          requiredOffline: const Value(true),
        ),
      );
  await database
      .into(database.contentAssetRefs)
      .insertOnConflictUpdate(
        ContentAssetRefsCompanion.insert(
          contentCode: _content.code,
          contentType: 'PHRASE',
          contentRevision: revision,
          assetId: assetId,
          assetRole: 'promptAudio',
          requiredOffline: const Value(true),
        ),
      );
}
