import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_delivery/localized_content_payload.dart';
import '../../domain/content_identity.dart';
import 'dto/localized_content_payload_dto.dart';

final class LocalizedContentPayloadMapper {
  const LocalizedContentPayloadMapper();

  LocalizedContentPayload map(LocalizedContentPayloadDto dto) {
    final type = contentTypeFromWireName(dto.contentType);
    if (type == null) {
      throw ArgumentError.value(
        dto.contentType,
        'contentType',
        'contains an unsupported content type',
      );
    }

    return LocalizedContentPayload(
      ref: LocalizedContentRef(
        identity: ContentIdentity(code: dto.contentCode, type: type),
        contentRevision: dto.contentRevision,
        locale: dto.locale,
        localizationRevision: dto.localizationRevision,
        checksum: dto.checksum,
      ),
      title: dto.title,
      subtitle: dto.subtitle,
      description: dto.description,
      translation: dto.translation,
      hint: dto.hint,
      explanation: dto.explanation,
    );
  }
}
