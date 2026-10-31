import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_delivery/localized_content_payload.dart';
import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/content_payload_gateway.dart';
import 'package:careerspeak_app/application/ports/localized_content_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart'
    hide PackContentRef, ContentAssetRef, LocaleFallbackRule;
import 'package:careerspeak_app/data/local/drift_app_preferences_repository.dart';
import 'package:careerspeak_app/data/local/drift_localized_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'canonical plus ru survive restart and kk falls back offline without root drift',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-c1-locale-restart-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final file = File('${directory.path}/careerspeak.sqlite');

      var database = CareerSpeakDatabase(NativeDatabase(file));
      final published = await _publishCanonicalAndRussian(database);
      expect(published, isA<Success<void>>());

      final preferences = DriftAppPreferencesRepository(database);
      expect(
        await preferences.setTranslationLocale(AppTranslationLocale.russian),
        isA<Success<void>>(),
      );

      final beforeRestart = (await DriftSyncJournal(
        database,
      ).readLocalSnapshot()).getOrThrow();
      expect(beforeRestart.currentContentVersion, 1);
      expect(beforeRestart.currentManifestChecksum, _rootChecksum);
      expect(beforeRestart.currentPacks, hasLength(2));

      await database.close();
      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);

      final reopenedPreferences = DriftAppPreferencesRepository(database);
      final restored = (await reopenedPreferences.getPreferences())
          .getOrThrow();
      expect(restored.translationLocale.code, 'ru');

      final resolver = DriftLocalizedContentRepository(database);
      final russian = (await resolver.resolve(
        identity: _identity,
        contentRevision: 1,
        requestedLocale: restored.translationLocale.code,
      )).getOrThrow();
      expect(russian, isNotNull);
      expect(russian!.resolvedLocale, 'ru');
      expect(russian.fallbackKind, LocaleFallbackKind.exact);
      expect(russian.title, 'Внедрение зависимостей');
      expect(russian.translation, 'Объясните constructor injection.');
      expect(russian.description, 'Canonical description');

      expect(
        await reopenedPreferences.setTranslationLocale(
          AppTranslationLocale.kazakh,
        ),
        isA<Success<void>>(),
      );
      final switched = (await reopenedPreferences.getPreferences())
          .getOrThrow();
      expect(switched.translationLocale.code, 'kk');

      final kazakhOffline = (await resolver.resolve(
        identity: _identity,
        contentRevision: 1,
        requestedLocale: switched.translationLocale.code,
      )).getOrThrow();
      expect(kazakhOffline, isNotNull);
      expect(kazakhOffline!.resolvedLocale, 'en');
      expect(kazakhOffline.fallbackKind, LocaleFallbackKind.canonicalEnglish);
      expect(kazakhOffline.usesCanonicalEnglishOnly, isTrue);
      expect(kazakhOffline.title, 'Dependency Injection');
      expect(kazakhOffline.description, 'Canonical description');
      expect(kazakhOffline.translation, isNull);

      final afterLocaleSwitch = (await DriftSyncJournal(
        database,
      ).readLocalSnapshot()).getOrThrow();
      expect(
        afterLocaleSwitch.currentContentVersion,
        beforeRestart.currentContentVersion,
      );
      expect(
        afterLocaleSwitch.currentManifestChecksum,
        beforeRestart.currentManifestChecksum,
      );
      expect(
        afterLocaleSwitch.currentPacks
            .map((pack) => pack.identity.toString())
            .toSet(),
        beforeRestart.currentPacks
            .map((pack) => pack.identity.toString())
            .toSet(),
      );
    },
  );
}

Future<Result<void>> _publishCanonicalAndRussian(
  CareerSpeakDatabase database,
) async {
  final canonicalRef = PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: 1,
    checksum: _canonicalPackChecksum,
  );
  final russianRef = PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR_RU', variant: 'locale:ru'),
    revision: 1,
    checksum: _russianPackChecksum,
  );
  final root = RootContentManifest(
    schemaVersion: 1,
    contentVersion: 1,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 31, 5),
    checksum: _rootChecksum,
    packs: <PackRevisionRef>[canonicalRef, russianRef],
    tombstones: const <ContentTombstone>[],
  );

  final journal = DriftSyncJournal(database);
  final local = (await journal.readLocalSnapshot()).getOrThrow();
  final plan = const ContentSyncPlanner()
      .plan(local: local, remote: root)
      .getOrThrow();
  final start = await journal.startOrCoalesce(
    runId: 'c1-locale-offline-initial',
    trigger: SyncTrigger.startup,
    translationLocale: 'ru',
  );
  if (start case FailureResult(:final failure)) {
    return FailureResult<void>(failure);
  }
  final persisted = await journal.persistPlan(
    runId: 'c1-locale-offline-initial',
    plan: plan,
  );
  if (persisted case FailureResult<void>(:final failure)) {
    return FailureResult<void>(failure);
  }

  final executor = DriftSyncPlanExecutor(
    database,
    _ManifestGateway(<String, PackContentManifest>{
      canonicalRef.identity.toString(): _canonicalPack(canonicalRef),
      russianRef.identity.toString(): _russianPack(russianRef),
    }),
    const _PayloadGateway(),
    localizedPayloadGateway: const _LocalizedPayloadGateway(),
  );
  final result = await executor.execute(
    runId: 'c1-locale-offline-initial',
    plan: plan,
  );
  if (result is Success<void>) {
    final terminal = await journal.transitionRun(
      runId: 'c1-locale-offline-initial',
      state: SyncRunState.succeeded,
    );
    if (terminal case FailureResult<void>(:final failure)) {
      return FailureResult<void>(failure);
    }
  }
  return result;
}

PackContentManifest _canonicalPack(PackRevisionRef target) {
  return PackContentManifest(
    schemaVersion: 1,
    identity: target.identity,
    revision: target.revision,
    checksum: target.checksum,
    contents: <PackContentRef>[
      PackContentRef(
        identity: _identity,
        revision: 1,
        checksum: _contentChecksum,
        sortOrder: 10,
        publishedAt: DateTime.utc(2026, 10, 31, 5),
      ),
    ],
    assets: const <ManifestAssetDescriptor>[],
    contentAssets: const <ContentAssetRef>[],
  );
}

PackContentManifest _russianPack(PackRevisionRef target) {
  final content = PackContentRef(
    identity: _identity,
    revision: 1,
    checksum: _contentChecksum,
    sortOrder: 10,
    publishedAt: DateTime.utc(2026, 10, 31, 5),
  );
  return PackContentManifest(
    schemaVersion: 1,
    identity: target.identity,
    revision: target.revision,
    checksum: target.checksum,
    contents: <PackContentRef>[content],
    localizations: <LocalizedContentRef>[_localizedRef],
    assets: const <ManifestAssetDescriptor>[],
    contentAssets: const <ContentAssetRef>[],
  );
}

final class _ManifestGateway implements ContentManifestGateway {
  const _ManifestGateway(this.packs);

  final Map<String, PackContentManifest> packs;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    return const FailureResult<RootManifestFetch>(
      ApplicationFailure(code: 'NOT_USED', message: 'Root fetch is not used.'),
    );
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    final pack = packs[target.identity.toString()];
    if (pack == null) {
      return const FailureResult<PackContentManifest>(
        ApplicationFailure(
          code: 'PACK_NOT_FOUND',
          message: 'Synthetic pack is missing.',
        ),
      );
    }
    return Success<PackContentManifest>(pack);
  }
}

final class _PayloadGateway implements ContentPayloadGateway {
  const _PayloadGateway();

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async {
    return Success<ContentPayload>(
      ContentPayload(
        ref: target,
        title: 'Dependency Injection',
        subtitle: 'Java Backend · Senior interview',
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
}

final class _LocalizedPayloadGateway implements LocalizedContentPayloadGateway {
  const _LocalizedPayloadGateway();

  @override
  Future<Result<LocalizedContentPayload>> fetch(
    LocalizedContentRef target,
  ) async {
    return Success<LocalizedContentPayload>(
      LocalizedContentPayload(
        ref: target,
        title: 'Внедрение зависимостей',
        translation: 'Объясните constructor injection.',
      ),
    );
  }
}

const _identity = ContentIdentity(
  code: 'JAVA_DI_001',
  type: ContentType.interview,
);
final _localizedRef = LocalizedContentRef(
  identity: _identity,
  contentRevision: 1,
  locale: 'ru',
  localizationRevision: 1,
  checksum: _localizedChecksum,
);

const _rootChecksum =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _canonicalPackChecksum =
    '2222222222222222222222222222222222222222222222222222222222222222';
const _russianPackChecksum =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _contentChecksum =
    '4444444444444444444444444444444444444444444444444444444444444444';
const _localizedChecksum =
    '5555555555555555555555555555555555555555555555555555555555555555';
