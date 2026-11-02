import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monetization-aware client advertises app contract v3', () {
    expect(supportedContentManifestSchemaVersion, 2);
    expect(careerSpeakAppContractVersion, 3);
  });
}
