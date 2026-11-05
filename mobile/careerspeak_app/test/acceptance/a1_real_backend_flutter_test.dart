import 'dart:io';

import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';
import 'package:careerspeak_app/application/ports/content_payload_gateway.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/installation_auth_recovery_api_client.dart';
import 'package:careerspeak_app/application/services/installation_bootstrap_service.dart';
import 'package:careerspeak_app/application/services/installation_identity_service.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_publication_snapshot_stager.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/data/local/drift_typed_content_reader.dart';
import 'package:careerspeak_app/data/local/drift_universal_catalogue_repository.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:careerspeak_app/data/remote/http_api_client.dart';
import 'package:careerspeak_app/data/remote/http_assessment_payload_gateway.dart';
import 'package:careerspeak_app/data/remote/http_asset_byte_source.dart';
import 'package:careerspeak_app/data/remote/http_catalogue_payload_gateway.dart';
import 'package:careerspeak_app/data/remote/http_content_manifest_gateway.dart';
import 'package:careerspeak_app/data/remote/http_content_payload_gateway.dart';
import 'package:careerspeak_app/data/remote/http_installation_registration_gateway.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const _runRealBackend = bool.fromEnvironment('A1_REAL_BACKEND');
const _backendUrl = String.fromEnvironment('A1_API_BASE_URL');
const _freeCode = String.fromEnvironment('A1_FREE_CODE');
const _fullCode = String.fromEnvironment('A1_FULL_CODE');
const _testCode = String.fromEnvironment('A1_TEST_CODE');
const _questionCode = String.fromEnvironment('A1_QUESTION_CODE');
const _r5ControlDir = String.fromEnvironment('A1_R5_CONTROL_DIR');

/// This is NOT a mock HTTP test. The JUnit A1 runner starts a real Spring Boot
/// process, publishes committed PostgreSQL data, and points this test at its
/// random local port. Never include this test in normal offline widget runs.
void main() {
  test(
    'live publication, FREE/FULL access, RustFS bytes, Drift and offline reopen',
    () async {
      final baseUri = Uri.parse(_backendUrl);
      final temporary = await Directory.systemTemp.createTemp('voxprep-a1-');
      final dbFile = File('${temporary.path}/a1.sqlite');
      final assetsDirectory = Directory('${temporary.path}/assets');
      final client = http.Client();
      final store = _MemoryCredentialStore();
      CareerSpeakDatabase? database;
      try {
        database = CareerSpeakDatabase(NativeDatabase(dbFile));
        final api = HttpApiClient(
          client: client,
          credentialStore: store,
          baseUri: baseUri,
          maxGetAttempts: 1,
        );
        final identity = InstallationIdentityService(
          store,
          installationIdFactory: () =>
              InstallationId('8aeac9d8-e5e5-4f88-93ca-9d90e7f1bba9'),
        );
        final credentials = (await InstallationBootstrapService(
          identityService: identity,
          registrationGateway: HttpInstallationRegistrationGateway(
            apiClient: api,
            credentialStore: store,
          ),
        ).ensureCredentials()).getOrThrow();
        expect(credentials.installationToken.value, isNotEmpty);

        final manifestGateway = HttpContentManifestGateway(apiClient: api);
        final rootFetch = await manifestGateway.fetchRootManifest();
        if (rootFetch case FailureResult<RootManifestFetch>(:final failure)) {
          fail(
            'A1 root manifest contract failure: code=${failure.code}, '
            'message=${failure.message}, details=${failure.details}',
          );
        }
        final rootResult = rootFetch.getOrThrow();
        expect(rootResult, isA<RootManifestChanged>());
        final root = (rootResult as RootManifestChanged).manifest;
        expect(root.schemaVersion, 2);
        expect(root.packs, hasLength(2));
        expect(root.catalogues, hasLength(6));
        expect(root.practiceTests.single.practiceTestCode, _testCode);

        final assessmentLoader = AssessmentRevisionLoader(
          gateway: HttpAssessmentPayloadGateway(apiClient: api),
          repository: DriftAssessmentRevisionRepository(database),
        );
        final coordinator = ContentSyncCoordinator(
          journal: DriftSyncJournal(database),
          manifestGateway: manifestGateway,
          planner: const ContentSyncPlanner(),
          executor: DriftSyncPlanExecutor(
            database,
            manifestGateway,
            HttpContentPayloadGateway(apiClient: api),
          ),
          snapshotStager: DriftPublicationSnapshotStager(
            database,
            assessmentLoader,
            HttpCataloguePayloadGateway(apiClient: api),
            manifestGateway: manifestGateway,
          ),
        );
        final synchronized = await coordinator.synchronize(
          runId: 'a1-real-published-mixed-access',
          trigger: SyncTrigger.manual,
          translationLocale: 'en',
        );
        if (synchronized case FailureResult<ContentSyncOutcome>(
          :final failure,
        )) {
          fail(
            'A1 live FREE/FULL sync: code=${failure.code}, '
            'message=${failure.message}, details=${failure.details}',
          );
        }
        expect(synchronized, isA<Success<ContentSyncOutcome>>());

        final current = (await DriftUniversalCatalogueRepository(
          database,
        ).readCurrent()).getOrThrow();
        expect(current, isNotNull);
        expect(current!.contentVersion, root.contentVersion);
        expect(current.graph.collections, hasLength(2));
        final contentPage = (await DriftContentRepository(
          database,
        ).watchContent(const ContentQuery()).first).getOrThrow();
        expect(contentPage.items.any((item) => item.code == _freeCode), isTrue);
        expect(
          contentPage.items.any((item) => item.code == _fullCode),
          isFalse,
        );

        final premium = await api.send(
          ApiRequest(
            method: ApiMethod.get,
            path: '/api/v1/content/phrase/$_fullCode/revisions/1',
          ),
        );
        expect(premium, isA<FailureResult<ApiResponse>>());
        final premiumFailure = (premium as FailureResult<ApiResponse>).failure;
        expect(premiumFailure.code, 'FORBIDDEN');
        expect(
          premiumFailure.details['backendCode'],
          'PREMIUM_UNLOCK_REQUIRED',
        );

        final testResponse = await api.send(
          ApiRequest(
            method: ApiMethod.get,
            path: '/api/v1/assessment/practice-tests/$_testCode/revisions/1',
          ),
        );
        expect(testResponse, isA<Success<ApiResponse>>());
        final questionResponse = await api.send(
          ApiRequest(
            method: ApiMethod.get,
            path: '/api/v1/assessment/questions/$_questionCode/revisions/1',
          ),
        );
        expect(questionResponse, isA<Success<ApiResponse>>());

        final freePack = root.packs.singleWhere(
          (pack) => pack.identity.code == 'A1_FREE',
        );
        final pack = (await manifestGateway.fetchPackManifest(
          freePack,
        )).getOrThrow();
        final image = pack.assets.singleWhere(
          (asset) => asset.mediaType == 'image/png',
        );
        final mediaProbe = await client.get(
          baseUri.resolve('/api/v1/media/assets/${image.assetId}/content'),
          headers: <String, String>{
            'authorization': 'Bearer ${credentials.installationToken.value}',
          },
        );
        if (mediaProbe.statusCode != 200) {
          fail(
            'A1 live media HTTP status=${mediaProbe.statusCode}, '
            'body=${mediaProbe.body}',
          );
        }
        final manager = AssetDownloadManager(
          source: HttpAssetByteSource(
            client: client,
            credentialStore: store,
            baseUri: baseUri,
          ),
          store: FileSystemAssetStore(assetsDirectory),
        );
        final downloaded = (await manager.ensureLocal(image)).getOrThrow();
        expect(await File(downloaded.localPath).exists(), isTrue);
        expect(
          await File(downloaded.localPath).readAsBytes(),
          mediaProbe.bodyBytes,
        );
        expect(downloaded.reused, isFalse);

        // Read the exact published typed body through the production Drift
        // reader. This must be available without any mock fixture.
        final freeAtN = contentPage.items.singleWhere(
          (item) => item.code == _freeCode,
        );
        expect(freeAtN.revision, 1);
        final phraseAtN = await DriftTypedContentReader(
          database,
        ).getForVisible(freeAtN);
        expect(phraseAtN, isA<PhraseBody>());
        expect(
          (phraseAtN! as PhraseBody).phrase,
          'Could you introduce yourself?',
        );

        var expectedCurrentVersion = root.contentVersion;
        if (_r5ControlDir.isNotEmpty) {
          // An explicit learner marker keyed by stable content identity must survive
          // changing the immutable revision and updating CURRENT.
          await database
              .into(database.favorites)
              .insert(
                FavoritesCompanion.insert(
                  contentCode: _freeCode,
                  contentType: 'PHRASE',
                  createdAt: DateTime.now().toUtc(),
                ),
              );
          await File('$_r5ControlDir/n1-ready').writeAsString('N1 synced');
          final deadline = DateTime.now().add(const Duration(seconds: 150));
          while (!await File('$_r5ControlDir/n2-ready').exists()) {
            final error = File('$_r5ControlDir/n2-error');
            if (await error.exists()) {
              fail(
                'R5 server publication N2 failed: ${await error.readAsString()}',
              );
            }
            if (DateTime.now().isAfter(deadline)) {
              fail('R5 N2 publisher timeout while Flutter retained N1');
            }
            await Future<void>.delayed(const Duration(milliseconds: 100));
          }
          final nextFetch = (await manifestGateway.fetchRootManifest())
              .getOrThrow();
          expect(nextFetch, isA<RootManifestChanged>());
          final nextRoot = (nextFetch as RootManifestChanged).manifest;
          expect(nextRoot.contentVersion, root.contentVersion + 1);
          expect(nextRoot.checksum, isNot(root.checksum));
          // Inject one real payload fetch failure after N+1 becomes available.
          // The atomic CURRENT switch must not happen until all bytes are ready.
          final interrupted = ContentSyncCoordinator(
            journal: DriftSyncJournal(database),
            manifestGateway: manifestGateway,
            planner: const ContentSyncPlanner(),
            executor: DriftSyncPlanExecutor(
              database,
              manifestGateway,
              _FailOnceContentPayloadGateway(
                HttpContentPayloadGateway(apiClient: api),
              ),
            ),
            snapshotStager: DriftPublicationSnapshotStager(
              database,
              assessmentLoader,
              HttpCataloguePayloadGateway(apiClient: api),
              manifestGateway: manifestGateway,
            ),
          );
          final failure = await interrupted.synchronize(
            runId: 'r5-n2-injected-fetch-failure',
            trigger: SyncTrigger.manual,
            translationLocale: 'en',
          );
          expect(failure, isA<FailureResult<ContentSyncOutcome>>());
          final stillN = (await DriftUniversalCatalogueRepository(
            database,
          ).readCurrent()).getOrThrow();
          expect(stillN!.contentVersion, root.contentVersion);
          final oldPage = (await DriftContentRepository(
            database,
          ).watchContent(const ContentQuery()).first).getOrThrow();
          final unchangedAtN = oldPage.items.singleWhere(
            (item) => item.code == _freeCode,
          );
          expect(unchangedAtN.revision, 1);
          final preservedBody = await DriftTypedContentReader(
            database,
          ).getForVisible(unchangedAtN);
          expect(preservedBody, isA<PhraseBody>());
          expect(
            (preservedBody! as PhraseBody).phrase,
            'Could you introduce yourself?',
          );
          expect(
            (await database.select(database.favorites).get()).any(
              (row) => row.contentCode == _freeCode,
            ),
            isTrue,
          );

          // A syntactically valid but incorrect payload checksum must also
          // fail closed. This injects a tampered response *after* the real
          // backend request and decoder, without weakening HTTP validation.
          final corrupted = ContentSyncCoordinator(
            journal: DriftSyncJournal(database),
            manifestGateway: manifestGateway,
            planner: const ContentSyncPlanner(),
            executor: DriftSyncPlanExecutor(
              database,
              manifestGateway,
              _CorruptOnceContentPayloadGateway(
                HttpContentPayloadGateway(apiClient: api),
              ),
            ),
            snapshotStager: DriftPublicationSnapshotStager(
              database,
              assessmentLoader,
              HttpCataloguePayloadGateway(apiClient: api),
              manifestGateway: manifestGateway,
            ),
          );
          final corruptedResult = await corrupted.synchronize(
            runId: 'r1-n2-injected-checksum-mismatch',
            trigger: SyncTrigger.manual,
            translationLocale: 'en',
          );
          expect(corruptedResult, isA<FailureResult<ContentSyncOutcome>>());
          expect(
            (corruptedResult as FailureResult<ContentSyncOutcome>).failure.code,
            'CONTENT_PAYLOAD_MISMATCH',
          );
          final stillNAfterCorruption =
              (await DriftUniversalCatalogueRepository(
                database,
              ).readCurrent()).getOrThrow();
          expect(stillNAfterCorruption!.contentVersion, root.contentVersion);
          final stillNPage = (await DriftContentRepository(
            database,
          ).watchContent(const ContentQuery()).first).getOrThrow();
          final stillNContent = stillNPage.items.singleWhere(
            (item) => item.code == _freeCode,
          );
          expect(stillNContent.revision, 1);
          final stillNBody = await DriftTypedContentReader(
            database,
          ).getForVisible(stillNContent);
          expect(stillNBody, isA<PhraseBody>());
          expect(
            (stillNBody! as PhraseBody).phrase,
            'Could you introduce yourself?',
          );

          // Retry with the production gateway and a fresh run ID.
          final nextSync = await coordinator.synchronize(
            runId: 'r5-real-publication-n-plus-one',
            trigger: SyncTrigger.manual,
            translationLocale: 'en',
          );
          if (nextSync case FailureResult<ContentSyncOutcome>(:final failure)) {
            fail('R5 N2 sync failed: ${failure.code} ${failure.details}');
          }
          expect(nextSync, isA<Success<ContentSyncOutcome>>());
          final newCurrent = (await DriftUniversalCatalogueRepository(
            database,
          ).readCurrent()).getOrThrow();
          expect(newCurrent!.contentVersion, nextRoot.contentVersion);
          expectedCurrentVersion = nextRoot.contentVersion;
          final updatedPage = (await DriftContentRepository(
            database,
          ).watchContent(const ContentQuery()).first).getOrThrow();
          final updated = updatedPage.items.singleWhere(
            (item) => item.code == _freeCode,
          );
          expect(updated.revision, 2);
          expect(updated.title, 'Interview introduction v2');
          final typedAtNPlusOne = await DriftTypedContentReader(
            database,
          ).getForVisible(updated);
          expect(typedAtNPlusOne, isA<PhraseBody>());
          expect(
            (typedAtNPlusOne! as PhraseBody).phrase,
            'Could you introduce yourself professionally?',
          );
          final favoritesAfterSync = await database
              .select(database.favorites)
              .get();
          expect(
            favoritesAfterSync.any(
              (row) =>
                  row.contentCode == _freeCode && row.contentType == 'PHRASE',
            ),
            isTrue,
          );
          final nextFreePack = nextRoot.packs.singleWhere(
            (pack) => pack.identity.code == 'A1_FREE',
          );
          final nextPack = (await manifestGateway.fetchPackManifest(
            nextFreePack,
          )).getOrThrow();
          expect(
            nextPack.assets.any((asset) => asset.assetId == image.assetId),
            isTrue,
          );
        }

        // A rejected installation credential cannot rotate itself and cannot
        // be replaced by registering the same UUID anonymously. The offline
        // data remains intact; no fresh token is created by the 401 handler.
        const rejectedToken = 'invalid-a1-credential';
        await store.writeInstallationToken(InstallationToken(rejectedToken));
        final protectedApi = InstallationAuthRecoveryApiClient(
          delegate: api,
          credentialStore: store,
        );
        final rejected = await protectedApi.send(
          ApiRequest(
            method: ApiMethod.get,
            path: '/api/v1/content/phrase/$_freeCode/revisions/1',
          ),
        );
        expect(rejected, isA<FailureResult<ApiResponse>>());
        expect(
          (rejected as FailureResult<ApiResponse>).failure.code,
          'UNAUTHORIZED',
        );
        final illegalRotation = await HttpInstallationRegistrationGateway(
          apiClient: api,
          credentialStore: store,
        ).register(credentials.installationId);
        expect(illegalRotation, isA<FailureResult<InstallationToken>>());
        expect(
          await store.readInstallationToken(),
          InstallationToken(rejectedToken),
        );
        await store.writeInstallationToken(credentials.installationToken);

        // No HTTP client or Spring Boot is consulted for local state after
        // the database is closed and reopened from a real SQLite file.
        await database.close();
        database = null;
        client.close();
        database = CareerSpeakDatabase(NativeDatabase(dbFile));
        final reopened = (await DriftUniversalCatalogueRepository(
          database,
        ).readCurrent()).getOrThrow();
        expect(reopened!.contentVersion, expectedCurrentVersion);
        expect(reopened.graph.collections, hasLength(2));
        final offlinePage = (await DriftContentRepository(
          database,
        ).watchContent(const ContentQuery()).first).getOrThrow();
        expect(offlinePage.items.any((item) => item.code == _freeCode), isTrue);
        final offlineFree = offlinePage.items.singleWhere(
          (item) => item.code == _freeCode,
        );
        final offlineBody = await DriftTypedContentReader(
          database,
        ).getForVisible(offlineFree);
        expect(offlineBody, isA<PhraseBody>());
        expect(
          (offlineBody! as PhraseBody).phrase,
          _r5ControlDir.isNotEmpty
              ? 'Could you introduce yourself professionally?'
              : 'Could you introduce yourself?',
        );
        expect(offlineFree.revision, _r5ControlDir.isNotEmpty ? 2 : 1);
        final reused = (await manager.ensureLocal(image)).getOrThrow();
        expect(reused.reused, isTrue);
        if (_r5ControlDir.isNotEmpty) {
          final retained = await database.select(database.favorites).get();
          expect(retained.any((row) => row.contentCode == _freeCode), isTrue);
          final content = (await DriftContentRepository(
            database,
          ).watchContent(const ContentQuery()).first).getOrThrow();
          expect(
            content.items
                .singleWhere((item) => item.code == _freeCode)
                .revision,
            2,
          );
        }
        expect(
          await File(reused.localPath).readAsBytes(),
          mediaProbe.bodyBytes,
        );

        // The marker is emitted only after a genuine live-backend exchange.
        // ignore: avoid_print
        print('A1_REAL_BACKEND_ACCEPTED');
      } finally {
        if (database != null) await database.close();
        client.close();
        await temporary.delete(recursive: true);
      }
    },
    skip: !_runRealBackend,
  );
}

final class _CorruptOnceContentPayloadGateway implements ContentPayloadGateway {
  _CorruptOnceContentPayloadGateway(this._delegate);

  final ContentPayloadGateway _delegate;
  bool _corrupted = false;

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async {
    final fetched = await _delegate.fetch(target);
    if (_corrupted || fetched is! Success<ContentPayload>) {
      return fetched;
    }
    _corrupted = true;
    final valid = fetched.value;
    // Return a well-formed digest that cannot match the exact requested ref.
    final mismatchedDigest =
        target.checksum ==
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        ? 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
        : 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    return Success<ContentPayload>(
      ContentPayload(
        ref: ContentPayloadRef(
          identity: valid.ref.identity,
          revision: valid.ref.revision,
          checksum: mismatchedDigest,
        ),
        title: valid.title,
        subtitle: valid.subtitle,
        description: valid.description,
        categoryCode: valid.categoryCode,
        category: valid.category,
        levelCode: valid.levelCode,
        level: valid.level,
        minutes: valid.minutes,
        hasAudio: valid.hasAudio,
        skillCodes: valid.skillCodes,
        body: valid.body,
      ),
    );
  }
}

final class _FailOnceContentPayloadGateway implements ContentPayloadGateway {
  _FailOnceContentPayloadGateway(this._delegate);
  final ContentPayloadGateway _delegate;
  bool _failed = false;
  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) {
    if (!_failed) {
      _failed = true;
      return Future<Result<ContentPayload>>.value(
        const FailureResult<ContentPayload>(
          ApplicationFailure(
            code: 'R5_INJECTED_N2_CONTENT_FETCH_FAILURE',
            message: 'A required N+1 payload is unavailable.',
            retryable: true,
          ),
        ),
      );
    }
    return _delegate.fetch(target);
  }
}

final class _MemoryCredentialStore implements InstallationCredentialStore {
  InstallationId? _installationId;
  InstallationToken? _installationToken;

  @override
  Future<InstallationId?> readInstallationId() async => _installationId;

  @override
  Future<InstallationToken?> readInstallationToken() async =>
      _installationToken;

  @override
  Future<void> writeInstallationId(InstallationId value) async {
    _installationId = value;
  }

  @override
  Future<void> writeInstallationToken(InstallationToken value) async {
    _installationToken = value;
  }

  @override
  Future<void> clearInstallationToken() async {
    _installationToken = null;
  }

  @override
  Future<void> clear() async {
    _installationId = null;
    _installationToken = null;
  }
}
