sealed class ContentBodyDto {
  const ContentBodyDto();

  String get kind;
}

final class VocabularyBodyDto extends ContentBodyDto {
  const VocabularyBodyDto({
    required this.term,
    required this.definition,
    required this.partOfSpeech,
    required this.examples,
  });

  @override
  String get kind => 'vocabulary';

  final String term;
  final String definition;
  final String? partOfSpeech;
  final List<String> examples;
}

final class InterviewBodyDto extends ContentBodyDto {
  const InterviewBodyDto({
    required this.prompt,
    required this.modelAnswer,
    required this.keyPoints,
  });

  @override
  String get kind => 'interview';

  final String prompt;
  final String modelAnswer;
  final List<String> keyPoints;
}

final class TopicSectionDto {
  const TopicSectionDto({required this.heading, required this.text});

  final String heading;
  final String text;
}

final class TopicBodyDto extends ContentBodyDto {
  const TopicBodyDto({required this.sections});

  @override
  String get kind => 'topic';

  final List<TopicSectionDto> sections;
}

final class PhraseBodyDto extends ContentBodyDto {
  const PhraseBodyDto({
    required this.phrase,
    required this.usage,
    required this.examples,
  });

  @override
  String get kind => 'phrase';

  final String phrase;
  final String usage;
  final List<String> examples;
}

final class ShadowingSegmentDto {
  const ShadowingSegmentDto({
    required this.order,
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  final int order;
  final String text;
  final int? startMs;
  final int? endMs;
}

final class ShadowingBodyDto extends ContentBodyDto {
  const ShadowingBodyDto({
    required this.transcript,
    required this.segments,
  });

  @override
  String get kind => 'shadowing';

  final String transcript;
  final List<ShadowingSegmentDto> segments;
}

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
    required this.skillCodes,
    required this.body,
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
  final List<String> skillCodes;
  final ContentBodyDto body;
}
