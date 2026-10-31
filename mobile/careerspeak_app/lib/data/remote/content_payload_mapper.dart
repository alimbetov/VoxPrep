import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/content_payload.dart';
import '../../application/content_delivery/typed_content_body.dart';
import '../../domain/content_identity.dart';
import 'dto/content_payload_dto.dart';

final class ContentPayloadMapper {
  const ContentPayloadMapper();

  ContentPayload map(ContentPayloadDto dto) {
    final type = contentTypeFromWireName(dto.contentType);
    if (type == null) {
      throw ArgumentError.value(
        dto.contentType,
        'contentType',
        'contains an unsupported content type',
      );
    }

    return ContentPayload.typed(
      ref: ContentPayloadRef(
        identity: ContentIdentity(code: dto.contentCode, type: type),
        revision: dto.revision,
        checksum: dto.checksum,
      ),
      title: dto.title,
      subtitle: dto.subtitle,
      description: dto.description,
      categoryCode: dto.categoryCode,
      category: dto.categoryLabel,
      levelCode: dto.levelCode,
      level: dto.levelLabel,
      minutes: dto.minutes,
      hasAudio: dto.hasAudio,
      skillCodes: dto.skillCodes,
      body: _mapBody(dto.body),
    );
  }

  TypedContentBody _mapBody(ContentBodyDto dto) {
    if (dto is VocabularyBodyDto) {
      return VocabularyBody(
        term: dto.term,
        definition: dto.definition,
        partOfSpeech: dto.partOfSpeech,
        examples: dto.examples,
      );
    }
    if (dto is InterviewBodyDto) {
      return InterviewBody(
        prompt: dto.prompt,
        modelAnswer: dto.modelAnswer,
        keyPoints: dto.keyPoints,
      );
    }
    if (dto is TopicBodyDto) {
      return TopicBody(
        sections: dto.sections
            .map(
              (section) =>
                  TopicSection(heading: section.heading, text: section.text),
            )
            .toList(growable: false),
      );
    }
    if (dto is PhraseBodyDto) {
      return PhraseBody(
        phrase: dto.phrase,
        usage: dto.usage,
        examples: dto.examples,
      );
    }
    if (dto is ShadowingBodyDto) {
      return ShadowingBody(
        transcript: dto.transcript,
        segments: dto.segments
            .map(
              (segment) => ShadowingSegment(
                order: segment.order,
                text: segment.text,
                startMs: segment.startMs,
                endMs: segment.endMs,
              ),
            )
            .toList(growable: false),
      );
    }
    throw ArgumentError.value(
      dto.kind,
      'body.kind',
      'contains an unsupported kind',
    );
  }
}
