import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:flutter_test/flutter_test.dart';

const _checksum =
    '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';

void main() {
  late Directory root;
  late FileSystemAssetStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('careerspeak-assets-');
    store = FileSystemAssetStore(
      root,
      now: () => DateTime.utc(2026, 10, 30, 12),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('writes verified bytes to content-addressed final path', () async {
    final result = await store.writeVerified(
      asset: _asset(),
      bytes: Stream<List<int>>.value('hello'.codeUnits),
    );

    final path = (result as Success<String>).value;
    expect(path, endsWith('$_checksum.mp3'));
    expect(await File(path).readAsString(), 'hello');

    final found = await store.findVerified(_asset());
    expect((found as Success<String?>).value, path);
  });

  test('deletes corrupt local copy and reports it missing', () async {
    final written = await store.writeVerified(
      asset: _asset(),
      bytes: Stream<List<int>>.value('hello'.codeUnits),
    );
    final path = (written as Success<String>).value;
    await File(path).writeAsString('HELLO');

    final found = await store.findVerified(_asset());

    expect((found as Success<String?>).value, isNull);
    expect(await File(path).exists(), isFalse);
  });

  test('rejects checksum mismatch without publishing final file', () async {
    final result = await store.writeVerified(
      asset: _asset(),
      bytes: Stream<List<int>>.value('jello'.codeUnits),
    );

    expect(result, isA<FailureResult<String>>());
    expect(
      (result as FailureResult<String>).failure.code,
      'ASSET_CHECKSUM_MISMATCH',
    );
    final found = await store.findVerified(_asset());
    expect((found as Success<String?>).value, isNull);
  });
}

ManifestAssetDescriptor _asset() => ManifestAssetDescriptor(
  assetId: 'audio-hello',
  checksumSha256: _checksum,
  deliveryKey: 'audio/hello.mp3',
  sizeBytes: 5,
  mediaType: 'audio/mpeg',
  requiredOffline: false,
);
