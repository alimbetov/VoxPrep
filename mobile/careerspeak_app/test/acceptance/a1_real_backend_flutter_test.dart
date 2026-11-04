import 'dart:io';

import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
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
        expect(reopened!.contentVersion, root.contentVersion);
        expect(reopened.graph.collections, hasLength(2));
        final offlinePage = (await DriftContentRepository(
          database,
        ).watchContent(const ContentQuery()).first).getOrThrow();
        expect(offlinePage.items.any((item) => item.code == _freeCode), isTrue);
        final reused = (await manager.ensureLocal(image)).getOrThrow();
        expect(reused.reused, isTrue);
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
