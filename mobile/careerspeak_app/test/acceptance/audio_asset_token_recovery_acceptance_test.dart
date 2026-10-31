import 'dart:convert';
import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:careerspeak_app/data/remote/http_api_client.dart';
import 'package:careerspeak_app/data/remote/http_asset_byte_source.dart';
import 'package:careerspeak_app/data/remote/http_media_access_gateway.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _audioBytes = <int>[1, 2, 3, 4];
const _audioChecksum =
    '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a';

final _audioAsset = ManifestAssetDescriptor(
  assetId: 'audio-recoverable-1',
  checksumSha256: _audioChecksum,
  deliveryKey: 'audio/interview/recoverable-1.mp3',
  sizeBytes: _audioBytes.length,
  mediaType: 'audio/mpeg',
  requiredOffline: false,
);

final _content = ContentIdentity(
  code: 'INTERVIEW_RECOVERY_1',
  type: ContentType.interview,
);

void main() {
  test(
    'deleted local audio is restored through current installation token and immutable asset identity',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'audio-token-recovery-',
      );
      addTearDown(() => directory.delete(recursive: true));

      final credentials = _CredentialStore(
        installationId: InstallationId('installation-recovery-1'),
        token: InstallationToken('token-v1'),
      );
      final authorizationHeaders = <String?>[];
      final accessBodies = <Map<String, Object?>>[];
      var grantNumber = 0;
      var mediaGets = 0;

      final client = MockClient((request) async {
        if (request.url.host == 'api.example.test' &&
            request.url.path == '/api/v1/media/access') {
          authorizationHeaders.add(request.headers['authorization']);
          accessBodies.add(
            Map<String, Object?>.from(
              jsonDecode(request.body) as Map<String, Object?>,
            ),
          );
          grantNumber += 1;
          return http.Response(
            jsonEncode(<String, Object?>{
              'assetId': _audioAsset.assetId,
              'url':
                  'https://media.example.test/signed/${_audioAsset.assetId}?grant=$grantNumber',
              'expiresAt': '2026-11-01T03:00:00Z',
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }

        if (request.url.host == 'media.example.test') {
          mediaGets += 1;
          return http.Response.bytes(_audioBytes, 200);
        }

        return http.Response('unexpected request', 500);
      });

      final store = FileSystemAssetStore(directory);
      final apiClient = HttpApiClient(
        client: client,
        credentialStore: credentials,
        baseUri: Uri.parse('https://api.example.test'),
        delay: (_) async {},
      );
      final accessGateway = HttpMediaAccessGateway(apiClient: apiClient);
      final source = HttpAssetByteSource(
        client: client,
        accessGateway: accessGateway,
      );
      final resolver = AssetResolver(
        catalog: const _Catalog(),
        store: store,
        downloads: AssetDownloadManager(
          source: source,
          store: store,
          maxAttempts: 1,
          delay: (_) async {},
        ),
      );

      final first = await resolver.resolveAudioContent(
        content: _content,
        revision: 1,
        role: 'PRIMARY',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      expect(first, isA<Success<ResolvedAsset>>());
      final firstPath = (first as Success<ResolvedAsset>).value.localPath;
      expect(await File(firstPath).readAsBytes(), _audioBytes);
      expect(grantNumber, 1);
      expect(mediaGets, 1);
      expect(authorizationHeaders, <String?>['Bearer token-v1']);
      expect(accessBodies.single, <String, Object?>{
        'assetId': _audioAsset.assetId,
      });

      await File(firstPath).delete();
      expect(await File(firstPath).exists(), isFalse);
      await credentials.writeInstallationToken(InstallationToken('token-v2'));

      final recovered = await resolver.resolveAudioContent(
        content: _content,
        revision: 1,
        role: 'PRIMARY',
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      expect(recovered, isA<Success<ResolvedAsset>>());
      final recoveredPath =
          (recovered as Success<ResolvedAsset>).value.localPath;
      expect(recoveredPath, firstPath);
      expect(await File(recoveredPath).readAsBytes(), _audioBytes);
      expect(grantNumber, 2);
      expect(mediaGets, 2);
      expect(authorizationHeaders, <String?>[
        'Bearer token-v1',
        'Bearer token-v2',
      ]);
      expect(accessBodies, <Map<String, Object?>>[
        <String, Object?>{'assetId': _audioAsset.assetId},
        <String, Object?>{'assetId': _audioAsset.assetId},
      ]);
      expect(_audioAsset.deliveryKey, 'audio/interview/recoverable-1.mp3');
    },
  );

  test('deleted audio fails closed when current token is unavailable', () async {
    final directory = await Directory.systemTemp.createTemp(
      'audio-token-missing-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final credentials = _CredentialStore(
      installationId: InstallationId('installation-recovery-2'),
      token: null,
    );
    var networkCalls = 0;
    final client = MockClient((request) async {
      networkCalls += 1;
      return http.Response('unexpected request', 500);
    });
    final store = FileSystemAssetStore(directory);
    final apiClient = HttpApiClient(
      client: client,
      credentialStore: credentials,
      baseUri: Uri.parse('https://api.example.test'),
      delay: (_) async {},
    );
    final resolver = AssetResolver(
      catalog: const _Catalog(),
      store: store,
      downloads: AssetDownloadManager(
        source: HttpAssetByteSource(
          client: client,
          accessGateway: HttpMediaAccessGateway(apiClient: apiClient),
        ),
        store: store,
        maxAttempts: 1,
        delay: (_) async {},
      ),
    );

    final result = await resolver.resolveAudioContent(
      content: _content,
      revision: 1,
      role: 'PRIMARY',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );

    expect(result, isA<FailureResult<ResolvedAsset>>());
    expect(
      (result as FailureResult<ResolvedAsset>).failure.code,
      'UNAUTHORIZED',
    );
    expect(networkCalls, 0);
  });
}

final class _Catalog implements AssetCatalogRepository {
  const _Catalog();

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(
    String assetId,
  ) async => Success<ManifestAssetDescriptor?>(
    assetId == _audioAsset.assetId ? _audioAsset : null,
  );

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async {
    if (content == _content && revision == 1 && role == 'PRIMARY') {
      return Success<ManifestAssetDescriptor?>(_audioAsset);
    }
    return const Success<ManifestAssetDescriptor?>(null);
  }
}

final class _CredentialStore implements InstallationCredentialStore {
  _CredentialStore({required this.installationId, required this.token});

  InstallationId? installationId;
  InstallationToken? token;

  @override
  Future<void> clear() async {
    installationId = null;
    token = null;
  }

  @override
  Future<void> clearInstallationToken() async {
    token = null;
  }

  @override
  Future<InstallationId?> readInstallationId() async => installationId;

  @override
  Future<InstallationToken?> readInstallationToken() async => token;

  @override
  Future<void> writeInstallationId(InstallationId installationId) async {
    this.installationId = installationId;
  }

  @override
  Future<void> writeInstallationToken(InstallationToken installationToken) async {
    token = installationToken;
  }
}
