final class LocalizedContentPayloadDto {
  const LocalizedContentPayloadDto({
    required this.contentCode,
    required this.contentType,
    required this.contentRevision,
    required this.locale,
    required this.localizationRevision,
    required this.checksum,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.translation,
    required this.hint,
    required this.explanation,
  });

  final String contentCode;
  final String contentType;
  final int contentRevision;
  final String locale;
  final int localizationRevision;
  final String checksum;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? translation;
  final String? hint;
  final String? explanation;
}
