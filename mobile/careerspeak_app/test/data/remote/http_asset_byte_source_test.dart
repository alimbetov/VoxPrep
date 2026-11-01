import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_asset_byte_source.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _checksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('downloads bytes only from authenticated Backend asset endpoint', () async {
    Uri? requested;
    String? authorization;
    bool? followRedirects;
    final source = HttpAssetByteSource(
      client: MockClient((request) async {
        requested = request.url;
        authorization = request.headers['authorization'];
        followRedirects = request.followRedirects;
        return http.Response.bytes(<int>[1, 2, 3], 200);
      }),
      credentialStore: _Credentials(InstallationToken('token-1')),
      baseUri: Uri.parse('https://api.example.test'),
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<Success<AssetByteStream>>());
    expect(
      requested,
      Uri.parse('https://api.example.test/api/v1/media/assets/asset-a/content'),
    );
    expect(authorization, 'Bearer token-1');
    expect(followRedirects, isFalse);
  });

  test('deliveryKey never changes the Backend download target', () async {
    final requested = <Uri>[];
    final source = HttpAssetByteSource(
      client: MockClient((request) async {
        requested.add(request.url);
        return http.Response.bytes(<int>[1, 2, 3], 200);
      }),
      credentialStore: _Credentials(InstallationToken('token-1')),
      baseUri: Uri.parse('https://api.example.test'),
    );

    await source.open(
      ManifestAssetDescriptor(
        assetId: 'asset-a',
        checksumSha256: _checksum,
        deliveryKey: 'rustfs/private/should-never-be-a-client-url.mp3',
        sizeBytes: 3,
        mediaType: 'audio/mpeg',
        requiredOffline: false,
      ),
    );

    expect(requested.single.host, 'api.example.test');
    expect(requested.single.path, '/api/v1/media/assets/asset-a/content');
    expect(requested.single.toString(), isNot(contains('rustfs')));
    expect(requested.single.toString(), isNot(contains('deliveryKey')));
  });

  test('missing installation token fails before any network request', () async {
    var networkCalls = 0;
    final source = HttpAssetByteSource(
      client: MockClient((request) async {
        networkCalls += 1;
        return http.Response('', 500);
      }),
      credentialStore: _Credentials(null),
      baseUri: Uri.parse('https://api.example.test'),
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<FailureResult<AssetByteStream>>());
    expect(
      (result as FailureResult<AssetByteStream>).failure.code,
      'UNAUTHORIZED',
    );
    expect(networkCalls, 0);
  });

  test('maps Backend 401 to installation authorization failure', () async {
    final source = HttpAssetByteSource(
      client: MockClient((request) async => http.Response('', 401)),
      credentialStore: _Credentials(InstallationToken('expired-token')),
      baseUri: Uri.parse('https://api.example.test'),
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<FailureResult<AssetByteStream>>());
    expect(
      (result as FailureResult<AssetByteStream>).failure.code,
      'INSTALLATION_UNAUTHORIZED',
    );
  });

  test('rejects redirects instead of following a storage-origin URL', () async {
    final source = HttpAssetByteSource(
      client: MockClient(
        (request) async => http.Response(
          '',
          302,
          headers: <String, String>{
            'location': 'https://rustfs.example.test/private/asset-a',
          },
        ),
      ),
      credentialStore: _Credentials(InstallationToken('token-1')),
      baseUri: Uri.parse('https://api.example.test'),
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<FailureResult<AssetByteStream>>());
    expect(
      (result as FailureResult<AssetByteStream>).failure.code,
      'ASSET_DOWNLOAD_REJECTED',
    );
  });

  test('maps temporary Backend media failure to retryable failure', () async {
    final source = HttpAssetByteSource(
      client: MockClient((request) async => http.Response('', 503)),
      credentialStore: _Credentials(InstallationToken('token-1')),
      baseUri: Uri.parse('https://api.example.test'),
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<FailureResult<AssetByteStream>>());
    final failure = (result as FailureResult<AssetByteStream>).failure;
    expect(failure.code, 'ASSET_SOURCE_UNAVAILABLE');
    expect(failure.retryable, isTrue);
  });
}

final class _Credentials implements InstallationCredentialStore {
  _Credentials(this.token);

  InstallationToken? token;

  @override
  Future<void> clear() async => token = null;

  @override
  Future<void> clearInstallationToken() async => token = null;

  @override
  Future<InstallationId?> readInstallationId() async =>
      InstallationId('installation-test');

  @override
  Future<InstallationToken?> readInstallationToken() async => token;

  @override
  Future<void> writeInstallationId(InstallationId installationId) async {}

  @override
  Future<void> writeInstallationToken(InstallationToken installationToken) async {
    token = installationToken;
  }
}

ManifestAssetDescriptor _asset({required int size}) => ManifestAssetDescriptor(
  assetId: 'asset-a',
  checksumSha256: _checksum,
  deliveryKey: 'audio/a.mp3',
  sizeBytes: size,
  mediaType: 'audio/mpeg',
  requiredOffline: false,
);
