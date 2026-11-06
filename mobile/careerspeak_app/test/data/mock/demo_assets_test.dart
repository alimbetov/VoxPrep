import 'package:careerspeak_app/data/mock/demo_learning_fixture.dart';
import 'package:careerspeak_app/data/mock/demo_runtime.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every demo asset is bundled with matching size and SHA; all lessons have bodies', () async {
    final pack = buildDemoPackManifest();
    for (final asset in pack.assets) {
      final result = (await DemoAssetByteSource().open(asset)).getOrThrow();
      final bytes = await result.bytes.expand((chunk) => chunk).toList();
      expect(bytes.length, asset.sizeBytes, reason: asset.assetId);
      expect(sha256.convert(bytes).toString(), asset.checksumSha256, reason: asset.assetId);
    }
    expect(pack.contentAssets.where((ref) => ref.role == 'coverImage'), hasLength(3));
    expect(pack.contentAssets.where((ref) => ref.role == 'narration'), hasLength(1));
    for (final content in buildDemoContentPayloads()) {
      expect(content.body, isNotNull, reason: content.ref.identity.code);
    }
  });
}
