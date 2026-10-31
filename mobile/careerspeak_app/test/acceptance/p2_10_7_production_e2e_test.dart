import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/app/application_bootstrap_providers.dart';
import 'package:careerspeak_app/app/careerspeak_app.dart';
import 'package:careerspeak_app/app/installation_identity_providers.dart';
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
import 'package:careerspeak_app/features/learn/learn_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fresh install sync survives file-backed reopen', () async {
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

      expect(firstBootstrap.credentials.installationId.value, _installationId);
      expect(firstBootstrap.credentials.installationToken.value, _token);
      expect(backend.registrationCalls, 1);
      expect(backend.rootManifestCalls, 1);
      expect(backend.packManifestCalls, 1);
      expect(backend.contentPayloadCalls, 1);
      await _expectProductionReadModel(database);

      await database.close();
      database = null;

      database = CareerSpeakDatabase(NativeDatabase(databaseFile));
      final secondBootstrap = await _bootstrap(
        database: database,
        credentialStore: credentialStore,
        client: client,
        runId: 'e2e-startup-2',
      );

      expect(secondBootstrap.credentials.installationId.value, _installationId);
      expect(secondBootstrap.credentials.installationToken.value, _token);
      expect(backend.registrationCalls, 1);
      expect(backend.rootManifestCalls, 2);
      expect(backend.packManifestCalls, 1);
      expect(backend.contentPayloadCalls, 1);
      await _expectProductionReadModel(database);
    } finally {
      if (database != null) {
        await database.close();
      }
      client.close();
      await tempDirectory.delete(recursive: true);
    }
  });

  testWidgets('production learner UI renders synchronized Drift content', (
    tester,
  ) async {
    final database = CareerSpeakDatabase(NativeDatabase.memory());
    final credentialStore = _MemoryCredentialStore();
    final backend = _LearnerApiFixture();
    final client = MockClient(backend.handle);
    addTearDown(database.close);
    addTearDown(client.close);

    await tester.runAsync(() async {
      await _bootstrap(
        database: database,
        credentialStore: credentialStore,
        client: client,
        runId: 'e2e-ui-startup',
      );
    });

    expect(backend.registrationCalls, 1);
    expect(backend.rootManifestCalls, 1);
    expect(backend.packManifestCalls, 1);
    expect(backend.contentPayloadCalls, 1);
    await _expectProductionUi(tester, database);
  });

  testWidgets(
    'production app live-updates from mock backend and emits renderer screenshots',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final database = CareerSpeakDatabase(NativeDatabase.memory());
      final credentialStore = _MemoryCredentialStore();
      await credentialStore.writeInstallationId(InstallationId(_installationId));
      final manifestGate = Completer<void>();
      final backend = _LearnerApiFixture(rootManifestGate: manifestGate);
      final client = MockClient(backend.handle);
      addTearDown(database.close);
      addTearDown(client.close);

      const screenshotKey = Key('production-e2e-screenshot');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            careerSpeakDatabaseProvider.overrideWithValue(database),
            installationCredentialStoreProvider.overrideWithValue(
              credentialStore,
            ),
            httpClientProvider.overrideWithValue(client),
            apiBaseUriProvider.overrideWithValue(
              Uri.parse('https://api.careerspeak.test'),
            ),
          ],
          child: const RepaintBoundary(
            key: screenshotKey,
            child: ProductionBootstrapHost(child: CareerSpeakApp()),
          ),
        ),
      );

      await _pumpUntil(
        tester,
        find.text('No learning content is available yet.'),
      );
      await _pumpUntilCondition(
        tester,
        () => backend.rootManifestCalls == 1,
        'root manifest request',
      );
      expect(backend.registrationCalls, 1);
      expect(backend.packManifestCalls, 0);
      expect(backend.contentPayloadCalls, 0);
      await _captureScreenshot(tester, screenshotKey, '01-home-before-sync.png');

      manifestGate.complete();
      await _pumpUntil(tester, find.text('Dependency Injection'));
      expect(backend.packManifestCalls, 1);
      expect(backend.contentPayloadCalls, 1);
      await _captureScreenshot(tester, screenshotKey, '02-home-after-sync.png');

      final learnDestination = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Learn'),
      );
      expect(learnDestination, findsOneWidget);
      await tester.tap(learnDestination);
      await _pumpUntil(tester, find.byType(SearchBar));
      expect(find.text('Dependency Injection'), findsOneWidget);
      await _captureScreenshot(tester, screenshotKey, '03-learn-after-sync.png');

      await tester.tap(find.text('Dependency Injection'));
      await _pumpUntil(tester, find.text('Overview'));
      expect(find.text('Explain constructor injection and its tradeoffs.'), findsOneWidget);
      await _captureScreenshot(tester, screenshotKey, '04-detail-after-sync.png');
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
      child: const MaterialApp(home: Scaffold(body: LearnScreen())),
    ),
  );

  final content = find.text('Dependency Injection');
  for (var attempt = 0; attempt < 40; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (content.evaluate().isNotEmpty) break;
  }

  expect(content, findsWidgets);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int attempts = 80,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }

  expect(finder, findsWidgets);
}

Future<void> _pumpUntilCondition(
  WidgetTester tester,
  bool Function() condition,
  String description, {
  int attempts = 80,
}) async {
  for (var attempt = 0; attempt < attempts; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (condition()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }

  expect(condition(), isTrue, reason: 'Timed out waiting for $description.');
}

Future<void> _captureScreenshot(
  WidgetTester tester,
  Key key,
  String fileName,
) async {
  await tester.pump();
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await boundary.toImage(pixelRatio: 1);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    image.dispose();
    throw StateError('Flutter renderer did not produce PNG bytes.');
  }

  final directory = Directory('build/acceptance_screenshots');
  await directory.create(recursive: true);
  final bytes = byteData.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );
  await File('${directory.path}/$fileName').writeAsBytes(bytes, flush: true);
  image.dispose();
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
  _LearnerApiFixture({this.rootManifestGate});

  final Completer<void>? rootManifestGate;

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
      final gate = rootManifestGate;
      if (gate != null) {
        await gate.future;
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
