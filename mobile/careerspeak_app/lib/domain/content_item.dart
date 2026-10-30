enum ContentType { vocabulary, interview, topic, shadowing, phrase }

class ContentItem {
  const ContentItem({
    required this.code,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.level,
    required this.minutes,
    this.hasAudio = true,
  });

  final String code;
  final ContentType type;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String level;
  final int minutes;
  final bool hasAudio;
}
