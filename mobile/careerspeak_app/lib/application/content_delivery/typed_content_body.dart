import '../../domain/content_item.dart';

sealed class TypedContentBody {
  const TypedContentBody();

  ContentType get contentType;
}

final class VocabularyBody extends TypedContentBody {
  factory VocabularyBody({
    required String term,
    required String definition,
    String? partOfSpeech,
    required List<String> examples,
  }) {
    return VocabularyBody._(
      term: _nonBlank(term, 'term'),
      definition: _nonBlank(definition, 'definition'),
      partOfSpeech: _optionalNonBlank(partOfSpeech, 'partOfSpeech'),
      examples: _nonBlankItems(examples, 'examples'),
    );
  }

  const VocabularyBody._({
    required this.term,
    required this.definition,
    required this.partOfSpeech,
    required this.examples,
  });

  @override
  ContentType get contentType => ContentType.vocabulary;

  final String term;
  final String definition;
  final String? partOfSpeech;
  final List<String> examples;
}

final class InterviewBody extends TypedContentBody {
  factory InterviewBody({
    required String prompt,
    required String modelAnswer,
    required List<String> keyPoints,
  }) {
    return InterviewBody._(
      prompt: _nonBlank(prompt, 'prompt'),
      modelAnswer: _nonBlank(modelAnswer, 'modelAnswer'),
      keyPoints: _nonBlankItems(keyPoints, 'keyPoints'),
    );
  }

  const InterviewBody._({
    required this.prompt,
    required this.modelAnswer,
    required this.keyPoints,
  });

  @override
  ContentType get contentType => ContentType.interview;

  final String prompt;
  final String modelAnswer;
  final List<String> keyPoints;
}

final class TopicSection {
  factory TopicSection({required String heading, required String text}) {
    return TopicSection._(
      heading: _nonBlank(heading, 'heading'),
      text: _nonBlank(text, 'text'),
    );
  }

  const TopicSection._({required this.heading, required this.text});

  final String heading;
  final String text;
}

final class TopicBody extends TypedContentBody {
  factory TopicBody({required List<TopicSection> sections}) {
    if (sections.isEmpty) {
      throw ArgumentError.value(sections, 'sections', 'must not be empty');
    }
    return TopicBody._(sections: List<TopicSection>.unmodifiable(sections));
  }

  const TopicBody._({required this.sections});

  @override
  ContentType get contentType => ContentType.topic;

  final List<TopicSection> sections;
}

final class PhraseBody extends TypedContentBody {
  factory PhraseBody({
    required String phrase,
    required String usage,
    required List<String> examples,
  }) {
    return PhraseBody._(
      phrase: _nonBlank(phrase, 'phrase'),
      usage: _nonBlank(usage, 'usage'),
      examples: _nonBlankItems(examples, 'examples'),
    );
  }

  const PhraseBody._({
    required this.phrase,
    required this.usage,
    required this.examples,
  });

  @override
  ContentType get contentType => ContentType.phrase;

  final String phrase;
  final String usage;
  final List<String> examples;
}

final class ShadowingSegment {
  factory ShadowingSegment({
    required int order,
    required String text,
    int? startMs,
    int? endMs,
  }) {
    if (order < 0) {
      throw ArgumentError.value(order, 'order', 'must be non-negative');
    }
    if ((startMs == null) != (endMs == null)) {
      throw ArgumentError(
        'startMs and endMs must either both be present or both be absent',
      );
    }
    if (startMs != null && (startMs < 0 || endMs! <= startMs)) {
      throw ArgumentError('timing must satisfy 0 <= startMs < endMs');
    }
    return ShadowingSegment._(
      order: order,
      text: _nonBlank(text, 'text'),
      startMs: startMs,
      endMs: endMs,
    );
  }

  const ShadowingSegment._({
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

final class ShadowingBody extends TypedContentBody {
  factory ShadowingBody({
    required String transcript,
    required List<ShadowingSegment> segments,
  }) {
    if (segments.isEmpty) {
      throw ArgumentError.value(segments, 'segments', 'must not be empty');
    }
    for (var index = 0; index < segments.length; index++) {
      if (segments[index].order != index) {
        throw ArgumentError.value(
          segments[index].order,
          'segments[$index].order',
          'must be contiguous and zero-based',
        );
      }
      if (index > 0) {
        final previous = segments[index - 1];
        final current = segments[index];
        if (previous.endMs != null &&
            current.startMs != null &&
            current.startMs! < previous.endMs!) {
          throw ArgumentError.value(
            current.startMs,
            'segments[$index].startMs',
            'must not overlap the previous timed segment',
          );
        }
      }
    }
    return ShadowingBody._(
      transcript: _nonBlank(transcript, 'transcript'),
      segments: List<ShadowingSegment>.unmodifiable(segments),
    );
  }

  const ShadowingBody._({
    required this.transcript,
    required this.segments,
  });

  @override
  ContentType get contentType => ContentType.shadowing;

  final String transcript;
  final List<ShadowingSegment> segments;
}

String _nonBlank(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return normalized;
}

String? _optionalNonBlank(String? value, String fieldName) {
  if (value == null) {
    return null;
  }
  return _nonBlank(value, fieldName);
}

List<String> _nonBlankItems(List<String> values, String fieldName) {
  if (values.isEmpty) {
    throw ArgumentError.value(values, fieldName, 'must not be empty');
  }
  return List<String>.unmodifiable(
    values.indexed.map(
      (entry) => _nonBlank(entry.$2, '$fieldName[${entry.$1}]'),
    ),
  );
}
