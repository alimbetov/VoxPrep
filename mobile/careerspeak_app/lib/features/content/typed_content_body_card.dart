import 'package:flutter/material.dart';

import '../../application/content_delivery/typed_content_body.dart';

/// Displays the actual published typed fields. No simulated speaking controls.
class TypedContentBodyCard extends StatelessWidget {
  const TypedContentBodyCard({required this.body, super.key});

  final TypedContentBody body;

  @override
  Widget build(BuildContext context) {
    final fields = switch (body) {
      VocabularyBody(
        :final term,
        :final definition,
        :final partOfSpeech,
        :final examples,
      ) =>
        <Widget>[
          _field(context, 'Term', term),
          if (partOfSpeech != null)
            _field(context, 'Part of speech', partOfSpeech),
          _field(context, 'Definition', definition),
          _list(context, 'Examples', examples),
        ],
      PhraseBody(:final phrase, :final usage, :final examples) => <Widget>[
        _field(context, 'Phrase', phrase),
        _field(context, 'Usage', usage),
        _list(context, 'Examples', examples),
      ],
      InterviewBody(:final prompt, :final modelAnswer, :final keyPoints) =>
        <Widget>[
          _field(context, 'Question', prompt),
          _field(context, 'Model answer', modelAnswer),
          _list(context, 'Key points', keyPoints),
        ],
      TopicBody(:final sections) => <Widget>[
        for (final section in sections)
          _field(context, section.heading, section.text),
      ],
      ShadowingBody(:final transcript, :final segments) => <Widget>[
        _field(context, 'Transcript', transcript),
        Text('Segments', style: Theme.of(context).textTheme.titleSmall),
        for (final segment in segments)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              segment.startMs == null
                  ? segment.text
                  : '${_timestamp(segment.startMs!)}–'
                        '${_timestamp(segment.endMs!)}  ${segment.text}',
            ),
          ),
      ],
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning content',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...fields,
          ],
        ),
      ),
    );
  }

  static Widget _field(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 5),
          SelectableText(value),
        ],
      ),
    );
  }

  static Widget _list(BuildContext context, String title, List<String> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        for (var index = 0; index < values.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Text('${index + 1}. ${values[index]}'),
          ),
      ],
    );
  }

  static String _timestamp(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = ms % 1000;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${millis.toString().padLeft(3, '0')}';
  }
}
