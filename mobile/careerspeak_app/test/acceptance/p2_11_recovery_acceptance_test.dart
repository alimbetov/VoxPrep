import 'dart:convert';

import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/preference_aware_content_sync.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/application_bootstrap_service.dart';
import 'package:careerspeak_app/application/services/installation_bootstrap_service.dart';
import 'package:careerspeak_app/application/services/installation_identity_service.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_app_preferences_repository.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/data/remote/http_api_client.dart';
import 'package:careerspeak_app/data/remote/http_content_manifest_gateway.dart';
import 'package:careerspeak_app/data/remote/http_content_payload_gateway.dart';
import 'package:careerspeak_app/data/remote/http_installation_registration_gateway.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('offline startup preserves last-known-good CURRENT content', () async {
    final database = CareerSpeakDatabase(NativeDatabase.memory());
    final credentialStore = _MemoryCredentialStore();
    final backend = _RecoveryLearnerApiFixture();
    final onlineClient = MockClient(backend.handle);
    addTearDown(database.close);
    addTearDown(onlineClient.close);

    await _bootstrapSuccess(
      database: database,
      credentialStore: credentialStore,
      client: onlineClient,
      runId: 'recovery-online',
    );
    await _expectCurrentRevision(database, revision: 1, title: _titleV1);

    final offlineClient = MockClient((request) async {
      throw http.ClientException('offline', request.url);
    });
    addTearDown(offlineClient.close);

    final result = await _bootstrapResult(
      database: database,
      credentialStore: credentialStore,
      client: offlineClient,
      runId: 'recovery-offline',
    );

    expect(result, isA<FailureResult<ApplicationBootstrapOutcome>>());
    expect(
      (result as FailureResult<ApplicationBootstrapOutcome>).failure.code,
      'OFFLINE',
    );
    expect((await credentialStore.readInstallationId())?.value, _installationId);
    expect((await credentialStore.readInstallationToken())?.value, _token);
    await _expectCurrentRevision(database, revision: 1, title: _titleV1);
  });

  test('failed newer publication never replaces last-known-good CURRENT', () async {
    final database = CareerSpeakDatabase(NativeDatabase.memory());
    final credentialStore = _MemoryCredentialStore();
    final backend = _RecoveryLearnerApiFixture();
    final client = MockClient(backend.handle);
    addTearDown(database.close);
    addTearDown(client.close);

    await _bootstrapSuccess(
      database: database,
      credentialStore: credentialStore,
      client: client,
      runId: 'recovery-v1',
    );
    await _expectCurrentRevision(database, revision: 1, title: _titleV1);

    backend
      ..revision = 2
      ..failPayload = true;

    final result = await _bootstrapResult(
      database: database,
      credentialStore: credentialStore,
      client: client,
      runId: 'recovery-v2-fails',
    );

    expect(result, isA<FailureResult<ApplicationBootstrapOutcome>>());
    expect(
      (result as FailureResult<ApplicationBootstrapOutcome>).failure.code,
      'SERVER_ERROR',
    );
    await _expectCurrentRevision(database, revision: 1, title: _titleV1);
  });

  test('same immutable root repairs a missing canonical learner payload', () async {
    final database = CareerSpeakDatabase(NativeDatabase.memory());
    final credentialStore = _MemoryCredentialStore();
    final backend = _RecoveryLearnerApiFixture();
    final client = MockClient(backend.handle);
    addTearDown(database.close);
    addTearDown(client.close);

    await _bootstrapSuccess(
      database: database,
      credentialStore: credentialStore,
      client: client,
      runId: 'repair-initial',
    );
    await _expectCurrentRevision(database, revision: 1, title: _titleV1);

    await (database.delete(database.contentCatalogReads)..where(
          (row) =>
              row.contentCode.equals(_contentCode) &
              row.contentType.equals('INTERVIEW') &
              row.revision.equals(1),
        ))
        .go();

    final broken = await DriftContentRepository(
      database,
    ).watchContent(const ContentQuery()).first;
    expect(broken, isA<FailureResult>());
    expect((broken as FailureResult).failure.code, 'CONTENT_READ_MODEL_INVALID');

    final packCallsBeforeRepair = backend.packManifestCalls;
    final payloadCallsBeforeRepair = backend.contentPayloadCalls;
    await _bootstrapSuccess(
      database: database,
      credentialStore: credentialStore,
      client: client,
      runId: 'repair-same-root',
    );

    expect(backend.registrationCalls, 1);
    expect(backend.packManifestCalls, packCallsBeforeRepair + 1);
    expect(backend.contentPayloadCalls, payloadCallsBeforeRepair + 1);
    await _expectCurrentRevision(database, revision: 1, title: _titleV1);
  });

  test('corrupt root journal fails closed without deleting CURRENT content', () async {
    final database = CareerSpeakDatabase(NativeDatabase.memory());
    final credentialStore = _MemoryCredentialStore();
    final backend = _RecoveryLearnerApiFixture();
    final client = MockClient(backend.handle);
    addTearDown(database.close);
    addTearDown(client.close);

    await _bootstrapSuccess(
      database: database,
      credentialStore: credentialStore,
      client: client,
      runId: 'corrupt-root-initial',
    );
    await _expectCurrentRevision(database, revision: 1, title: _titleV1);

    await database.delete(database.contentManifestStates).go();

    final snapshot = await DriftSyncJournal(database).readLocalSnapshot();
    expect(snapshot, isA<FailureResult>());
    expect((snapshot as FailureResult).failure.code, 'LOCAL_SYNC_STATE_CORRUPT');
    await _expectCurrentRevision(database, revision: 1, title: _titleV1);
  });
}

Future<ApplicationBootstrapOutcome> _bootstrapSuccess({
  required CareerSpeakDatabase database,
  required InstallationCredentialStore credentialStore,
  required http.Client client,
  required String runId,
}) async {
  return (await _bootstrapResult(
    database: database,
    credentialStore: credentialStore,
    client: client,
    runId: runId,
  )).getOrThrow();
}

Future<Result<ApplicationBootstrapOutcome>> _bootstrapResult({
  required CareerSpeakDatabase database,
  required InstallationCredentialStore credentialStore,
  required http.Client client,
  required String runId,
}) {
  final apiClient = HttpApiClient(
    client: client,
    credentialStore: credentialStore,
    baseUri: Uri.parse('https://api.careerspeak.test'),
    maxGetAttempts: 1,
  );
  final manifestGateway = HttpContentManifestGateway(apiClient: apiClient);
  final payloadGateway = HttpContentPayloadGateway(apiClient: apiClient);
  final coordinator = ContentSyncCoordinator(
    journal: DriftSyncJournal(database),
    manifestGateway: manifestGateway,
    planner: const ContentSyncPlanner(),
    executor: DriftSyncPlanExecutor(database, manifestGateway, payloadGateway),
  );
  final contentSync = PreferenceAwareContentSync(
    preferencesRepository: DriftAppPreferencesRepository(database),
    coordinator: coordinator,
  );
  final bootstrap = ApplicationBootstrapService(
    installationBootstrapService: InstallationBootstrapService(
      identityService: InstallationIdentityService(
        credentialStore,
        installationIdFactory: () => InstallationId(_installationId),
      ),
      registrationGateway: HttpInstallationRegistrationGateway(
        apiClient: apiClient,
      ),
    ),
    synchronizeContent: contentSync.synchronize,
    runIdFactory: () => runId,
  );
  return bootstrap.bootstrap();
}

Future<void> _expectCurrentRevision(
  CareerSpeakDatabase database, {
  required int revision,
  required String title,
}) async {
  final page = (await DriftContentRepository(
    database,
  ).watchContent(const ContentQuery()).first).getOrThrow();
  expect(page.items, hasLength(1));
  expect(page.items.single.code, _contentCode);
  expect(page.items.single.revision, revision);
  expect(page.items.single.title, title);
}

final class _MemoryCredentialStore implements InstallationCredentialStore {
  InstallationId? _installationId;
  InstallationToken? _installationToken;

  @override
  Future<void> clear() async {
    _installationId = null;
    _installationToken = null;
  }

  @override
  Future<void> clearInstallationToken() async {
    _installationToken = null;
  }

  @override
  Future<InstallationId?> readInstallationId() async => _installationId;

  @override
  Future<InstallationToken?> readInstallationToken() async =>
      _installationToken;

  @override
  Future<void> writeInstallationId(InstallationId installationId) async {
    _installationId = installationId;
  }

  @override
  Future<void> writeInstallationToken(
    InstallationToken installationToken,
  ) async {
    _installationToken = installationToken;
  }
}

final class _RecoveryLearnerApiFixture {
  int revision = 1;
  bool failPayload = false;

  int registrationCalls = 0;
  int rootManifestCalls = 0;
  int packManifestCalls = 0;
  int contentPayloadCalls = 0;

  Future<http.Response> handle(http.Request request) async {
    if (request.method == 'POST' &&
        request.url.path == '/api/v1/installations') {
      registrationCalls += 1;
      return _jsonResponse(<String, Object?>{'installationToken': _token});
    }

    _requireBearer(request);

    if (request.method == 'GET' &&
        request.url.path == '/api/v1/content/manifest') {
      rootManifestCalls += 1;
      return _jsonResponse(_rootManifest(revision));
    }

    if (request.method == 'GET' &&
        request.url.path == '/api/v1/content/packs/JAVA_SENIOR/manifest') {
      packManifestCalls += 1;
      final requestedRevision = int.parse(
        request.url.queryParameters['revision']!,
      );
      return _jsonResponse(_packManifest(requestedRevision));
    }

    if (request.method == 'GET' &&
        request.url.path ==
            '/api/v1/content/interview/$_contentCode/revisions/$revision') {
      contentPayloadCalls += 1;
      if (failPayload) {
        return _jsonResponse(
          <String, Object?>{
            'code': 'SERVER_ERROR',
            'message': 'Synthetic recovery failure.',
          },
          statusCode: 503,
        );
      }
      return _jsonResponse(_contentPayload(revision));
    }

    return _jsonResponse(
      <String, Object?>{'code': 'NOT_FOUND', 'message': 'Unexpected request.'},
      statusCode: 404,
    );
  }

  void _requireBearer(http.Request request) {
    if (request.headers['authorization'] != 'Bearer $_token') {
      throw StateError('Authenticated request is missing installation token.');
    }
  }
}

Map<String, Object?> _rootManifest(int revision) => <String, Object?>{
  'schemaVersion': 1,
  'contentVersion': revision,
  'minimumAppContractVersion': 1,
  'publishedAt': '2026-10-31T00:00:00Z',
  'checksum': revision == 1 ? _rootChecksumV1 : _rootChecksumV2,
  'packs': <Object?>[
    <String, Object?>{
      'code': 'JAVA_SENIOR',
      'variant': 'canonical',
      'revision': revision,
      'checksum': revision == 1 ? _packChecksumV1 : _packChecksumV2,
    },
  ],
  'tombstones': <Object?>[],
};

Map<String, Object?> _packManifest(int revision) => <String, Object?>{
  'schemaVersion': 1,
  'code': 'JAVA_SENIOR',
  'variant': 'canonical',
  'revision': revision,
  'checksum': revision == 1 ? _packChecksumV1 : _packChecksumV2,
  'contents': <Object?>[
    <String, Object?>{
      'contentCode': _contentCode,
      'contentType': 'interview',
      'revision': revision,
      'checksum': revision == 1 ? _contentChecksumV1 : _contentChecksumV2,
      'sortOrder': 10,
      'publishedAt': '2026-10-31T00:00:00Z',
    },
  ],
  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};

Map<String, Object?> _contentPayload(int revision) => <String, Object?>{
  'contentCode': _contentCode,
  'contentType': 'interview',
  'revision': revision,
  'checksum': revision == 1 ? _contentChecksumV1 : _contentChecksumV2,
  'title': revision == 1 ? _titleV1 : _titleV2,
  'subtitle': 'Java Backend · Senior interview',
  'description': 'Explain constructor injection and its tradeoffs.',
  'categoryCode': 'JAVA_BACKEND',
  'categoryLabel': 'Java Backend',
  'levelCode': 'SENIOR',
  'levelLabel': 'Senior',
  'minutes': 8,
  'hasAudio': false,
};

http.Response _jsonResponse(
  Object body, {
  int statusCode = 200,
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const <String, String>{
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

const _installationId = '22222222-2222-4222-8222-222222222222';
const _token = 'installation-token-recovery';
const _contentCode = 'JAVA_DI_001';
const _titleV1 = 'Dependency Injection';
const _titleV2 = 'Dependency Injection v2';

const _rootChecksumV1 =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _packChecksumV1 =
    '2222222222222222222222222222222222222222222222222222222222222222';
const _contentChecksumV1 =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _rootChecksumV2 =
    '4444444444444444444444444444444444444444444444444444444444444444';
const _packChecksumV2 =
    '5555555555555555555555555555555555555555555555555555555555555555';
const _contentChecksumV2 =
    '6666666666666666666666666666666666666666666666666666666666666666';
