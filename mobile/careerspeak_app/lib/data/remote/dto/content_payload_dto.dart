final class ContentPayloadDto {
  const ContentPayloadDto({
    required this.contentCode,
    required this.contentType,
    required this.revision,
    required this.checksum,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.categoryCode,
    required this.categoryLabel,
    required this.levelCode,
    required this.levelLabel,
    required this.minutes,
    required this.hasAudio,
  });

  final String contentCode;
  final String contentType;
  final int revision;
  final String checksum;
  final String title;
  final String subtitle;
  final String description;
  final String categoryCode;
  final String categoryLabel;
  final String levelCode;
  final String levelLabel;
  final int minutes;
  final bool hasAudio;
}
