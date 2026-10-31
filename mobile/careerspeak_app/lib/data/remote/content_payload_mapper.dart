import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/content_payload.dart';
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

    return ContentPayload(
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
    );
  }
}
