import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_asset_byte_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _checksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('resolves immutable deliveryKey against CDN base path', () async {
    Uri? requested;
    final source = HttpAssetByteSource(
      client: MockClient((request) async {
        requested = request.url;
        return http.Response.bytes(<int>[1, 2, 3], 200);
      }),
      baseUri: Uri.parse('https://cdn.example.test/published/'),
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<Success<AssetByteStream>>());
    expect(
      requested,
      Uri.parse('https://cdn.example.test/published/audio/a.mp3'),
    );
  });

  test('maps temporary CDN failure to retryable failure', () async {
    final source = HttpAssetByteSource(
      client: MockClient((request) async => http.Response('', 503)),
      baseUri: Uri.parse('https://cdn.example.test/'),
    );

    final result = await source.open(_asset(size: 3));

    expect(result, isA<FailureResult<AssetByteStream>>());
    final failure = (result as FailureResult<AssetByteStream>).failure;
    expect(failure.code, 'ASSET_SOURCE_UNAVAILABLE');
    expect(failure.retryable, isTrue);
  });
}

ManifestAssetDescriptor _asset({required int size}) => ManifestAssetDescriptor(
  assetId: 'asset-a',
  checksumSha256: _checksum,
  deliveryKey: 'audio/a.mp3',
  sizeBytes: size,
  mediaType: 'audio/mpeg',
  requiredOffline: false,
);
