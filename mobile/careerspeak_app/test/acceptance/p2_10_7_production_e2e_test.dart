import 'dart:convert';
import 'dart:io';

import 'package:careerspeak_app/app/careerspeak_app.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/preference_aware_content_sync.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/query/content_query.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'fresh install syncs production content to UI and survives reopen',
    (tester) async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'careerspeak-p2-10-7-',
      );
      final databaseFile = File('${tempDirectory.path}/careerspeak.sqlite');
      final credentialStore = _MemoryCredentialStore();
      final backend = _LearnerApiFixture();
      final client = MockClient(backend.handle);

      CareerSpeakDatabase? database;
      try {
        database = CareerSpeakDatabase(NativeDatabase(databaseFile));
        final firstBootstrap = await _bootstrap(
          database: database,
          credentialStore: credentialStore,
          client: client,
          runId: 'e2e-startup-1',
        );

        expect(
          firstBootstrap.credentials.installationId.value,
          _installationId,
        );
        expect(firstBootstrap.credentials.installationToken.value, _token);
        expect(backend.registrationCalls, 1);
        expect(backend.rootManifestCalls, 1);
        expect(backend.packManifestCalls, 1);
        expect(backend.contentPayloadCalls, 1);

        await _expectProductionReadModel(database);
        await _expectProductionUi(tester, database);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        await database.close();

        database = CareerSpeakDatabase(NativeDatabase(databaseFile));
        final secondBootstrap = await _bootstrap(
          database: database,
          credentialStore: credentialStore,
          client: client,
          runId: 'e2e-startup-2',
        );

        expect(
          secondBootstrap.credentials.installationId.value,
          _installationId,
        );
        expect(secondBootstrap.credentials.installationToken.value, _token);
        expect(backend.registrationCalls, 1);
        expect(backend.rootManifestCalls, 2);
        expect(backend.packManifestCalls, 1);
        expect(backend.contentPayloadCalls, 1);

        await _expectProductionReadModel(database);
        await _expectProductionUi(tester, database);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        if (database != null) {
          await database.close();
        }
        client.close();
        await tempDirectory.delete(recursive: true);
      }
    },
  );
}

Future<ApplicationBootstrapOutcome> _bootstrap({
  required CareerSpeakDatabase database,
  required InstallationCredentialStore credentialStore,
  required http.Client client,
  required String runId,
}) async {
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
  final identityService = InstallationIdentityService(
    credentialStore,
    installationIdFactory: () => InstallationId(_installationId),
  );
  final installationBootstrap = InstallationBootstrapService(
    identityService: identityService,
    registrationGateway: HttpInstallationRegistrationGateway(
      apiClient: apiClient,
    ),
  );
  final bootstrap = ApplicationBootstrapService(
    installationBootstrapService: installationBootstrap,
    synchronizeContent: contentSync.synchronize,
    runIdFactory: () => runId,
  );

  return (await bootstrap.bootstrap()).getOrThrow();
}

Future<void> _expectProductionReadModel(CareerSpeakDatabase database) async {
  final repository = DriftContentRepository(database);
  final page = (await repository.watchContent(const ContentQuery()).first)
      .getOrThrow();

  expect(page.items, hasLength(1));
  final item = page.items.single;
  expect(item.code, 'JAVA_DI_001');
  expect(item.title, 'Dependency Injection');
  expect(item.category, 'Java Backend');
  expect(item.level, 'Senior');
  expect(item.revision, 1);
}

Future<void> _expectProductionUi(
  WidgetTester tester,
  CareerSpeakDatabase database,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [careerSpeakDatabaseProvider.overrideWithValue(database)],
      child: const CareerSpeakApp(),
    ),
  );
  await tester.pumpAndSettle();

  await _navigate(tester, 'Learn');
  expect(find.text('Dependency Injection'), findsWidgets);
}

Future<void> _navigate(WidgetTester tester, String label) async {
  final navigation = find.byWidgetPredicate(
    (widget) => widget is NavigationBar || widget is NavigationRail,
  );
  final destination = find.descendant(
    of: navigation,
    matching: find.text(label),
  );

  expect(destination, findsOneWidget);
  await tester.tap(destination);
  await tester.pumpAndSettle();
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

final class _LearnerApiFixture {
  int registrationCalls = 0;
  int rootManifestCalls = 0;
  int packManifestCalls = 0;
  int contentPayloadCalls = 0;

  Future<http.Response> handle(http.Request request) async {
    if (request.method == 'POST' &&
        request.url.path == '/api/v1/installations') {
      registrationCalls += 1;
      if (request.headers.containsKey('authorization')) {
        throw StateError('Installation registration must be anonymous.');
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['installationId'] != _installationId) {
        throw StateError('Unexpected installation id.');
      }
      return _jsonResponse(<String, Object?>{'installationToken': _token});
    }

    _requireBearer(request);

    if (request.method == 'GET' &&
        request.url.path == '/api/v1/content/manifest') {
      rootManifestCalls += 1;
      if (request.url.queryParameters['locale'] != 'ru') {
        throw StateError('Startup sync must use persisted translation locale.');
      }
      return _jsonResponse(
        _rootManifest,
        headers: <String, String>{'etag': '"content-v1"'},
      );
    }

    if (request.method == 'GET' &&
        request.url.path == '/api/v1/content/packs/JAVA_SENIOR/manifest') {
      packManifestCalls += 1;
      if (request.url.queryParameters['variant'] != 'canonical' ||
          request.url.queryParameters['revision'] != '1') {
        throw StateError('Unexpected pack manifest target.');
      }
      return _jsonResponse(_packManifest);
    }

    if (request.method == 'GET' &&
        request.url.path ==
            '/api/v1/content/interview/JAVA_DI_001/revisions/1') {
      contentPayloadCalls += 1;
      return _jsonResponse(_contentPayload);
    }

    return _jsonResponse(<String, Object?>{
      'code': 'NOT_FOUND',
      'message': 'Unexpected request',
    }, statusCode: 404);
  }

  void _requireBearer(http.Request request) {
    if (request.headers['authorization'] != 'Bearer $_token') {
      throw StateError(
        'Authenticated learner request is missing bearer token.',
      );
    }
  }
}

http.Response _jsonResponse(
  Object body, {
  int statusCode = 200,
  Map<String, String> headers = const <String, String>{},
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: <String, String>{
      'content-type': 'application/json; charset=utf-8',
      ...headers,
    },
  );
}

const _installationId = '11111111-1111-4111-8111-111111111111';
const _token = 'installation-token-e2e';
const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _packChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _contentChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

const _rootManifest = <String, Object?>{
  'schemaVersion': 1,
  'contentVersion': 1,
  'minimumAppContractVersion': 1,
  'publishedAt': '2026-10-30T20:00:00Z',
  'checksum': _rootChecksum,
  'packs': <Object?>[
    <String, Object?>{
      'code': 'JAVA_SENIOR',
      'variant': 'canonical',
      'revision': 1,
      'checksum': _packChecksum,
    },
  ],
  'tombstones': <Object?>[],
};

const _packManifest = <String, Object?>{
  'schemaVersion': 1,
  'code': 'JAVA_SENIOR',
  'variant': 'canonical',
  'revision': 1,
  'checksum': _packChecksum,
  'contents': <Object?>[
    <String, Object?>{
      'contentCode': 'JAVA_DI_001',
      'contentType': 'interview',
      'revision': 1,
      'checksum': _contentChecksum,
      'sortOrder': 10,
      'publishedAt': '2026-10-30T20:00:00Z',
    },
  ],
  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};

const _contentPayload = <String, Object?>{
  'contentCode': 'JAVA_DI_001',
  'contentType': 'interview',
  'revision': 1,
  'checksum': _contentChecksum,
  'title': 'Dependency Injection',
  'subtitle': 'Java Backend · Senior interview',
  'description': 'Explain constructor injection and its tradeoffs.',
  'categoryCode': 'JAVA_BACKEND',
  'categoryLabel': 'Java Backend',
  'levelCode': 'SENIOR',
  'levelLabel': 'Senior',
  'minutes': 8,
  'hasAudio': false,
};
