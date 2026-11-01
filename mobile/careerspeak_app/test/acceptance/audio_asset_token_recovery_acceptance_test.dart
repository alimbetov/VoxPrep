import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:careerspeak_app/data/remote/http_asset_byte_source.dart';
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
    'deleted local audio is restored through Backend using current installation token',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'audio-token-recovery-',
      );
      addTearDown(() => directory.delete(recursive: true));

      final credentials = _CredentialStore(
        installationId: InstallationId('installation-recovery-1'),
        token: InstallationToken('token-v1'),
      );
      final requestedUris = <Uri>[];
      final authorizationHeaders = <String?>[];

      final client = MockClient((request) async {
        requestedUris.add(request.url);
        authorizationHeaders.add(request.headers['authorization']);
        expect(request.url.host, 'api.example.test');
        expect(
          request.url.path,
          '/api/v1/media/assets/${_audioAsset.assetId}/content',
        );
        return http.Response.bytes(_audioBytes, 200);
      });

      final store = FileSystemAssetStore(directory);
      final source = HttpAssetByteSource(
        client: client,
        credentialStore: credentials,
        baseUri: Uri.parse('https://api.example.test'),
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
      expect(requestedUris, hasLength(1));
      expect(authorizationHeaders, <String?>['Bearer token-v1']);

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
      expect(requestedUris, hasLength(2));
      expect(authorizationHeaders, <String?>[
        'Bearer token-v1',
        'Bearer token-v2',
      ]);
      expect(
        requestedUris.every((uri) => uri.host == 'api.example.test'),
        isTrue,
      );
      expect(_audioAsset.deliveryKey, 'audio/interview/recoverable-1.mp3');
    },
  );

  test(
    'deleted audio fails closed when current token is unavailable',
    () async {
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
      final resolver = AssetResolver(
        catalog: const _Catalog(),
        store: store,
        downloads: AssetDownloadManager(
          source: HttpAssetByteSource(
            client: client,
            credentialStore: credentials,
            baseUri: Uri.parse('https://api.example.test'),
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
    },
  );
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
  Future<void> writeInstallationToken(
    InstallationToken installationToken,
  ) async {
    token = installationToken;
  }
}
