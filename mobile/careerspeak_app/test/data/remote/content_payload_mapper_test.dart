import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';
import 'package:careerspeak_app/data/remote/content_payload_mapper.dart';
import 'package:careerspeak_app/data/remote/dto/content_payload_dto.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _contentHash =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  const mapper = ContentPayloadMapper();

  test('maps the typed wire DTO into the canonical application payload', () {
    const dto = ContentPayloadDto(
      contentCode: 'JAVA_Q_001',
      contentType: 'interview',
      revision: 3,
      checksum: _contentHash,
      title: 'Dependency Injection',
      subtitle: 'Java Backend',
      description: 'Explain constructor injection and its tradeoffs.',
      categoryCode: 'JAVA_BACKEND',
      categoryLabel: 'Java Backend',
      levelCode: 'SENIOR',
      levelLabel: 'Senior',
      minutes: 6,
      hasAudio: true,
      skillCodes: <String>['COMMUNICATION'],
      body: InterviewBodyDto(
        prompt: 'What is dependency injection?',
        modelAnswer: 'Dependencies are supplied externally.',
        keyPoints: <String>['loose coupling'],
      ),
    );

    final payload = mapper.map(dto);

    expect(payload.ref.identity.code, dto.contentCode);
    expect(payload.ref.identity.type, ContentType.interview);
    expect(payload.ref.revision, dto.revision);
    expect(payload.ref.checksum, dto.checksum);
    expect(payload.title, dto.title);
    expect(payload.categoryCode, dto.categoryCode);
    expect(payload.levelCode, dto.levelCode);
    expect(payload.skillCodes, dto.skillCodes);
    expect(payload.body, isA<InterviewBody>());
  });

  test('rejects content type and body kind mismatch', () {
    const dto = ContentPayloadDto(
      contentCode: 'JAVA_Q_001',
      contentType: 'phrase',
      revision: 3,
      checksum: _contentHash,
      title: 'Dependency Injection',
      subtitle: 'Java Backend',
      description: 'Explain constructor injection and its tradeoffs.',
      categoryCode: 'JAVA_BACKEND',
      categoryLabel: 'Java Backend',
      levelCode: 'SENIOR',
      levelLabel: 'Senior',
      minutes: 6,
      hasAudio: true,
      skillCodes: <String>['COMMUNICATION'],
      body: InterviewBodyDto(
        prompt: 'What is dependency injection?',
        modelAnswer: 'Dependencies are supplied externally.',
        keyPoints: <String>['loose coupling'],
      ),
    );

    expect(() => mapper.map(dto), throwsArgumentError);
  });

  test('rejects an unsupported wire content type', () {
    const dto = ContentPayloadDto(
      contentCode: 'JAVA_Q_001',
      contentType: 'unsupported',
      revision: 3,
      checksum: _contentHash,
      title: 'Dependency Injection',
      subtitle: 'Java Backend',
      description: 'Explain constructor injection and its tradeoffs.',
      categoryCode: 'JAVA_BACKEND',
      categoryLabel: 'Java Backend',
      levelCode: 'SENIOR',
      levelLabel: 'Senior',
      minutes: 6,
      hasAudio: true,
      skillCodes: <String>[],
      body: InterviewBodyDto(
        prompt: 'Question',
        modelAnswer: 'Answer',
        keyPoints: <String>['point'],
      ),
    );

    expect(() => mapper.map(dto), throwsArgumentError);
  });
}
