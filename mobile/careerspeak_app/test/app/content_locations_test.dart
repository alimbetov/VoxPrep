import 'package:careerspeak_app/app/content_locations.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content route carries the full content identity', () {
    const identity = ContentIdentity(
      code: 'JAVA_DI_001',
      type: ContentType.interview,
    );

    final location = contentDetailLocation(identity);
    expect(location, '/content/interview/JAVA_DI_001');

    final restored = contentIdentityFromRoute(
      typeCode: 'interview',
      code: 'JAVA_DI_001',
    );
    expect(restored, identity);
  });

  test('unknown content type fails closed', () {
    final restored = contentIdentityFromRoute(
      typeCode: 'unknown',
      code: 'JAVA_DI_001',
    );
    expect(restored, isNull);
  });
}
