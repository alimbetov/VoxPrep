import 'dart:convert';
import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/content_manifest_decoder.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = ContentManifestDecoder();

  test('root manifest v1 fixture remains compatible with the decoder', () {
    final result = decoder.decodeRoot(_fixture('root_manifest_v1.json'));

    expect(result, isA<Success<RootContentManifest>>());
    final manifest = (result as Success<RootContentManifest>).value;
    expect(manifest.contentVersion, 108);
    expect(manifest.minimumAppContractVersion, 1);
    expect(manifest.packs.single.identity.toString(), 'JAVA_SENIOR/canonical');
    expect(manifest.localeFallbacks, hasLength(2));
    expect(manifest.localeFallbacks.first.locale, 'ru-KZ');
    expect(manifest.localeFallbacks.first.fallbackLocales, <String>[
      'ru',
      'en',
    ]);
    expect(manifest.tombstones.single.identity.type, ContentType.interview);
  });

  test('pack manifest v1 fixture preserves the exact reference graph', () {
    final result = decoder.decodePack(_fixture('pack_manifest_v1.json'));

    expect(result, isA<Success<PackContentManifest>>());
    final manifest = (result as Success<PackContentManifest>).value;
    expect(manifest.identity.toString(), 'JAVA_SENIOR/canonical');
    expect(manifest.contents.single.identity.type, ContentType.interview);
    expect(manifest.contents.single.revision, 3);
    expect(manifest.assets.single.assetId, 'asset-1');
    expect(manifest.assets.single.requiredOffline, isTrue);
    expect(manifest.contentAssets.single.assetId, 'asset-1');
  });
}

Object? _fixture(String name) {
  return jsonDecode(File('test/contracts/fixtures/$name').readAsStringSync());
}
