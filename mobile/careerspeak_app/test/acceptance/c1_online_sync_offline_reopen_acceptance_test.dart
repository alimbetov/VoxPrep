import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:careerspeak_app/application/content_delivery/localized_content_payload.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/content_payload_gateway.dart';
import 'package:careerspeak_app/application/ports/localized_content_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_localized_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'online localized sync survives restart and resolves offline by Backend fallback',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-c1-online-offline-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final file = File('${directory.path}/careerspeak.sqlite');
      final backend = _BackendFixture();

      var database = CareerSpeakDatabase(NativeDatabase(file));
      final coordinator = ContentSyncCoordinator(
        journal: DriftSyncJournal(database),
        manifestGateway: backend,
        planner: const ContentSyncPlanner(),
        executor: DriftSyncPlanExecutor(
          database,
          backend,
          backend,
          localizedPayloadGateway: backend,
        ),
      );

      final sync = await coordinator.synchronize(
        runId: 'c1-online-sync',
        trigger: SyncTrigger.startup,
        translationLocale: 'ru-KZ',
      );
      expect(sync, isA<Success<ContentSyncOutcome>>());
      expect(backend.rootCalls, 1);
      expect(backend.packCalls, <String>['canonical', 'locale:ru']);
      expect(backend.canonicalPayloadCalls, 1);
      expect(backend.localizedPayloadCalls, 1);

      await database.close();
      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);
      final offline = DriftLocalizedContentRepository(database);

      final regional = (await offline.resolve(
        identity: _identity,
        contentRevision: 1,
        requestedLocale: 'ru-KZ',
      )).getOrThrow();
      expect(regional, isNotNull);
      expect(regional!.resolvedLocale, 'ru');
      expect(regional.fallbackKind, LocaleFallbackKind.configured);
      expect(regional.title, 'Русский заголовок');
      expect(regional.description, 'Canonical description');
      expect(regional.translation, 'Русский перевод');

      final kazakh = (await offline.resolve(
        identity: _identity,
        contentRevision: 1,
        requestedLocale: 'kk',
      )).getOrThrow();
      expect(kazakh, isNotNull);
      expect(kazakh!.resolvedLocale, 'en');
      expect(kazakh.usesCanonicalEnglishOnly, isTrue);
      expect(kazakh.title, 'Canonical title');

      final root = await database.select(database.contentManifestStates).getSingle();
      expect(root.currentContentVersion, 501);
      expect(root.currentManifestChecksum, _rootChecksum);
    },
  );
}

final class _BackendFixture
    implements
        ContentManifestGateway,
        ContentPayloadGateway,
        LocalizedContentPayloadGateway {
  int rootCalls = 0;
  final List<String> packCalls = <String>[];
  int canonicalPayloadCalls = 0;
  int localizedPayloadCalls = 0;

  late final PackRevisionRef canonicalRef = PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: 8,
    checksum: _canonicalPackChecksum,
  );
  late final PackRevisionRef russianRef = PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'locale:ru'),
    revision: 5,
    checksum: _russianPackChecksum,
  );
  late final PackContentRef contentRef = PackContentRef(
    identity: _identity,
    revision: 1,
    checksum: _contentChecksum,
    sortOrder: 10,
    publishedAt: DateTime.utc(2026, 10, 31, 6),
  );
  late final LocalizedContentRef localizedRef = LocalizedContentRef(
    identity: _identity,
    contentRevision: 1,
    locale: 'ru',
    localizationRevision: 2,
    checksum: _localizedChecksum,
  );

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    rootCalls += 1;
    return Success<RootManifestFetch>(
      RootManifestChanged(
        manifest: RootContentManifest(
          schemaVersion: 1,
          contentVersion: 501,
          minimumAppContractVersion: 1,
          publishedAt: DateTime.utc(2026, 10, 31, 6),
          checksum: _rootChecksum,
          packs: <PackRevisionRef>[canonicalRef, russianRef],
          localeFallbacks: <LocaleFallbackRule>[
            LocaleFallbackRule(
              locale: 'ru-KZ',
              fallbackLocales: const <String>['ru', 'en'],
            ),
            LocaleFallbackRule(
              locale: 'kk',
              fallbackLocales: const <String>['en'],
            ),
          ],
          tombstones: const <ContentTombstone>[],
        ),
        etag: 'root-501',
      ),
    );
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    packCalls.add(target.identity.variant);
    if (target.identity == canonicalRef.identity) {
      return Success<PackContentManifest>(
        PackContentManifest(
          schemaVersion: 1,
          identity: canonicalRef.identity,
          revision: canonicalRef.revision,
          checksum: canonicalRef.checksum,
          contents: <PackContentRef>[contentRef],
          assets: const <ManifestAssetDescriptor>[],
          contentAssets: const <ContentAssetRef>[],
        ),
      );
    }
    return Success<PackContentManifest>(
      PackContentManifest(
        schemaVersion: 1,
        identity: russianRef.identity,
        revision: russianRef.revision,
        checksum: russianRef.checksum,
        contents: <PackContentRef>[contentRef],
        localizations: <LocalizedContentRef>[localizedRef],
        assets: const <ManifestAssetDescriptor>[],
        contentAssets: const <ContentAssetRef>[],
      ),
    );
  }

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async {
    canonicalPayloadCalls += 1;
    return Success<ContentPayload>(
      ContentPayload(
        ref: ContentPayloadRef(
          identity: _identity,
          revision: 1,
          checksum: _contentChecksum,
        ),
        title: 'Canonical title',
        subtitle: 'Canonical subtitle',
        description: 'Canonical description',
        categoryCode: 'JAVA_BACKEND',
        category: 'Java Backend',
        levelCode: 'SENIOR',
        level: 'Senior',
        minutes: 8,
        hasAudio: false,
      ),
    );
  }

  @override
  Future<Result<LocalizedContentPayload>> fetchLocalized(
    LocalizedContentRef target,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<Result<LocalizedContentPayload>> fetch(LocalizedContentRef target) async {
    localizedPayloadCalls += 1;
    return Success<LocalizedContentPayload>(
      LocalizedContentPayload(
        ref: localizedRef,
        title: 'Русский заголовок',
        translation: 'Русский перевод',
      ),
    );
  }
}

const _identity = ContentIdentity(
  code: 'JAVA_DI_001',
  type: ContentType.interview,
);
const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _canonicalPackChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _russianPackChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _contentChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _localizedChecksum =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
