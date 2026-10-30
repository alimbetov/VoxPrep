import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _checksumUpper =
    'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
const _checksumLower =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('content payload projects an exact immutable content revision', () {
    final ref = ContentPayloadRef(
      identity: const ContentIdentity(
        code: 'JAVA_DI_001',
        type: ContentType.interview,
      ),
      revision: 3,
      checksum: _checksumUpper,
    );
    final payload = ContentPayload(
      ref: ref,
      title: 'Dependency Injection',
      subtitle: 'Java Backend · Senior interview',
      description: 'Explain dependency injection.',
      categoryCode: 'JAVA_BACKEND',
      category: 'Java Backend',
      levelCode: 'SENIOR',
      level: 'Senior',
      minutes: 8,
      hasAudio: true,
    );

    final item = payload.toContentItem();
    expect(ref.checksum, _checksumLower);
    expect(payload.categoryCode, 'JAVA_BACKEND');
    expect(payload.levelCode, 'SENIOR');
    expect(item.code, 'JAVA_DI_001');
    expect(item.type, ContentType.interview);
    expect(item.revision, 3);
    expect(item.title, 'Dependency Injection');
    expect(item.category, 'Java Backend');
    expect(item.level, 'Senior');
    expect(item.hasAudio, isTrue);
  });

  test('content payload rejects unstable taxonomy codes', () {
    final ref = ContentPayloadRef(
      identity: const ContentIdentity(
        code: 'JAVA_DI_001',
        type: ContentType.interview,
      ),
      revision: 3,
      checksum: _checksumLower,
    );

    expect(
      () => ContentPayload(
        ref: ref,
        title: 'Dependency Injection',
        subtitle: 'Java Backend',
        description: 'Explain dependency injection.',
        categoryCode: 'Java Backend',
        category: 'Java Backend',
        levelCode: 'SENIOR',
        level: 'Senior',
        minutes: 8,
        hasAudio: true,
      ),
      throwsArgumentError,
    );
  });

  test('content payload reference rejects invalid revision and checksum', () {
    const identity = ContentIdentity(
      code: 'JAVA_DI_001',
      type: ContentType.interview,
    );

    expect(
      () => ContentPayloadRef(
        identity: identity,
        revision: 0,
        checksum: _checksumLower,
      ),
      throwsArgumentError,
    );
    expect(
      () => ContentPayloadRef(
        identity: identity,
        revision: 1,
        checksum: 'not-a-checksum',
      ),
      throwsArgumentError,
    );
  });
}
