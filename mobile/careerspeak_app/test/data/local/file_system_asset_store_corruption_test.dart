import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test(
    'corrupt local cover is rejected and evicted before UI resolution',
    () async {
      final root = await Directory.systemTemp.createTemp('cover_corruption_');
      addTearDown(() => root.delete(recursive: true));

      final file = File('${root.path}/sha256/aa/$_hash.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(<int>[0, 1, 2, 3]);

      final store = FileSystemAssetStore(root);
      final descriptor = ManifestAssetDescriptor(
        assetId: 'cover-corrupt-1',
        checksumSha256: _hash,
        deliveryKey: 'images/cover.png',
        sizeBytes: 4,
        mediaType: 'image/png',
        requiredOffline: false,
      );

      final result = await store.findVerified(descriptor);

      expect(result.getOrThrow(), isNull);
      expect(await file.exists(), isFalse);
    },
  );
}
