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
          'AssetDownloadManager -> HttpAssetByteSource -> verified local file.',
    );
  });

  test('catalogue icons and audio use typed downloadIfMissing resolution', () {
    final iconProvider = File(
      'lib/app/asset_resolver_providers.dart',
    ).readAsStringSync();
    final audioProvider = File(
      'lib/app/audio_playback_providers.dart',
    ).readAsStringSync();
    final byteSource = File(
      'lib/data/remote/http_asset_byte_source.dart',
    ).readAsStringSync();

    expect(iconProvider, contains('resolver.resolveImage('));
    expect(audioProvider, contains('resolver.resolveAudioContent('));
    expect(iconProvider, contains('AssetResolutionPolicy.downloadIfMissing'));
    expect(audioProvider, contains('AssetResolutionPolicy.downloadIfMissing'));
    expect(byteSource, contains("http.Request('GET'"));
    expect(byteSource, contains('asset.deliveryKey'));
  });
}
