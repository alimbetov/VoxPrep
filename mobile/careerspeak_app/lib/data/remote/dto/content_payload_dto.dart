final class ContentPayloadDto {
  const ContentPayloadDto({
    required this.contentCode,
    required this.contentType,
    required this.revision,
    required this.checksum,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.level,
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
  final String category;
  final String level;
  final int minutes;
  final bool hasAudio;
}
