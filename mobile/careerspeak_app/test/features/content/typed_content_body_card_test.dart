import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';
import 'package:careerspeak_app/features/content/typed_content_body_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> render(WidgetTester tester, TypedContentBody body) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: TypedContentBodyCard(body: body)),
        ),
      ),
    );
  }

  testWidgets('Vocabulary shows real term, definition and examples', (
    tester,
  ) async {
    await render(
      tester,
      VocabularyBody(
        term: 'Resilience',
        definition: 'Ability to recover from failure.',
        partOfSpeech: 'noun',
        examples: ['A resilient Spring Boot service.'],
      ),
    );
    expect(find.text('Resilience'), findsOneWidget);
    expect(find.text('Ability to recover from failure.'), findsOneWidget);
    expect(find.text('1. A resilient Spring Boot service.'), findsOneWidget);
  });

  testWidgets('Interview shows prompt, model answer and key points', (
    tester,
  ) async {
    await render(
      tester,
      InterviewBody(
        prompt: 'Explain dependency injection.',
        modelAnswer: 'Dependencies are supplied to the object.',
        keyPoints: ['Loose coupling', 'Testability'],
      ),
    );
    expect(find.text('Explain dependency injection.'), findsOneWidget);
    expect(
      find.text('Dependencies are supplied to the object.'),
      findsOneWidget,
    );
    expect(find.text('1. Loose coupling'), findsOneWidget);
  });

  testWidgets('Phrase shows usage and examples', (tester) async {
    await render(
      tester,
      PhraseBody(
        phrase: 'Could you clarify?',
        usage: 'Asking for more detail.',
        examples: ['Could you clarify the requirements?'],
      ),
    );
    expect(find.text('Could you clarify?'), findsOneWidget);
    expect(find.text('Asking for more detail.'), findsOneWidget);
  });

  testWidgets('Topic preserves section order', (tester) async {
    await render(
      tester,
      TopicBody(
        sections: [
          TopicSection(heading: 'REST', text: 'HTTP resources'),
          TopicSection(heading: 'Kafka', text: 'Event streaming'),
        ],
      ),
    );
    expect(find.text('REST'), findsOneWidget);
    expect(find.text('Kafka'), findsOneWidget);
  });

  testWidgets('Shadowing shows actual transcript and timings only', (
    tester,
  ) async {
    await render(
      tester,
      ShadowingBody(
        transcript: 'Welcome to the interview.',
        segments: [
          ShadowingSegment(order: 0, text: 'Welcome', startMs: 0, endMs: 1200),
        ],
      ),
    );
    expect(find.text('Welcome to the interview.'), findsOneWidget);
    expect(find.text('00:00.000–00:01.200  Welcome'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsNothing);
  });
  testWidgets('long learning text scrolls vertically inside bounded card', (
    tester,
  ) async {
    await render(
      tester,
      TopicBody(
        sections: [
          TopicSection(
            heading: 'Long lesson',
            text: List<String>.filled(
              160,
              'A detailed learning paragraph.',
            ).join(' '),
          ),
          TopicSection(heading: 'Last section', text: 'End of lesson'),
        ],
      ),
    );

    final scrolling = find.byKey(const Key('learning-content-scroll'));
    expect(scrolling, findsOneWidget);
    final scrollable = tester.widget<SingleChildScrollView>(scrolling);
    expect(scrollable.scrollDirection, Axis.vertical);
    expect(tester.getSize(scrolling).height, lessThanOrEqualTo(420));
    final controller = scrollable.controller!;
    expect(controller.position.maxScrollExtent, greaterThan(0));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();
    expect(controller.offset, greaterThan(0));
    expect(find.text('End of lesson'), findsOneWidget);
  });

  testWidgets('short text is not forced to the maximum scroll height', (
    tester,
  ) async {
    await render(
      tester,
      PhraseBody(
        phrase: 'Good morning',
        usage: 'Greeting',
        examples: ['Good morning, team.'],
      ),
    );
    final scrolling = find.byKey(const Key('learning-content-scroll'));
    expect(tester.getSize(scrolling).height, lessThan(420));
    expect(find.text('Good morning'), findsOneWidget);
  });
}
