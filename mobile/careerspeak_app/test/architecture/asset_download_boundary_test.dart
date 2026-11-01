import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('learner UI cannot bypass the managed asset pipeline', () {
    final root = Directory('lib/features');
    expect(root.existsSync(), isTrue, reason: root.path);

    final violations = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('Image.network(') ||
          source.contains('NetworkImage(') ||
          source.contains('package:http/')) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Remote learner media must resolve through AssetResolver -> '
          'AssetDownloadManager -> authenticated Backend asset stream -> '
          'verified local file.',
    );
  });

  test('production HTTP transport is confined to Backend API adapters', () {
    final root = Directory('lib');
    expect(root.existsSync(), isTrue, reason: root.path);

    const allowedHttpImports = <String>{
      'lib/app/api_client_providers.dart',
      'lib/data/remote/http_api_client.dart',
      'lib/data/remote/http_asset_byte_source.dart',
    };
    final violations = <String>[];

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      final source = entity.readAsStringSync();
      if (source.contains('package:http/') &&
          !allowedHttpImports.contains(path)) {
        violations.add(path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'All production HTTP must terminate at Backend API endpoints. '
          'Flutter must not contain a direct RustFS/S3/CDN transport adapter.',
    );
  });

  test('catalogue icons and audio use typed backend-only asset resolution', () {
    final iconProvider = File('lib/app/asset_resolver_providers.dart')
        .readAsStringSync();
    final audioProvider = File('lib/app/audio_playback_providers.dart')
        .readAsStringSync();
    final downloadProviders = File('lib/app/asset_download_providers.dart')
        .readAsStringSync();
    final byteSource = File('lib/data/remote/http_asset_byte_source.dart')
        .readAsStringSync();

    expect(iconProvider, contains('resolver.resolveImage('));
    expect(audioProvider, contains('resolver.resolveAudioContent('));
    expect(iconProvider, contains('AssetResolutionPolicy.downloadIfMissing'));
    expect(audioProvider, contains('AssetResolutionPolicy.downloadIfMissing'));
    expect(downloadProviders, contains('installationCredentialStoreProvider'));
    expect(downloadProviders, contains('apiBaseUriProvider'));
    expect(
      byteSource,
      contains("'api/v1/media/assets/\$encodedAssetId/content'"),
    );
    expect(byteSource, contains("headers['authorization'] = 'Bearer \$token'"));
    expect(byteSource, isNot(contains('MediaAccessGrant')));
    expect(byteSource, isNot(contains('grant.url')));
    expect(byteSource, isNot(contains('asset.deliveryKey')));
  });

  test('Flutter production sources contain no object-storage client boundary', () {
    final root = Directory('lib');
    final violations = <String>[];
    const forbidden = <String>[
      'rustfs',
      'presigned',
      'presign',
      'signed url',
      'amazonaws.com',
      's3.amazonaws.com',
      'minio',
    ];

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync().toLowerCase();
      for (final marker in forbidden) {
        if (source.contains(marker)) {
          violations.add('${entity.path}: $marker');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'RustFS/S3/CDN are Backend-internal infrastructure. Flutter may know '
          'assetId and immutable integrity metadata only.',
    );
  });
}
