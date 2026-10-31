import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/ports/media_access_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_asset_byte_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _checksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('downloads only from signed URL resolved by assetId', () async {
    Uri? requested;
    bool? followRedirects;
    final access = _AccessGateway([
      Uri.parse('https://media.example.test/signed/a?signature=one'),
    ]);
    final source = HttpAssetByteSource(
      client: MockClient((request) async {
        requested = request.url;
        followRedirects = request.followRedirects;
        return http.Response.bytes(<int>[1, 2, 3], 200);
      }),
      accessGateway: access,
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<Success<AssetByteStream>>());
    expect(
      requested,
      Uri.parse('https://media.example.test/signed/a?signature=one'),
    );
    expect(followRedirects, isFalse);
    expect(access.assetIds, ['asset-a']);
  });

  test(
    'origin 403 refreshes grant once for the same immutable asset',
    () async {
      final requested = <Uri>[];
      final access = _AccessGateway([
        Uri.parse('https://media.example.test/signed/a?signature=expired'),
        Uri.parse('https://media.example.test/signed/a?signature=fresh'),
      ]);
      final source = HttpAssetByteSource(
        client: MockClient((request) async {
          requested.add(request.url);
          if (requested.length == 1) return http.Response('', 403);
          return http.Response.bytes(<int>[1, 2, 3], 200);
        }),
        accessGateway: access,
      );

      final result = await source.open(_asset(size: 3));

      expect(result, isA<Success<AssetByteStream>>());
      expect(requested.length, 2);
      expect(access.assetIds, ['asset-a', 'asset-a']);
    },
  );

  test('second origin 403 fails instead of refreshing forever', () async {
    final access = _AccessGateway([
      Uri.parse('https://media.example.test/signed/a?signature=one'),
      Uri.parse('https://media.example.test/signed/a?signature=two'),
    ]);
    final source = HttpAssetByteSource(
      client: MockClient((request) async => http.Response('', 403)),
      accessGateway: access,
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<FailureResult<AssetByteStream>>());
    expect(
      (result as FailureResult<AssetByteStream>).failure.code,
      'ASSET_DOWNLOAD_REJECTED',
    );
    expect(access.assetIds.length, 2);
  });

  test(
    'rejects redirects instead of leaving the signed HTTPS origin',
    () async {
      final source = HttpAssetByteSource(
        client: MockClient(
          (request) async => http.Response(
            '',
            302,
            headers: <String, String>{
              'location': 'http://untrusted.example.test/asset-a',
            },
          ),
        ),
        accessGateway: _AccessGateway([
          Uri.parse('https://media.example.test/signed/a?signature=one'),
        ]),
      );

      final result = await source.open(_asset(size: 3));

      expect(result, isA<FailureResult<AssetByteStream>>());
      expect(
        (result as FailureResult<AssetByteStream>).failure.code,
        'ASSET_DOWNLOAD_REJECTED',
      );
    },
  );

  test('maps temporary media-origin failure to retryable failure', () async {
    final source = HttpAssetByteSource(
      client: MockClient((request) async => http.Response('', 503)),
      accessGateway: _AccessGateway([
        Uri.parse('https://media.example.test/signed/a?signature=one'),
      ]),
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<FailureResult<AssetByteStream>>());
    final failure = (result as FailureResult<AssetByteStream>).failure;
    expect(failure.code, 'ASSET_SOURCE_UNAVAILABLE');
    expect(failure.retryable, isTrue);
  });
}

final class _AccessGateway implements MediaAccessGateway {
  _AccessGateway(this.urls);

  final List<Uri> urls;
  final assetIds = <String>[];
  int _next = 0;

  @override
  Future<Result<MediaAccessGrant>> resolve(String assetId) async {
    assetIds.add(assetId);
    final url = urls[_next++];
    return Success(
      MediaAccessGrant(
        assetId: assetId,
        url: url,
        expiresAt: DateTime.utc(2026, 11, 1, 12, 5),
      ),
    );
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
